# PROMPT — QUEST-01: Quest System Architecture

**Task ID:** QUEST-01
**Category:** Quest System
**Priority:** High
**Dependencies:** FOUND-01 (project bootstrap), CORE-09 (day/night cycle), CORE-10 (game state), SAVE-01 (save system)
**Blocks:** QUEST-02 (Daily), QUEST-03 (Progress), QUEST-04 (Discovery), QUEST-05 (Story), UI-03 (Quest Log)
**GDD Reference:**
- §11.2 — "Quest Log — tombol Q; menampilkan active quests dan progress"
- §16 — Quest System types (Daily / Progress / Discovery / Story) + "Story Quest menggunakan Dialogic timeline untuk percakapan penting"
- §5.1 — "Gagal menyelesaikan Critical Story Quest ... memicu ending alternatif, bukan game over langsung"

---

## Goal

Implement the **foundation** of the quest system: a `QuestManager` autoload that tracks active and completed quests, driven by `QuestData` Resource files (not hard-coded), with signals consumed by the upcoming Quest Log UI (UI-03) and downstream quest types (QUEST-02..05). Story quests must be authorable through the **Dialogic** addon already installed at `addons/dialogic/`.

This task delivers **architecture only** — no specific quest content (those belong to QUEST-02..05). Ship one or two trivial sample quests purely to prove the pipeline end-to-end.

---

## Scope

### In Scope
1. **`QuestData` Resource** (`quests/data/quest_data.gd`) — typed quest definition with objectives, rewards, metadata.
2. **`QuestObjective` Resource** (`quests/data/quest_objective.gd`) — single objective with a typed `event_id` + target count.
3. **`QuestManager` autoload** (`quests/scripts/quest_manager.gd`) — registers quests, tracks active/completed, emits signals, grants rewards.
4. **Generic event bus pattern** — `QuestManager.report_event(event_id: StringName, amount: int = 1, context: Dictionary = {})` so any system can drive progress without coupling.
5. **Hooks from existing systems** that report events (no UI yet, just emissions):
   - `InventoryManager.item_added` → `report_event(&"item_collected", amount, {"item_id": id})`
   - `DayNightCycle.day_changed` → `report_event(&"day_survived", 1, {"day": n})`
   - `EnemyBase._die` → `report_event(&"enemy_killed", 1, {"enemy_type": type})`
   - `BreedingManager.breed_succeeded` → `report_event(&"plant_bred", 1, {"plant_id": id})`
   - `CodexManager.plant_discovered` → `report_event(&"plant_discovered", 1, {"plant_id": id})`
   - `CraftingManager.weapon_crafted` → `report_event(&"weapon_crafted", 1, {"weapon_id": id})`
6. **Reward grant pipeline** — items into `InventoryManager`, weapon unlocks via `CraftingManager.owned_weapons`, hook stub for `unlock_flag` (deferred to QUEST-03).
7. **Save/load integration** — schema bump, serialize active/completed quest state.
8. **Dialogic integration** — `QuestManager` listens to `Dialogic.signal_event` so a Dialogic timeline can call `[signal arg="quest_start:quest_id"]` / `[signal arg="quest_complete:quest_id"]` / `[signal arg="quest_fail:quest_id"]`.
9. **Quest Log API** for UI-03 — `get_active_quests()`, `get_completed_quests()`, `get_progress(quest_id)` returning a normalized 0..1 list per objective.
10. **Two demo quest resources** (`quests/data/demo/`) — one Daily-style ("Collect 5 Petal Shard"), one Story-style stub that triggers a Dialogic timeline. These are throwaway samples to prove the system; QUEST-02..05 will replace them.
11. **Debug keys** in `player_controller.gd`: `Shift+K` lists active quests + progress; `Shift+Alt+K` force-completes the first active quest.

