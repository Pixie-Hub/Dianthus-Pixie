# ACCESS-01 & ACCESS-02 — Difficulty Levels + Colorblind Mode — Implementation Prompt

**Project:** Dianthus Pixie
**Engine:** Godot 4.6 (GDScript)
**Effort:** ACCESS-01 M (1–3 days) · ACCESS-02 S (< 1 day)
**Priority:** ACCESS-01 High · ACCESS-02 Medium
**Dependencies:** DIFF-01 (Simple Difficulty Scaling — Done), CORE-07 (Wave Spawner — Done), CORE-10 (HUD — Done), UI-05 (Pause/Settings — Done), SAVE-01/02 (Save System — Done)
**Downstream dependents:** SAVE schema v2 (difficulty field no longer stub), future balance tuning, ACCESS-03 (tutorial may reference difficulty label)

---

## 1. Objective

### ACCESS-01 — 3 Difficulty Levels

Implement three selectable difficulty tiers per GDD §11.4:

| Tier | ID (int) | Enemy Stat Modifier | Description |
|------|----------|---------------------|-------------|
| Easy | 0 | **−20%** HP, DMG, speed | Relaxed experience for casual / younger players |
| Normal | 1 | **±0%** (baseline) | Default — matches current DIFF-01 scaling |
| Hard | 2 | **+30%** HP, DMG, speed | Challenge mode — enemies are noticeably tougher and faster |

Requirements:
1. **Selectable at new game start** — the Main Menu "New Game" flow should allow picking difficulty before the game begins (or default to Normal if skipped).
2. **Changeable mid-run** — the Settings screen (already has a `DifficultyOption` OptionButton with stub handler) must apply the change immediately. The next wave will use the new modifiers.
3. **Persisted** — difficulty tier is saved in `settings.cfg` (already done) **and** in the save file's `difficulty` key (currently a stub `{"tier": "normal"}`).
4. **Applied multiplicatively on top of DIFF-01 scaling** — the per-day linear scaling from `WaveSpawner` remains unchanged. Difficulty acts as a global modifier layer applied to each spawned enemy.

### ACCESS-02 — Colorblind Mode

Add supplemental shape/icon indicators to the HP and Energy HUD bars so color is not the sole information channel, per GDD §11.4:

- **Player HP bar** — a small heart icon (♥ / Label glyph) next to or overlaid on the bar.
- **Core HP bar** — a small shield icon (🛡 / Label glyph) next to or overlaid on the bar.
- **Energy bar** — a small lightning bolt icon (⚡ / Label glyph) next to or overlaid on the bar. *(Energy bar does not exist yet — place a `TODO: PLANT-07` stub for it and only add the colorblind icon node; do not implement the energy system.)*

When colorblind mode is **off** (default): icons are hidden.
When colorblind mode is **on**: icons are visible, providing redundant non-color identification.

Toggle is the existing `ColorblindToggle` CheckButton in Settings, which already persists to `settings.cfg`.

---

## 2. Architecture — ACCESS-01

### 2a. New autoload: `DifficultyManager` (`accessibility/difficulty/difficulty_manager.gd`)

Create a lightweight singleton that holds the current difficulty tier and exposes multipliers. This keeps difficulty logic out of `WaveSpawner` (single-responsibility).

```gdscript
class_name DifficultyManager
extends Node

signal difficulty_changed(tier_id: int)

enum Tier { EASY = 0, NORMAL = 1, HARD = 2 }

const TIER_DATA: Dictionary = {
    Tier.EASY:   { "label": "Easy",   "hp_mult": 0.80, "dmg_mult": 0.80, "speed_mult": 0.80 },
    Tier.NORMAL: { "label": "Normal", "hp_mult": 1.00, "dmg_mult": 1.00, "speed_mult": 1.00 },
    Tier.HARD:   { "label": "Hard",   "hp_mult": 1.30, "dmg_mult": 1.30, "speed_mult": 1.30 },
}

var current_tier: Tier = Tier.NORMAL


func set_tier(tier_id: int) -> void:
    var new_tier: Tier = tier_id as Tier
    if new_tier == current_tier:
        return
    current_tier = new_tier
    difficulty_changed.emit(int(current_tier))
    print("[DifficultyManager] Tier changed to %s" % get_tier_label())


func get_tier_label() -> String:
    return TIER_DATA[current_tier]["label"]


func get_hp_multiplier() -> float:
    return TIER_DATA[current_tier]["hp_mult"]


func get_dmg_multiplier() -> float:
    return TIER_DATA[current_tier]["dmg_mult"]


func get_speed_multiplier() -> float:
    return TIER_DATA[current_tier]["speed_mult"]


func get_tier_id() -> int:
    return int(current_tier)
```

