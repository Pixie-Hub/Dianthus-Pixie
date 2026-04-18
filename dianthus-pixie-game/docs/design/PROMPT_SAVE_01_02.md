# SAVE-01 & SAVE-02 — Auto-Save + Manual Save / Single-Slot Load — Implementation Prompt

**Project:** Dianthus Pixie
**Engine:** Godot 4.6 (GDScript)
**Effort:** M (1–2 days, combined)
**Priority:** High (Phase 4, but infrastructure must be stubbed now per Risk 5)
**Dependencies:**
- CORE-09 (Night Survived Screen — Done) — autosave hooks onto `GameManager.night_survived`
- FOUND-05 (Day/Night Cycle — Done) — `DayNightCycle.day_count` / `current_phase` are persisted
- PLANT-01 (Thornvine/Gloomshroom — Done) — garden layout serialisation starts here
- DIFF-01 (Difficulty Scaling — Done) — `day_count` drives scaling so load order matters

**Downstream dependents:** QUEST-01 (quest state serialisation), END-01/END-04 (unlock flags), ACCESS-01 (difficulty persistence), UI-05 Pause Menu (Save/Load buttons), Main Menu (Continue / New Game overwrite dialog)

---

## 1. Objective

Ship the **full save-coherence backbone** for Dianthus Pixie in a single sprint. Two tasks are combined because SAVE-02 has zero value without SAVE-01's schema + SaveManager, and both touch the same files.

Deliverables:

1. **SAVE-01 — Auto-Save System**
   - Autosave fires **after a night is successfully cleared**, at the moment `GameManager.night_survived` is emitted.
   - Persists: `schema_version`, `day_count`, current phase + phase timer, player stats (HP, position, last zone), 30-slot inventory, Dianthus Core HP, garden layout (plant type + position + HP + destroyed flag), and forward-compatible stubs for quests/unlocks/difficulty.
   - Single file at `user://savegame.json`.

2. **SAVE-02 — Manual Save & Single-Slot Load**
   - Manual save callable at any time while `GameManager.current_state == EXPLORATION` (day phase). Blocked during `DEFENSE` (night) and `GAME_OVER`.
   - Load restores full state in-place by changing scene to `player.last_zone` and re-applying the save dictionary.
   - Exactly **one save slot**. "New Game" must detect an existing save and expose an overwrite-confirmation path (hook only — UI belongs to the Main Menu task).

Non-goals (strictly deferred):
- Multiple slots, cloud sync, autosave-on-exit, autosave-on-damage.
- Full Pause Menu / Main Menu UI — only hook methods are wired.
- Quest, unlock, and difficulty fields are **reserved keys** in the schema but carry empty payloads until their owning tasks land.

---

## 2. GDD Specs (§11.3) — Mapped to Acceptance

| GDD line | Mapped requirement |
|---|---|
| "Auto-save terjadi setiap setelah malam berhasil dipertahankan" | `SaveManager.save_to_slot(false)` called from `GameManager.night_survived` handler. |
| "Manual save tersedia kapan saja selama Exploration/Preparation Phase" | `SaveManager.save_to_slot(true)` only succeeds when `current_state == EXPLORATION`. |
| "Satu save slot per permainan" | Hardcoded path `user://savegame.json`. No slot index anywhere in the API. |
| "Tidak ada permadeath mode" | Game Over does **not** delete the save. Player can reload last autosave after death (wired via Main Menu in a later task). |

Risk 5 mitigation (from `TASK_BREAKDOWN.md` §Risk 5) is non-negotiable:
- Dictionary carries `schema_version: int` from v1.
- `migrate(data: Dictionary) -> Dictionary` runs on every load.
- **No node references serialised.** Only IDs (plant `type` strings, scene file paths, numeric fields).

---

## 3. Save Schema (v1)

Flat, human-readable JSON. All keys are snake_case. Unknown keys must be **preserved** on re-save (forward-compat).