### Out of Scope (explicit `TODO: <TASK-ID>` stubs)
- **UI-03** Quest Log screen — leave a `# TODO: UI-03` comment where the screen would be instanced. No HUD pinning yet.
- **QUEST-02** Daily quest generation/expiry logic — leave `# TODO: QUEST-02` in `_on_day_changed` for daily reroll.
- **QUEST-03** Progress quest cumulative tracking beyond what objectives already give.
- **QUEST-04** Discovery quest auto-generation when new combos attempted.
- **QUEST-05** Full story chain authoring (Ruins → Voidlord → Devourer). Only the Dialogic ↔ QuestManager glue is required here.
- Time-limited quests / failure → alternative ending wiring (stub `_on_quest_failed` only; END branch deferred).
- Multi-stage quests (chained objectives that unlock subsequent objectives) — leave `next_quest_id` field on `QuestData` but do not implement chaining yet.

---

## Existing Architecture Reference

### Autoload Order (project.godot — current)
1. GameManager
2. DayNightCycle
3. SaveManager
4. DifficultyManager
5. InventoryManager
6. CraftingManager
7. BreedingManager
8. CodexManager
9. **QuestManager** ← insert here, before any quest-aware UI
10. (Dialogic autoload is registered by the addon)

### Existing Signal Sources (already implemented, just connect)
| Source | Signal | Payload |
|---|---|---|
| `InventoryManager` | `item_added(item_id, amount)` | string, int |
| `DayNightCycle` | `day_changed(day)` and `phase_changed(phase)` | int / enum |
| `EnemyBase` | inside `_die()` — no signal yet, **add `signal enemy_died(enemy_type: String)`** and emit before `queue_free()` |
| `BreedingManager` | `breed_succeeded(combo_id, output_seed_id)` | string, string |
| `CodexManager` | `plant_discovered(plant_id)` | string |
| `CraftingManager` | `weapon_crafted(weapon_id)` | string |

### Existing Patterns to Follow
- **Static data class** like `RecipeDatabase`, `ItemDatabase`, `PlantRegistry` — **but do not use this here**: quest data must be `Resource` files per acceptance criteria.
- **Autoload + serialize/deserialize** like `CraftingManager`, `BreedingManager`, `CodexManager` (`serialize() -> Dictionary` / `deserialize(Dictionary)`).
- **Save schema** — current version is **7** (set by PLANT-08). Bump to **8** for quests.
- **CanvasLayer UI** with `PROCESS_MODE_ALWAYS` — UI-03 will use **layer 95** (last reserved was 94 = LoadoutScreen).
- **Debug-only keys** in `player_controller.gd._unhandled_input` guarded by `OS.is_debug_build()` checks where appropriate.

### Dialogic Addon (already installed)
- Path: `addons/dialogic/`, version `2.0-Alpha-19 (Godot 4.4+)`.
- Plugin auto-registers a global `Dialogic` autoload (singleton).
- Relevant API (do not modify the addon — only consume it):
  - `Dialogic.start(timeline_resource_or_path)` — begins a timeline.
  - `Dialogic.timeline_ended` signal.
  - `Dialogic.signal_event(argument)` signal — fires when a timeline executes a `[signal]` event with a string argument.
- **Integration contract**: timelines drive quest state by emitting `[signal arg="quest_start:<id>"]`, `[signal arg="quest_complete:<id>"]`, `[signal arg="quest_fail:<id>"]`. `QuestManager._on_dialogic_signal()` parses the prefix and dispatches.

---

## Implementation Plan

### 1. Quest Data Resources

#### `quests/data/quest_objective.gd`
```gdscript
class_name QuestObjective
extends Resource

@export var objective_id: StringName = &""           # Unique within parent quest
@export var description: String = ""                  # "Collect 10 Petal Shard"
@export var event_id: StringName = &""                # &"item_collected", &"enemy_killed", etc.
@export var target_count: int = 1
@export var filter: Dictionary = {}                   # e.g. {"item_id": "petal_shard"}, optional
```

`filter` is matched against the `context` dict passed to `report_event()`. An objective increments its counter only if every key in `filter` matches `context`. Empty filter = always matches.