### 2b. Register autoload in `project.godot`

Add below the `SaveManager` line in `[autoload]`:
```
DifficultyManager="*res://accessibility/difficulty/difficulty_manager.gd"
```

### 2c. Integrate into `WaveSpawner` (`enemies/spawner/wave_spawner.gd`)

Modify `_spawn_enemy()` to apply difficulty multipliers **after** the existing DIFF-01 per-day HP scaling and **before** `add_child()`. This makes the two systems stack multiplicatively.

**Current code** (lines ~109–111):
```gdscript
if _current_hp_multiplier > 1.0:
    enemy.max_hp = int(round(enemy.max_hp * _current_hp_multiplier))
    enemy.current_hp = enemy.max_hp
```

**Replace with:**
```gdscript
# DIFF-01: Per-day HP scaling.
var effective_hp_mult: float = _current_hp_multiplier
# ACCESS-01: Difficulty tier HP modifier (stacks multiplicatively).
effective_hp_mult *= DifficultyManager.get_hp_multiplier()
if effective_hp_mult != 1.0:
    enemy.max_hp = int(round(enemy.max_hp * effective_hp_mult))
    enemy.current_hp = enemy.max_hp

# ACCESS-01: Difficulty tier damage modifier.
var dmg_mult: float = DifficultyManager.get_dmg_multiplier()
if dmg_mult != 1.0:
    enemy.damage = int(round(enemy.damage * dmg_mult))

# ACCESS-01: Difficulty tier speed modifier.
var spd_mult: float = DifficultyManager.get_speed_multiplier()
if spd_mult != 1.0:
    enemy.move_speed *= spd_mult
```

**Update the `start_wave()` print line** to include difficulty label:
```gdscript
print("[WaveSpawner] Wave started. Day: %d, Difficulty: %s, Entry points: %d, Enemies: %d, HP x%.2f" \
    % [day, DifficultyManager.get_tier_label(), count, _current_wave_total, _current_hp_multiplier])
```

### 2d. Wire Settings screen (`ui/menus/settings_screen.gd`)

Replace the `_on_difficulty_changed` stub:

```gdscript
func _on_difficulty_changed(index: int) -> void:
    DifficultyManager.set_tier(index)
```

Also add to `_load_settings()`, after setting `_difficulty_option.selected`:
```gdscript
DifficultyManager.set_tier(_difficulty_option.selected)
```

This ensures `DifficultyManager.current_tier` is correct on startup.

### 2e. Wire Main Menu — difficulty on New Game

In `main_menu.gd`, the `_start_new_game()` function should reset `DifficultyManager` to match the Settings screen selection. Since `settings_screen.gd._load_settings()` already calls `DifficultyManager.set_tier()` on `_ready()`, and the Settings screen is a child of the Main Menu scene, no extra code is needed here — the tier is already live.

However, if you want the Main Menu to show the current difficulty label on the "New Game" button (nice-to-have), add after `_refresh_continue_button()` in `_ready()`:
```gdscript
# Optional: show difficulty on the New Game button tooltip.
# %NewGameButton.tooltip_text = "Starts on %s difficulty" % DifficultyManager.get_tier_label()
```
This is optional — skip if time is tight.

### 2f. Save/Load integration (`save/scripts/save_manager.gd`)

**In `_gather_state()`** — replace the stub:
```gdscript
# Current:
state["difficulty"] = {"tier": "normal"}  # TODO (ACCESS-01)

# Replace with:
state["difficulty"] = {"tier": DifficultyManager.get_tier_label().to_lower()}
```

**In `_apply_state()`** — add after the inventory restoration (step 5) and before the garden restoration (step 6):
```gdscript
# 5.5 Difficulty tier.
var diff_tier: String = state.get("difficulty", {}).get("tier", "normal")
match diff_tier:
    "easy":
        DifficultyManager.set_tier(DifficultyManager.Tier.EASY)
    "hard":
        DifficultyManager.set_tier(DifficultyManager.Tier.HARD)
    _:
        DifficultyManager.set_tier(DifficultyManager.Tier.NORMAL)
```