```json
{
    "schema_version": 1,
    "meta": {
        "timestamp_unix": 1744975800,
        "game_version": "0.1.0",
        "manual": false
    },
    "day_night": {
        "day_count": 3,
        "current_phase": "DAY",
        "phase_timer": 42.5
    },
    "player": {
        "position": {"x": 120.0, "y": 240.0},
        "current_hp": 75,
        "last_zone": "res://world/zones/meadow_edge/meadow_edge.tscn"
    },
    "inventory": {
        "petal_shard": 8,
        "verdant_sap": 2
    },
    "core": {
        "current_hp": 200
    },
    "garden": {
        "plants": [
            {
                "type": "thornvine",
                "position": {"x": 64.0, "y": 96.0},
                "current_hp": 30,
                "is_destroyed": false
            }
        ]
    },
    "quests": {},
    "unlocks": [],
    "difficulty": {
        "tier": "normal"
    }
}
```

**Reserved empty payloads (leave as documented TODO stubs):**
- `quests` — populated by `TODO (QUEST-01)`.
- `unlocks` — populated by `TODO (END-01, END-04)`.
- `difficulty.tier` — populated by `TODO (ACCESS-01)`. Default `"normal"` until then.

---

## 4. Architecture

### 4a. `save/scripts/save_manager.gd` (new autoload)

`class_name SaveManager`, `extends Node`. Registered as autoload `SaveManager` in `project.godot`.

**Constants:**
```gdscript
const SAVE_PATH: String = "user://savegame.json"
const SCHEMA_VERSION: int = 1
const GAME_VERSION: String = "0.1.0"

const PLANT_TYPE_TO_SCENE: Dictionary = {
    "thornvine": "res://plants/entities/thornvine.tscn",
    "gloomshroom": "res://plants/entities/gloomshroom.tscn",
}
```

**Signals:**
```gdscript
signal save_completed(success: bool, manual: bool)
signal load_completed(success: bool)
```

**State:**
```gdscript
var _pending_load_state: Dictionary = {}  # applied after scene change in load_from_slot()
```

**Public API:**
- `has_save() -> bool` — `FileAccess.file_exists(SAVE_PATH)`.
- `save_to_slot(manual: bool) -> bool` — gather state, write JSON, emit `save_completed`. Manual saves **must** return false (no write) when `GameManager.current_state != GameManager.GameState.EXPLORATION`.
- `load_from_slot() -> bool` — read JSON, validate + migrate, stash in `_pending_load_state`, call `get_tree().change_scene_to_file(state.player.last_zone)`, defer `_apply_pending_state()` to `SceneTree.process_frame` (once).
- `delete_save() -> void` — removes the file if it exists. Used by New Game overwrite flow.
- `get_save_metadata() -> Dictionary` — cheap read of `schema_version`, `meta`, and `day_night.day_count` only. For Main Menu "Continue from Day X" label without loading full state.

**Private helpers:**
- `_gather_state(manual: bool) -> Dictionary` — builds the full dict from autoloads + current scene (see §4b).
- `_apply_state(state: Dictionary) -> void` — inverse of gather. Called deferred after scene change (see §4c).
- `_migrate(data: Dictionary) -> Dictionary` — returns upgraded dict. v1 is identity; later versions add cases (see §6).
- `_connect_autosave() -> void` — called in `_ready()`. Connects `GameManager.night_survived` → autosave.

### 4b. State gathering — where each field comes from

| Field | Source |
|---|---|
| `day_night.day_count` | `DayNightCycle.day_count` |
| `day_night.current_phase` | `DayNightCycle.get_phase_name()` |
| `day_night.phase_timer` | `DayNightCycle.get_time_remaining()` |
| `player.position` | `GameManager.player.global_position` (fallback `GameManager.player_data.position`) |
| `player.current_hp` | `GameManager.player.current_hp` |
| `player.last_zone` | `get_tree().current_scene.scene_file_path` |
| `inventory` | `GameManager.player_data["inventory"].duplicate()` |
| `core.current_hp` | `GameManager.dianthus_core.current_hp` |
| `garden.plants[]` | `get_tree().get_nodes_in_group("plants")` → for each `PlantBase`, emit `{type, position, current_hp, is_destroyed}`. Type resolved by matching `scene_file_path` against `PLANT_TYPE_TO_SCENE` values (reverse lookup). Plants with `is_destroyed == true` may be skipped since they are mid-wither. |

Every lookup must be `is_instance_valid()`-guarded. Missing autoloads or nodes must fall back to safe defaults, not crash.

### 4c. State application — load order matters

Restoration runs **after** the target scene finishes loading (one frame after `change_scene_to_file`). Fixed order:

1. **DayNightCycle first** — write `day_count`, `current_phase`, `_phase_timer`, then call `_apply_tint()` so the canvas modulate matches the saved phase. Set `GameManager.current_state` to `EXPLORATION` if phase is DAY else `DEFENSE` (but in practice saves only exist for DAY).
2. **Clear live runtime entities** — free everything in groups `"enemies"` and `"plants"` on the new scene before placing saved plants. This prevents duplicate plants when loading into a scene that ships with some.
3. **Dianthus Core HP** — set `core.current_hp` directly; call the core's `_update_aura()` or emit `hp_changed` so the HUD refreshes. A helper `GameManager.dianthus_core.set_hp(value)` is fine if added; otherwise assign the var and emit.
4. **Player** — set `global_position`, `current_hp`, then emit `hp_changed(current_hp, MAX_HP)` so the HUD updates. Guard with `is_instance_valid(GameManager.player)`.
5. **Inventory** — `GameManager.player_data["inventory"] = state.inventory.duplicate()`. If Person B's pickup UI subscribes to an inventory-changed signal later, that signal fires here (add TODO).
6. **Garden plants** — for each saved entry: `PackedScene = load(PLANT_TYPE_TO_SCENE[entry.type])` → `instantiate()` → set `global_position`, `current_hp` (after `_ready`), add to current scene.
7. Emit `load_completed(true)`.

### 4d. Hooks into existing code (minimal edits)

- **`shared/autoloads/game_manager.gd`** — **no changes required**. SaveManager reads from GameManager; GameManager does not need to know about SaveManager.
- **`core/day_night/day_night_cycle.gd`** — add one public setter so SaveManager does not reach into `_phase_timer`:
    ```gdscript
    func apply_loaded_state(day: int, phase_name: String, timer_remaining: float) -> void:
        day_count = max(1, day)
        current_phase = Phase.DAY if phase_name == "DAY" else Phase.NIGHT
        _phase_timer = max(0.1, timer_remaining)
        phase_changed.emit(get_phase_name())
        _apply_tint()
    ```
    Rationale: avoids touching private vars from outside, and consolidates the post-load event emit in one place.
- **`player/scripts/player_controller.gd`** — add F11 (manual save) and F12 (load) debug hotkeys next to F10. No other logic changes.
- **`project.godot`** — register `SaveManager="*res://save/scripts/save_manager.gd"` in the `[autoload]` section **below** existing autoloads. Order matters: SaveManager depends on GameManager + DayNightCycle being ready.

### 4e. Hooks NOT wired in this task (but publicly callable)

These stay as TODO stubs with task IDs per `taskworkflow.md`:

- `TODO (UI-05)` — Pause Menu "Save" button calls `SaveManager.save_to_slot(true)` and shows result via the `save_completed` signal.
- `TODO (Main Menu)` — "Continue" button: if `SaveManager.has_save()`, call `SaveManager.load_from_slot()`; else grey-out. Use `get_save_metadata()` to label the button "Continue — Day 3".
- `TODO (Main Menu)` — "New Game" button: if `SaveManager.has_save()`, show a ConfirmationDialog; on confirm, call `SaveManager.delete_save()` before entering the starting zone.

SaveManager's public API is stable; these tasks only call it, never modify it.

---

## 5. File Structure

**New files:**
```
save/
└── scripts/
    ├── save_manager.gd          # autoload, all save/load logic
    └── save_manager.gd.uid      # Godot auto-generates on first open
```

**Modified files:**
- `project.godot` — one autoload line added.
- `core/day_night/day_night_cycle.gd` — add `apply_loaded_state()` method (~6 lines).
- `player/scripts/player_controller.gd` — add F11 / F12 / Shift+F11 debug branches in `_unhandled_input()` (~15 lines).

**No new scenes.** No new input actions. No new HUD widgets. Target total net additions: ~250 lines (including save_manager.gd).

---

## 6. Schema Migration Plan

Even at v1, wire the migration path so adding fields in v2 costs zero gymnastics.

```gdscript
func _migrate(data: Dictionary) -> Dictionary:
    var version: int = int(data.get("schema_version", 0))
    if version > SCHEMA_VERSION:
        push_warning("[SaveManager] Save version %d is newer than engine %d. Loading anyway." % [version, SCHEMA_VERSION])
        return data
    # v0 → v1: theoretical legacy path, never shipped. Kept as skeleton.
    if version < 1:
        data["schema_version"] = 1
        data["quests"] = {}
        data["unlocks"] = []
        data["difficulty"] = {"tier": "normal"}
    # Future: if version < 2: ... add new fields with sane defaults here.
    return data
```