#### `quests/data/quest_data.gd`
```gdscript
class_name QuestData
extends Resource

enum Type { DAILY, PROGRESS, DISCOVERY, STORY }

@export var quest_id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var quest_type: Type = Type.DAILY
@export var objectives: Array[QuestObjective] = []
@export var reward_items: Dictionary = {}            # {"petal_shard": 5, "aether_bloom": 1}
@export var reward_weapons: Array[String] = []       # weapon_ids unlocked via CraftingManager
@export var reward_unlock_flags: Array[String] = []  # opaque flags — TODO: QUEST-03
@export var time_limit_days: int = 0                 # 0 = none; >0 = fail if active beyond that many day_changed events
@export var dialogic_timeline_on_complete: String = ""  # optional: timeline path to play on complete
@export var dialogic_timeline_on_fail: String = ""
@export var next_quest_id: StringName = &""          # TODO: chaining (deferred)
@export var auto_start: bool = false                 # if true, QuestManager starts on _ready (after registry load)
```

#### Demo resources (`quests/data/demo/`)
- `demo_daily_petals.tres` — 1 objective: collect 5 `petal_shard`; reward 1 `verdant_sap`.
- `demo_story_intro.tres` — story quest, no auto-start; `dialogic_timeline_on_complete` points to a sample timeline (create a stub `.dtl` only if trivial, else leave blank with TODO).

### 2. QuestManager Autoload — `quests/scripts/quest_manager.gd`

```gdscript
extends Node

const QUEST_DIR := "res://quests/data/"

signal quest_started(quest_id: StringName)
signal quest_progress_updated(quest_id: StringName, objective_id: StringName, current: int, target: int)
signal quest_completed(quest_id: StringName)
signal quest_failed(quest_id: StringName, reason: String)
signal quest_rewards_granted(quest_id: StringName, items: Dictionary, weapons: Array)

var _registry: Dictionary = {}             # quest_id -> QuestData
var _active: Dictionary = {}               # quest_id -> { progress: { obj_id: int }, started_day: int }
var _completed: Dictionary = {}            # quest_id -> true
var _failed: Dictionary = {}               # quest_id -> reason

func _ready() -> void:
    _scan_registry()
    _connect_event_sources()
    _connect_dialogic()
    for q in _registry.values():
        if q.auto_start and not is_completed(q.quest_id):
            start_quest(q.quest_id)

# Public API
func start_quest(id: StringName) -> bool
func complete_quest(id: StringName) -> void          # internal use; also callable from Dialogic
func fail_quest(id: StringName, reason: String) -> void
func is_active(id: StringName) -> bool
func is_completed(id: StringName) -> bool
func get_active_quests() -> Array[QuestData]
func get_completed_quests() -> Array[QuestData]
func get_progress(id: StringName) -> Dictionary     # { obj_id: { current, target, description } }
func report_event(event_id: StringName, amount: int = 1, context: Dictionary = {}) -> void

# Internals
func _scan_registry() -> void                        # Walks QUEST_DIR recursively, loads .tres into _registry
func _connect_event_sources() -> void                # Connect InventoryManager, DayNightCycle, EnemyBase signals
func _connect_dialogic() -> void                     # Connect Dialogic.signal_event if Dialogic singleton exists
func _on_dialogic_signal(arg: String) -> void        # Parses "quest_start:id" / "quest_complete:id" / "quest_fail:id"
func _grant_rewards(q: QuestData) -> void
func _matches_filter(filter: Dictionary, context: Dictionary) -> bool
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void
```

**Event-driven progress (key algorithm):**
```gdscript
func report_event(event_id, amount, context := {}) -> void:
    for quest_id in _active.keys():
        var q: QuestData = _registry[quest_id]
        var prog: Dictionary = _active[quest_id].progress
        var all_done := true
        for obj in q.objectives:
            if obj.event_id == event_id and _matches_filter(obj.filter, context):
                prog[obj.objective_id] = mini(prog.get(obj.objective_id, 0) + amount, obj.target_count)
                quest_progress_updated.emit(quest_id, obj.objective_id, prog[obj.objective_id], obj.target_count)
            if prog.get(obj.objective_id, 0) < obj.target_count:
                all_done = false
        if all_done:
            complete_quest(quest_id)
```

`_connect_event_sources()` does the wiring listed in the **Hooks** scope above. Each handler calls `report_event` with the right `event_id` + context.

### 3. EnemyBase Signal Addition — `enemies/enemy_base.gd`