**In `_migrate()`** — the existing v0→v1 migration already seeds `data["difficulty"] = {"tier": "normal"}`, so no additional migration logic is needed for ACCESS-01. The schema version remains 1.

---

## 3. Architecture — ACCESS-02

### 3a. Colorblind signal on GameManager or standalone

The simplest approach: `DifficultyManager` (or a separate signal) is overkill. Instead, use the existing `settings.cfg` persistence and a global signal. Add a **colorblind signal** to `GameManager`:

```gdscript
# In game_manager.gd — add signal at top:
signal colorblind_mode_changed(enabled: bool)

# Add variable:
var colorblind_mode: bool = false

# Add setter:
func set_colorblind_mode(enabled: bool) -> void:
    if colorblind_mode == enabled:
        return
    colorblind_mode = enabled
    colorblind_mode_changed.emit(enabled)
    print("[GameManager] Colorblind mode: %s" % ("ON" if enabled else "OFF"))
```

### 3b. Wire Settings screen

Replace the `_on_colorblind_toggled` stub in `settings_screen.gd`:

```gdscript
func _on_colorblind_toggled(enabled: bool) -> void:
    GameManager.set_colorblind_mode(enabled)
```

Also in `_load_settings()`, after setting `_colorblind_toggle.button_pressed`, add:
```gdscript
GameManager.set_colorblind_mode(_colorblind_toggle.button_pressed)
```

### 3c. HUD modifications (`ui/hud/hud.gd` + `ui/hud/hud.tscn`)

Add icon Labels to the HUD scene and toggle their visibility via the signal.

**Scene changes (`hud.tscn`):**

Add a `Label` node as a sibling to each HP bar, inside each `VBoxContainer`:

1. **PlayerHPIcon** — child of `PlayerHPContainer/VBoxContainer`, placed after `PlayerHPBar`
   - `unique_name_in_owner = true`
   - `text = "♥"` (heart glyph)
   - `theme_override_font_sizes/font_size = 8`
   - `theme_override_colors/font_color = Color(0.9, 0.2, 0.2, 1)` (match bar color)
   - `visible = false`

2. **CoreHPIcon** — child of `CoreHPContainer/VBoxContainer`, placed after `CoreHPBar`
   - `unique_name_in_owner = true`
   - `text = "🛡"` (shield glyph) — or use text `"[S]"` if Unicode rendering is unreliable in the pixel font
   - `theme_override_font_sizes/font_size = 8`
   - `theme_override_colors/font_color = Color(0.2, 0.9, 0.3, 1)` (match bar color)
   - `visible = false`

3. **EnergyIcon** — *(placeholder, do not create a full energy bar)*
   - Add a comment in `hud.gd`: `# TODO (PLANT-07): Add EnergyIcon (⚡) label next to future Energy bar.`
   - No node needed yet since the energy bar itself does not exist.

**Script changes (`hud.gd`):**

```gdscript
# New @onready vars:
@onready var _player_hp_icon: Label = %PlayerHPIcon
@onready var _core_hp_icon: Label = %CoreHPIcon

# In _ready(), add:
GameManager.colorblind_mode_changed.connect(_on_colorblind_changed)
_on_colorblind_changed(GameManager.colorblind_mode)

# New function:
func _on_colorblind_changed(enabled: bool) -> void:
    _player_hp_icon.visible = enabled
    _core_hp_icon.visible = enabled
```

### 3d. Standalone HP bar scenes (optional consistency)

The standalone `core_hp_bar.gd` / `player_hp_bar.gd` scenes appear to be earlier implementations superseded by the unified `hud.gd`. If they are still used anywhere, apply the same icon pattern. If they are unused (which is likely — the unified HUD handles both bars), leave them untouched and add a comment:
```gdscript
# NOTE: Colorblind icons are handled in ui/hud/hud.gd. This standalone bar
# does not have them. If this scene is reactivated, add icon support per ACCESS-02.
```

---

## 4. File Structure

### New files:
| File | Purpose |
|------|---------|
| `accessibility/difficulty/difficulty_manager.gd` | `DifficultyManager` autoload — holds current tier, exposes multipliers, emits `difficulty_changed` |