Policy:
- **Never remove** a field across versions — leave it, ignore it, or convert it.
- **Always provide a default** for new fields in the migration.
- Bump `SCHEMA_VERSION` and add a new `if version < N:` block **in the same commit** that adds a new field.

---

## 7. Save/Load Flow Diagrams

### Autosave (SAVE-01)
```
Night cleared → WaveSpawner.wave_cleared
             → NightSurvivedScreen shown
             → GameManager.night_survived.emit(day)
             → SaveManager._on_night_survived(day)
             → SaveManager.save_to_slot(false)
             → FileAccess write user://savegame.json
             → save_completed(true, false)
```

### Manual save (SAVE-02)
```
Player presses F11 (or Pause Menu Save button)
  → player_controller._debug_save() calls SaveManager.save_to_slot(true)
  → SaveManager checks GameManager.current_state == EXPLORATION
    - if false: push_warning, emit save_completed(false, true), return false
  → write JSON
  → save_completed(true, true)
```

### Load (SAVE-02)
```
Player presses F12 (or Main Menu Continue button)
  → SaveManager.load_from_slot()
  → FileAccess read → JSON.parse_string → _migrate
  → stash in _pending_load_state
  → get_tree().change_scene_to_file(state.player.last_zone)
  → await SceneTree.process_frame (once)
  → _apply_state(_pending_load_state)
  → _pending_load_state = {}
  → load_completed(true)
```

### New Game overwrite (hook only — real UI in Main Menu task)
```
SaveManager.has_save() → true
  → Main Menu shows ConfirmationDialog       [TODO (Main Menu)]
  → On confirm: SaveManager.delete_save()
  → get_tree().change_scene_to_file("res://world/zones/meadow_edge/meadow_edge.tscn")
```

---

## 8. Debug Keys (added to `player_controller.gd`)

| Key | Action |
|-----|--------|
| F11 | `SaveManager.save_to_slot(true)` — prints result |
| F12 | `SaveManager.load_from_slot()` — prints result |
| Shift+F11 | `SaveManager.delete_save()` — used to test New Game overwrite |

Implementation pattern (match existing F1–F10 style):
```gdscript
elif event.keycode == KEY_F11:
    if event.shift_pressed:
        SaveManager.delete_save()
        print("DEBUG: Deleted save file.")
    else:
        var ok: bool = SaveManager.save_to_slot(true)
        print("DEBUG: Manual save %s" % ("OK" if ok else "BLOCKED (not in EXPLORATION)"))
elif event.keycode == KEY_F12:
    var ok: bool = SaveManager.load_from_slot()
    print("DEBUG: Load save %s" % ("OK" if ok else "FAILED"))
```

Update `PERSON_TASKS.md` → Quick Reference Debug Keys table with F11 / F12 / Shift+F11 rows (added by SAVE-01/02).

---

## 9. Acceptance Criteria

### SAVE-01 — Autosave
1. **Autosave fires on night survive.** Start a fresh run, press F8 (force wave), F9 (force clear). Console shows `[SaveManager] Autosaved (day=1)`. File `user://savegame.json` exists and contains `"schema_version": 1`, `"day_count": 1`, and populated `player` / `core` sections.
2. **Autosave does NOT fire during night** if `wave_cleared` never emits (e.g., Core destroyed). Game Over path shall not leave a corrupted half-save. Verify by pressing F1 repeatedly to destroy the Core — no new save is written and the existing save is untouched.
3. **Autosave captures current phase correctly.** After night survive, the phase at save time is still `"NIGHT"` briefly, then transitions to `"DAY"` as the DayNightCycle advances. The save must reflect the **post-advance** state (DAY, day_count +1). Solution: autosave is queued via `call_deferred` so it fires after `DayNightCycle._advance_phase` in the same frame. Verify by inspecting saved JSON after clearing Night 1 — `day_count: 2`, `current_phase: "DAY"`.
4. **Garden plants survive the save.** Place one Thornvine + one Gloomshroom via F10 before surviving the night. After autosave, the JSON `garden.plants` array contains both entries with correct `type`, `position`, and `current_hp`.
5. **Core HP captured.** Damage Core via F1 to 180 HP, then survive night. Save shows `core.current_hp: 180`.