Add `signal enemy_died(enemy_type: String)` near other signals; emit it in `_die()` immediately before `queue_free()`. Pass `get("enemy_type") if has_meta("enemy_type") else self.get_class()` — or simpler: derive from scene filename. Keep it minimal — QUEST-02 will refine filter taxonomy.

Connect in `QuestManager._connect_event_sources` lazily by iterating `get_tree().get_nodes_in_group("enemies")` AND by listening to a new `WaveSpawner.enemy_spawned(enemy)` signal you add — `WaveSpawner._spawn_enemy()` should `emit_signal("enemy_spawned", enemy)` after `add_child(enemy)`. Then QuestManager connects each spawned enemy's `enemy_died`.

### 4. Save/Load — `save/scripts/save_manager.gd`

- Bump `SCHEMA_VERSION` to **8**.
- `_gather_state()` — `state["quests"] = QuestManager.serialize()`.
- `_apply_state()` — call `QuestManager.deserialize(state.get("quests", {}))` after CodexManager and before player loadout.
- `_migrate()` — v7 → v8 adds `state["quests"] = { "active": {}, "completed": {}, "failed": {} }`.
- `serialize()` returns `{ active: { id: { progress, started_day } }, completed: { id: true }, failed: { id: reason } }` — only IDs, not full QuestData (registry is reloaded from disk on boot).

### 5. Dialogic Glue

```gdscript
func _connect_dialogic() -> void:
    var dialogic := get_node_or_null("/root/Dialogic")
    if dialogic == null:
        push_warning("QuestManager: Dialogic singleton not found; story quest hooks disabled.")
        return
    if dialogic.has_signal("signal_event"):
        dialogic.signal_event.connect(_on_dialogic_signal)

func _on_dialogic_signal(arg: Variant) -> void:
    var s := str(arg)
    var parts := s.split(":", false, 1)
    if parts.size() != 2:
        return
    var cmd: String = parts[0]
    var qid: StringName = StringName(parts[1])
    match cmd:
        "quest_start":    start_quest(qid)
        "quest_complete": complete_quest(qid)
        "quest_fail":     fail_quest(qid, "dialogic")
```

Conversely, on `complete_quest`, if `q.dialogic_timeline_on_complete != ""` and Dialogic exists, call `Dialogic.start(q.dialogic_timeline_on_complete)`.

### 6. Input Actions & Debug — `project.godot` + `player_controller.gd`

- Add `quest_log_toggle` action (Q key, physical_keycode=81). **Note:** Q currently maps to `activate_skill` per PLANT-08. Resolve by **moving `activate_skill` to `Space` or `F`** (your choice, document the migration in `PERSON_TASKS.md`); per GDD §11.2 Q is reserved for Quest Log. Pick `F` to avoid jump conflicts and update PLANT-08 hotkey row.
- `Shift+K` debug → print active quest progress to console.
- `Shift+Alt+K` debug → call `QuestManager.complete_quest(first_active_id)`.

### 7. UI-03 Stub

Do **not** build the Quest Log screen here. In `meadow_edge.tscn`, add a comment-only placeholder:

```
# TODO: UI-03 — instance QuestLogScreen here once implemented
```

But ensure `quest_log_toggle` action is routed in `player_controller.gd._unhandled_input` to a no-op that prints `"TODO: UI-03"` so the binding compiles cleanly.

---

## Files to Create

| File | Purpose |
|------|---------|
| `quests/data/quest_objective.gd` | `class_name QuestObjective extends Resource` |
| `quests/data/quest_data.gd` | `class_name QuestData extends Resource`, with Type enum |
| `quests/data/demo/demo_daily_petals.tres` | Sample DAILY quest |
| `quests/data/demo/demo_story_intro.tres` | Sample STORY quest with Dialogic hook |
| `quests/scripts/quest_manager.gd` | Autoload — registry, active/completed tracking, signals, save/load |

## Files to Modify