### Modified files:
| File | Changes |
|------|---------|
| `project.godot` | Add `DifficultyManager` autoload entry in `[autoload]` |
| `enemies/spawner/wave_spawner.gd` | Apply difficulty multipliers in `_spawn_enemy()`, update log in `start_wave()` |
| `ui/menus/settings_screen.gd` | Wire `_on_difficulty_changed` → `DifficultyManager.set_tier()`, wire `_on_colorblind_toggled` → `GameManager.set_colorblind_mode()`, apply both on `_load_settings()` |
| `shared/autoloads/game_manager.gd` | Add `colorblind_mode` var, `colorblind_mode_changed` signal, `set_colorblind_mode()` method |
| `save/scripts/save_manager.gd` | Replace difficulty stub in `_gather_state()`, add restore in `_apply_state()` |
| `ui/hud/hud.gd` | Add `@onready` refs for icon labels, connect `colorblind_mode_changed`, toggle visibility |
| `ui/hud/hud.tscn` | Add `PlayerHPIcon` and `CoreHPIcon` Label nodes (visible = false by default) |

### Not modified (confirmed no-touch):
- `enemies/enemy_base.gd` — multipliers are applied per-instance in `_spawn_enemy()`, not in the base class
- `core/day_night/day_night_cycle.gd` — no changes
- `player/scripts/player_controller.gd` — no new debug keys
- `enemies/fsm/` — no FSM changes
- `plants/entities/` — no plant changes

---

## 5. Acceptance Criteria

### ACCESS-01

1. **Settings UI shows 3 options:** Easy, Normal (default), Hard in `DifficultyOption`. Selecting one calls `DifficultyManager.set_tier()` immediately.
2. **Easy mode reduces enemy stats:** On Easy, Day 1 Shadowling should have `round(40 * 0.80) = 32 HP`, `round(8 * 0.80) = 6 DMG`, and `40.0 * 0.80 = 32.0 px/s` speed. Verify via console log or debugger.
3. **Hard mode increases enemy stats:** On Hard, Day 1 Shadowling should have `round(40 * 1.30) = 52 HP`, `round(8 * 1.30) = 10 DMG`, and `40.0 * 1.30 = 52.0 px/s` speed.
4. **Normal mode is baseline:** On Normal, Day 1 Shadowling has exactly 40 HP, 8 DMG, 40.0 speed — identical to pre-ACCESS-01 behavior.
5. **Stacks with DIFF-01 scaling:** On Hard, Day 3 Shadowling has `round(40 * 1.20 * 1.30) = round(62.4) = 62 HP`. The per-day multiplier (1.20) and difficulty multiplier (1.30) stack multiplicatively.
6. **Mid-run change works:** Start on Normal, survive Night 1. Open Settings, switch to Easy. On Night 2, enemies should be weaker than they would have been on Normal Day 2.
7. **Persisted in settings.cfg:** Close and reopen the game. The difficulty selection in Settings should restore to the previously chosen tier.
8. **Persisted in save file:** Save on Hard, quit, load — `DifficultyManager.current_tier` should be `HARD` after load.
9. **No regression:** `wave_cleared` still fires correctly. Night Survived screen still appears. CORE-09 flow is unbroken.

### ACCESS-02

1. **Colorblind OFF (default):** No icons visible on Player HP or Core HP bars. HUD looks identical to pre-ACCESS-02.
2. **Colorblind ON:** Heart icon (♥) appears next to Player HP bar. Shield icon appears next to Core HP bar. Both are small and non-intrusive.
3. **Toggle is reactive:** Turning colorblind mode on/off in Settings immediately shows/hides the icons without restarting the game.
4. **Persisted in settings.cfg:** Close and reopen the game. Colorblind mode restores from `settings.cfg`.
5. **Energy bar stub:** A `TODO (PLANT-07)` comment exists in `hud.gd` for the future energy icon. No energy bar or icon is created yet.

---

## 6. Existing Codebase Context

### Autoloads (in load order per `project.godot`):
1. **`GameManager`** (`shared/autoloads/game_manager.gd`) — signals: `game_state_changed`, `core_hp_changed`, `player_hp_changed`, `player_died`, `player_respawned`, `night_survived`. Holds `current_state` enum, `dianthus_core` ref, `player` ref, `player_data` dict.
2. **`DayNightCycle`** (`core/day_night/day_night_cycle.gd`) — `day_count: int` (starts 1), `current_phase: Phase`, `phase_changed(phase: String)` signal.
3. **`SceneTransition`** (`core/transitions/scene_transition.gd`) — fade transition utility.
4. **`SaveManager`** (`save/scripts/save_manager.gd`) — JSON single-slot save. `_gather_state()` serializes world state. `_apply_state()` restores it. Schema version 1. Already has `state["difficulty"] = {"tier": "normal"}` stub.