### SAVE-02 — Manual Save + Load
6. **F11 during DAY** writes the save, prints `OK`, and updates the file's `meta.timestamp_unix`.
7. **F11 during NIGHT** is rejected, prints `BLOCKED (not in EXPLORATION)`, and leaves the existing save untouched (timestamp unchanged).
8. **F12 loads the saved state.** After placing plants, damaging Core, taking player damage, pressing F11, then moving the player and damaging the Core further, pressing F12 restores:
    - Player position and HP from save.
    - Core HP from save.
    - Garden plants (duplicates removed, saved layout restored).
    - DayNightCycle `day_count`, phase, and remaining timer from save.
9. **Shift+F11 deletes the save file.** After deletion, `SaveManager.has_save()` returns `false` and F12 prints `FAILED`.
10. **Single slot enforced.** Repeated autosaves overwrite the same file. Only one file ever exists at `user://savegame.json`.
11. **Schema migration runs on every load.** Manually edit the JSON to set `schema_version: 0` and delete the `difficulty` key. Pressing F12 upgrades the dict in memory, fills `difficulty.tier: "normal"`, and logs the migration. The next autosave writes the upgraded dict with `schema_version: 1`.
12. **Forward-compat: unknown keys survive a save-load cycle.** Manually add `"extra_key": "hello"` to the JSON and F12 → F11. The re-saved file still contains `"extra_key": "hello"`.
13. **No regressions.** CORE-04 Game Over, CORE-09 Night Survived Screen, CORE-10 HUD, DIFF-01 scaling, and PLANT-01 effects all work identically before and after loading a save. F1–F10 debug keys unchanged.

---

## 10. Existing Codebase Context

**Do NOT modify any of these beyond what §4 explicitly lists.**

### Autoloads (already registered):
- `GameManager` (`shared/autoloads/game_manager.gd`) — `current_state`, `dianthus_core`, `player`, `player_data: Dictionary {position, last_zone, inventory}`, signal `night_survived(day: int)`.
- `DayNightCycle` (`core/day_night/day_night_cycle.gd`) — `day_count: int`, `current_phase: Phase`, `get_phase_name()`, `get_time_remaining()`, signal `phase_changed(phase: String)`.
- `SceneTransition` (`core/transitions/scene_transition.gd`) — already writes `player_data.position` + `player_data.last_zone` on zone transitions. SaveManager reads the same fields, so no conflict.

### Gameplay nodes:
- `DianthusCore` (`core/dianthus_core/dianthus_core.gd`) — `current_hp: int`, `MAX_HP: const 200`, emits `hp_changed`.
- `PlayerController` (`player/scripts/player_controller.gd`) — `current_hp: int`, `MAX_HP: const 100`, emits `hp_changed`.
- `PlantBase` (`plants/entities/plant_base.gd`) — `max_hp`, `current_hp`, `is_destroyed`. Scenes live at `res://plants/entities/thornvine.tscn` and `gloomshroom.tscn`.
- `WaveSpawner` (`enemies/spawner/wave_spawner.gd`) — no direct interaction. Autosave only runs when no wave is active (post-clear, day phase).

### File I/O:
- Target `user://savegame.json`. Godot resolves `user://` to `%APPDATA%/Godot/app_userdata/Dianthus Pixie Game/` on Windows. No filesystem permission issues.
- Use `FileAccess.open(path, FileAccess.WRITE)` / `FileAccess.READ`. Check `FileAccess.get_open_error()` after opening — push_error on failure and emit `save_completed(false, manual)` / `load_completed(false)`.
- Use `JSON.stringify(data, "\t")` for pretty output (easier debugging). `JSON.parse_string(text)` returns null on malformed input — handle gracefully.

---

## 11. Important Constraints