| File | Change |
|------|--------|
| `project.godot` | Register `QuestManager` autoload after `CodexManager`; add `quest_log_toggle` (Q); remap `activate_skill` from Q to F |
| `enemies/enemy_base.gd` | Add `signal enemy_died(enemy_type)`; emit in `_die()` before `queue_free()` |
| `enemies/spawner/wave_spawner.gd` | Add `signal enemy_spawned(enemy)`; emit in `_spawn_enemy()` |
| `inventory/scripts/inventory_manager.gd` | (no change — `item_added` already exists) |
| `core/day_night/day_night_cycle.gd` | (no change if `day_changed` exists; else add) |
| `crafting/breeding/breeding_manager.gd` | (no change — `breed_succeeded` exists) |
| `crafting/scripts/crafting_manager.gd` | (no change — `weapon_crafted` exists) |
| `ui/codex/codex_manager.gd` | (no change — `plant_discovered` exists) — remove the `TODO: QUEST-04` stub comment |
| `save/scripts/save_manager.gd` | `SCHEMA_VERSION=8`; gather/apply quests; v7→v8 migration |
| `world/zones/meadow_edge/meadow_edge.tscn` | Add UI-03 placeholder comment (no instance) |
| `player/scripts/player_controller.gd` | Activate-skill key migrated to F; Shift+K / Shift+Alt+K debug; `quest_log_toggle` no-op |
| `docs/design/TASK_BREAKDOWN.md` | Set QUEST-01 status to **Done** |
| `docs/design/PERSON_TASKS.md` | Document Q (quest_log_toggle, currently no-op until UI-03), F (activate_skill, was Q), Shift+K, Shift+Alt+K |

---

## Acceptance Criteria

1. `QuestManager` autoload boots without errors on a fresh project; registry scan finds the two demo quests.
2. Starting `demo_daily_petals` and picking up 5 Petal Shard pickups completes the quest, grants 1 Verdant Sap, and emits `quest_completed` exactly once.
3. `quest_progress_updated` fires for every relevant `item_added` event with monotonically non-decreasing `current`.
4. Quest data lives entirely in `.tres` files — `QuestManager` contains zero hard-coded quest definitions (greppable: no `display_name = "..."` literals inside `quest_manager.gd`).
5. Calling `Dialogic.start(...)` on a timeline that fires `[signal arg="quest_start:demo_story_intro"]` causes that quest to enter `_active`. A timeline emitting `[signal arg="quest_complete:demo_story_intro"]` triggers `quest_completed` and grants its rewards.
6. Save → quit → reload restores active quest progress, completed set, and failed set (schema v8).
7. Old saves at schema v7 migrate cleanly to v8 with empty quest state.
8. `Shift+K` prints a readable summary of active quests; `Shift+Alt+K` force-completes the first active quest and grants rewards.
9. No new lint errors or missing-class warnings in scripts (Godot reload may be required for `class_name` propagation — note this in completion memory).
10. Pressing **Q** does not crash; logs `TODO: UI-03`. Pressing **F** activates the skill (formerly Q) — verify PLANT-08 behavior unchanged.

---

## Notes & Gotchas

- **Hotkey collision (Q):** GDD §11.2 explicitly assigns Q to Quest Log, but PLANT-08 already used Q for `activate_skill`. This task is the right place to resolve it — migrate skill to F and update HUD label in `hud.tscn` (`SkillKeyLabel.text = "F"`).
- **Dialogic resilience:** Project must still run if Dialogic addon is disabled — every Dialogic call is guarded by `get_node_or_null("/root/Dialogic")`.
- **Resource-driven authoring:** Future quest authors edit `.tres` in the editor inspector — never modify `quest_manager.gd`. Confirm by adding a third demo `.tres` last and verifying `_scan_registry` picks it up with no code change.
- **Filter semantics:** Keep `filter` matching shallow (top-level keys) for QUEST-01. Nested matching is overkill — defer to QUEST-04 if needed.
- **Time limits:** Field exists on `QuestData` but only stub the check — wire `time_limit_days` decrement on `day_changed` and emit `quest_failed("time_limit")` only if the value is > 0; downstream END-branch logic is QUEST-05.
- **Performance:** `report_event` iterates active quests on every event. With ≤ ~20 active quests this is fine; if it ever balloons, index by `event_id` later — not now.
- **No QuestManager → BreedingManager / CraftingManager / CodexManager backwards dependencies** — QuestManager is a *consumer* only. This keeps the autoload DAG acyclic.