### WaveSpawner (`enemies/spawner/wave_spawner.gd`):
- DIFF-01 scaling: `hp_growth_per_day = 0.10`, `spawn_growth_per_day = 1`, caps at `max_hp_multiplier = 3.0` / `max_spawn_count = 20`.
- `_spawn_enemy()` instantiates `enemy_scene`, applies HP scaling, then calls `_enemy_container.add_child(enemy)`.
- `start_wave()` computes `_current_hp_multiplier` and `_current_wave_total` from `DayNightCycle.day_count`.

### EnemyBase (`enemies/enemy_base.gd`):
- `@export var max_hp: int = 40`, `@export var damage: int = 8`, `@export var move_speed: float = 40.0`
- `var speed_modifier: float = 1.0` — used by Gloomshroom slow effect.
- `get_effective_speed() -> float` — returns `move_speed * speed_modifier`. All FSM states use this for movement.
- **Important:** Difficulty speed modifier should be applied to `move_speed` (the base), not `speed_modifier` (which is for runtime effects like Gloomshroom slow). This way both systems compose correctly: `get_effective_speed()` = `(base * difficulty) * slow_effect`.

### Settings Screen (`ui/menus/settings_screen.gd`):
- Already has `%DifficultyOption` (OptionButton, items: Easy=0, Normal=1, Hard=2, default selected=1).
- Already has `%ColorblindToggle` (CheckButton).
- `_on_difficulty_changed(_index)` and `_on_colorblind_toggled(_enabled)` are stubs with `pass` + TODO comments.
- Persists to `user://settings.cfg` via `ConfigFile`. Loads on `_ready()`.

### HUD (`ui/hud/hud.gd` + `hud.tscn`):
- `CanvasLayer` (layer 10) with `PlayerHPContainer` (top-left) and `CoreHPContainer` (top-center).
- Each has a `VBoxContainer` → Label + ProgressBar.
- `_shake()` method on damage. Connects to `GameManager.player_hp_changed` and `GameManager.core_hp_changed`.
- No energy bar yet (PLANT-07 scope).

### Main Menu (`ui/menus/main_menu.gd`):
- `_start_new_game()` resets `GameManager`, `DayNightCycle`, changes scene. Does not currently set difficulty.
- Settings screen is embedded as a child — `_load_settings()` fires on `_ready()`, so `DifficultyManager` will be initialized before any game starts.

---

## 7. Important Constraints

- **GDScript only**, Godot 4.6, **tabs** for indentation, full type hints on all vars and function signatures.
- **Do NOT mutate `@export` vars permanently** — difficulty modifiers are applied per-instance in `_spawn_enemy()`, same pattern as DIFF-01.
- **Difficulty modifies `move_speed`, NOT `speed_modifier`** — `speed_modifier` is reserved for runtime effects (Gloomshroom slow). Modifying `move_speed` on the instance before `add_child()` is safe because the enemy's FSM states call `get_effective_speed()` which reads `move_speed * speed_modifier`.
- **Round HP and damage to `int`** via `int(round(...))`. Speed remains `float`.
- **Apply difficulty AFTER DIFF-01 scaling, BEFORE `add_child()`** — ensures enemy `_ready()` sees final values.
- **Do NOT add new debug keys.** Existing F7 (skip phase) + F8 (force wave) are sufficient for testing. Difficulty is changed via Settings UI.
- **Do NOT touch FSM states, plant scripts, or DayNightCycle.** ACCESS-01 is a modifier layer applied in `wave_spawner.gd` + a new autoload.
- **Colorblind icons must use built-in font glyphs or plain text** (e.g., `"♥"`, `"[S]"`, `"⚡"`). Do NOT add external icon assets — the project uses pixel art and external PNGs would require separate asset pipeline work.
- **Match existing code style** — underscore-prefixed private vars, `push_warning()` for designer errors, `print("[ComponentName] ...")` for runtime logs.
- **Keep the diff small** — ACCESS-01 target ~60 net lines across all files. ACCESS-02 target ~30 net lines.
- **Schema version stays at 1** — the `difficulty` key already exists in the save schema (just with a stub value). We are filling it in, not adding a new key. No migration needed.

---

## 8. Verification Script (manual QA)

### ACCESS-01