- **GDScript only**, Godot 4.6, tabs, full type hints on parameters and return types.
- **No node references in the save file.** Ever. Serialise IDs, paths, and primitive values only. Vectors serialise as `{"x": float, "y": float}`.
- **Autosave must be re-entrant-safe.** If `night_survived` fires twice (e.g., someone calls `GameManager.trigger_night_survived()` manually), the second call must not corrupt the file — guard with a bool `_is_saving` and early-out, or with a mutex pattern using `await`.
- **Saves survive scene reloads.** The SaveManager is an autoload — its state survives `get_tree().change_scene_to_file()`. The `_pending_load_state` dictionary relies on this.
- **Never write during `DEFENSE` state.** Even autosave must confirm we are in DAY at write time (the deferred call guarantees this).
- **`print` prefix convention:** `[SaveManager]` for all logs, matching `[WaveSpawner]` and `[Debug]` patterns already in the codebase.
- **Do NOT touch** HUD, FSM states, weapon logic, PlantBase / Thornvine / Gloomshroom internals, WaveSpawner, CORE-04 Game Over screen, or CORE-09 Night Survived screen.
- **Do NOT introduce new dependencies** — no `Resource`-based save format, no custom binary packing. Stay on Godot's built-in `JSON` + `FileAccess`.
- **TODO stubs are mandatory** for every deferred integration point (quests, unlocks, difficulty, pause-menu hook, main-menu hook). Tag each with its owning task ID per `taskworkflow.md`.
- **Keep diff small** — the SaveManager is the only large new file. Every other touch should be surgical (<20 lines each). If `player_controller.gd` swells by more than 25 lines, the debug-key section is over-engineered.

---

## 12. Verification Script (manual QA)

1. Launch `meadow_edge.tscn` fresh (delete `user://savegame.json` first if it exists).
2. Place Thornvine (F10), place Gloomshroom (F10), damage Core to ~160 (F1 ×2), damage Player to ~70 (F3).
3. Press **F8** (force wave) → **F9** (force clear) → observe `[SaveManager] Autosaved (day=1)` in the console.
4. Open `%APPDATA%/Godot/app_userdata/Dianthus Pixie Game/savegame.json` in a text editor. Confirm:
    - `schema_version: 1`
    - `day_night.day_count: 2`, `current_phase: "DAY"`
    - `garden.plants.length == 2`
    - `core.current_hp ≈ 160`
    - `player.current_hp ≈ 70`
5. Press **F11** during DAY → console shows `OK`, file timestamp updates.
6. Press **F7** to advance to NIGHT. Press **F11** → console shows `BLOCKED`, file unchanged.
7. Press **F9** to clear the night, then **F10** to place a third plant, then F3 to take extra damage. Press **F12** to load — confirm player HP, Core HP, plant count, and phase all revert to the step 5 snapshot.
8. Press **Shift+F11** → save file deleted; `SaveManager.has_save()` is false; F12 prints `FAILED`.
9. Manually edit the on-disk save: set `schema_version: 0`, remove `difficulty`, add `"extra_key": "hello"`. Press F12 → migration log, `difficulty.tier: "normal"` injected, `extra_key` preserved.
10. Trigger Game Over (F1 spam) on a save-existing run. Confirm the save file is **not** deleted.

---

## 13. Out of Scope (future tasks — do NOT implement)

- **Pause Menu Save button** → UI-05 (Person C). SaveManager.save_to_slot() is ready to call.
- **Main Menu Continue / New Game flow** → Main Menu task (Person C Week 2). `has_save()`, `get_save_metadata()`, `load_from_slot()`, `delete_save()` are ready to call.
- **Quest state serialisation** → QUEST-01. `quests: {}` is reserved.
- **Unlock flag serialisation** (True Ending, Endless mode, etc.) → END-01, END-04. `unlocks: []` is reserved.
- **Difficulty persistence** → ACCESS-01. `difficulty.tier` defaults to `"normal"`.
- **Autosave-on-exit / autosave-on-zone-transition** → out of scope. Autosave only fires on night-survive per GDD §11.3.
- **New Game+ carryover** → separate task; affects migration v1→v2 only.
- **Cloud / Steam sync** → not planned.
- **Encrypted save** → not planned for the 2-week slice.
- **Multiple slots** → GDD §11.3 explicitly forbids.

---

## 14. Post-Task Memory Update

After completing SAVE-01 + SAVE-02, record in memory (per `taskworkflow.md`):

- New files: `save/scripts/save_manager.gd`, `save/scripts/save_manager.gd.uid`
- Modified files: `project.godot`, `core/day_night/day_night_cycle.gd`, `player/scripts/player_controller.gd`, `docs/design/PERSON_TASKS.md` (debug keys table)
- Save schema version: `1`
- Reserved schema keys (empty until their task lands): `quests`, `unlocks`, `difficulty`
- Debug keys added: F11, F12, Shift+F11
- Next downstream tasks that can now call SaveManager: UI-05, Main Menu, QUEST-01, ACCESS-01, END-01