1. Launch game from Main Menu.
2. Open Settings → confirm Difficulty dropdown shows "Easy", "Normal" (selected), "Hard".
3. Select "Easy", close Settings, start New Game.
4. Press **F7** to skip to Night. Watch console:
   ```
   [DifficultyManager] Tier changed to Easy
   [WaveSpawner] Wave started. Day: 1, Difficulty: Easy, Entry points: X, Enemies: 5, HP x1.00
   ```
5. Press **F5** to spawn a debug Shadowling at mouse — this one should have **base 40 HP** (debug spawn bypasses WaveSpawner scaling). Compare with a WaveSpawner-spawned enemy in the same wave which should have **32 HP** (40 × 0.80).
6. Press **F9** to clear the wave. Press **F7** twice to reach Night 2.
7. Console should show `Day: 2, Difficulty: Easy, Enemies: 6, HP x1.10`. A spawned enemy should have `round(40 * 1.10 * 0.80) = round(35.2) = 35 HP`.
8. Pause → Settings → change to Hard. Resume. Press **F7** twice to reach Night 3.
9. Console: `Day: 3, Difficulty: Hard, Enemies: 7, HP x1.20`. Enemy HP = `round(40 * 1.20 * 1.30) = round(62.4) = 62`.
10. Press **F11** (manual save). Quit to Main Menu. Press Continue.
11. After load, open Settings → Difficulty should show "Hard". Start a new night → enemies should still have Hard scaling.

### ACCESS-02

1. Launch game, open Settings → confirm Colorblind Mode is OFF.
2. Start game → HUD shows Player HP (red bar, top-left) and Core HP (green bar, top-center). **No icons visible.**
3. Pause → Settings → toggle Colorblind Mode ON → close Settings → resume.
4. **Heart icon (♥)** is now visible next to or below the Player HP bar. **Shield icon** is visible next to the Core HP bar.
5. Pause → Settings → toggle Colorblind Mode OFF → icons disappear immediately.
6. Toggle back ON, quit to Main Menu, relaunch → Colorblind Mode should still be ON (persisted), icons visible on next game start.

---

## 9. Edge Cases & Design Decisions

### Difficulty × Gloomshroom slow interaction
- Gloomshroom sets `speed_modifier = 0.6` on enemies in its radius.
- Difficulty modifies `move_speed` directly on spawn.
- Result: A Hard-mode Shadowling has `move_speed = 40.0 * 1.30 = 52.0`. When slowed by Gloomshroom: `get_effective_speed() = 52.0 * 0.6 = 31.2`. This is correct — harder enemies are still slowed by the same percentage, but their slowed speed is higher than a Normal enemy's slowed speed.

### Difficulty change during active night
- If the player changes difficulty mid-wave, **already-spawned enemies are NOT retroactively modified**. Only enemies spawned after the change use the new multipliers. This is acceptable for simplicity and matches the "applied at spawn" pattern.

### Difficulty in Endless mode (future)
- The `DifficultyManager` multipliers will stack with DIFF-01 and future exponential scaling (DIFF-02/END-04). No special handling needed now.

### Colorblind icons with future Energy bar
- When PLANT-07 adds the Energy bar, it should also add an `EnergyIcon` Label (⚡) and connect it to `GameManager.colorblind_mode_changed`. A TODO comment marks this.

---

## 10. Out of Scope (future tasks — do NOT implement)

- **Damage scaling on the DIFF-01 per-day curve** — DIFF-01 only scales HP and count per day. ACCESS-01 adds a difficulty-tier damage modifier, but per-day damage growth is deferred.
- **Difficulty selection screen before New Game** — A dedicated "Choose Difficulty" popup before starting could be nice UX, but is not in the GDD. The Settings screen approach is sufficient. Could be added as UI polish later.
- **Per-difficulty resource/reward scaling** — GDD §11.4 only specifies enemy stat changes. Resource drops and night rewards are not affected by difficulty.
- **Colorblind palette swaps** — GDD §11.4 specifies "supplemental icons", not recoloring. Full palette swaps are a larger scope accessibility feature.
- **Colorblind mode for plant effect radius colors** — Out of scope for ACCESS-02. Could be a future sub-task.
- **Tutorial difficulty hints** — ACCESS-03 (tutorial) may reference difficulty, but that is its own task.
- **Text speed implementation** — ACCESS-04, separate task. The `_on_text_speed_changed` stub remains as-is.
