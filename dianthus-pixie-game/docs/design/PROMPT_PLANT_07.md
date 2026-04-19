# PROMPT — PLANT-07: Full Energy System

**Task ID:** PLANT-07 | **Priority:** Critical | **Effort:** M  
**Deps:** CORE-08 ✅ | **GDD:** §5.1, §9.1, §11.1, §13.3

---

## 1. Context

Replace four existing TODO stubs with a real energy system:
- `player_controller.gd:214` — death penalty stub
- `player_controller.gd:324` — +3 energy per hit stub
- `enemy_base.gd:52` — +10 energy on kill stub
- `hud.gd:11` — energy bar HUD stub

## 2. Spec (GDD §13.3)

**Capacity:** base 100. `const BASE_MAX_ENERGY = 100`, `var max_energy = BASE_MAX_ENERGY`.  
Future: +10 max per 3 Melati (PLANT-02 — stub comment only).

**Gain sources:**
| Source | Amount | Location |
|--------|--------|----------|
| Hit enemy | +3/hit | `_on_sword_hitbox_body_entered()` in player_controller.gd |
| Kill enemy | +10/kill | `die()` in enemy_base.gd |
| Near Core | +2/sec passive | `_physics_process()` in player_controller.gd, dist check |

**Spend:** `try_spend_energy(amount) -> bool` API. Plant skill 20-50, character skill 30. Neither exists yet — leave `# TODO (PLANT-08)`.

**Death penalty (§5.1):** On respawn lose 25% of *current* energy (floor). `ENERGY_DEATH_PENALTY = 0.25` constant already exists.

**HUD (§11.1):** Blue/teal bar below Player HP. Smooth tween fill (0.15s). Colorblind icon `[E]`.

## 3. Architecture

Energy lives on player node (like HP). Signal `energy_changed(current, max)` forwarded through GameManager as `player_energy_changed` so HUD listens to GameManager.

## 4. Changes Per File

### 4.1 player/scripts/player_controller.gd — MODIFY

**Add signal** (with existing signals):
```gdscript
signal energy_changed(current_energy: int, max_energy: int)
```

**Add constants** (after ENERGY_DEATH_PENALTY):
```gdscript
const BASE_MAX_ENERGY: int = 100
const ENERGY_PER_HIT: int = 3
const ENERGY_PER_KILL: int = 10
const ENERGY_NEAR_CORE_RATE: float = 2.0
const CORE_PROXIMITY_RADIUS: float = 64.0
```

**Add vars** (after _debug_plant_cycle):
```gdscript
var current_energy: int = 0
var max_energy: int = BASE_MAX_ENERGY
var _energy_regen_accumulator: float = 0.0
```

**In `_ready()`** — after `hp_changed.emit(...)`:
```gdscript
energy_changed.emit(current_energy, max_energy)
```

**In `_physics_process(delta)`** — after movement/move_and_slide, before return, call:
```gdscript
_update_core_energy_regen(delta)
```

**New private method:**
```gdscript
func _update_core_energy_regen(delta: float) -> void:
    if is_dead:
        return
    if not is_instance_valid(GameManager.dianthus_core):
        return
    var dist: float = global_position.distance_to(
        GameManager.dianthus_core.global_position)
    if dist > CORE_PROXIMITY_RADIUS:
        _energy_regen_accumulator = 0.0
        return
    _energy_regen_accumulator += ENERGY_NEAR_CORE_RATE * delta
    if _energy_regen_accumulator >= 1.0:
        var amount: int = int(_energy_regen_accumulator)
        _energy_regen_accumulator -= float(amount)
        add_energy(amount)
```

**New public methods:**
```gdscript
func add_energy(amount: int) -> void:
    if is_dead:
        return
    current_energy = min(current_energy + amount, max_energy)
    energy_changed.emit(current_energy, max_energy)

func try_spend_energy(amount: int) -> bool:
    if current_energy < amount:
        return false
    current_energy -= amount
    energy_changed.emit(current_energy, max_energy)
    return true
    # TODO (PLANT-08): Hook into active skill input.
```

**Replace TODO at line ~324** (`_on_sword_hitbox_body_entered`):
```gdscript
# was: # TODO (PLANT-07): Add +3 energy per hit here.
add_energy(ENERGY_PER_HIT)
```

**Replace TODO at line ~214** (`_respawn`):
```gdscript
# was: # TODO (PLANT-07): Apply -25% stored energy penalty here.
var energy_penalty: int = int(current_energy * ENERGY_DEATH_PENALTY)
current_energy = max(current_energy - energy_penalty, 0)
energy_changed.emit(current_energy, max_energy)
```

**Debug keys** — modify F3/F4 blocks to handle Shift variants:
```gdscript
if event.keycode == KEY_F3:
    if event.shift_pressed:
        current_energy = 50
        energy_changed.emit(current_energy, max_energy)
        print("DEBUG: Energy set to 50/%d" % max_energy)
    else:
        take_damage(25)
        print("DEBUG: Player took 25 damage. HP: %d/%d" % [current_hp, MAX_HP])
elif event.keycode == KEY_F4:
    if event.shift_pressed:
        current_energy = max_energy
        energy_changed.emit(current_energy, max_energy)
        print("DEBUG: Energy filled to %d/%d" % [current_energy, max_energy])
    else:
        heal(25)
        print("DEBUG: Player healed 25. HP: %d/%d" % [current_hp, MAX_HP])
```

### 4.2 enemies/enemy_base.gd — MODIFY

In `die()`, replace `# TODO (PLANT-07)` comment with:
```gdscript
if is_instance_valid(GameManager.player) and GameManager.player.has_method("add_energy"):
    GameManager.player.add_energy(10)
```

### 4.3 shared/autoloads/game_manager.gd — MODIFY

**Add signal** (after `player_respawned`):
```gdscript
signal player_energy_changed(current_energy: int, max_energy: int)
```

**In `register_player()`**, add after existing signal connections:
```gdscript
if p.has_signal("energy_changed"):
    p.energy_changed.connect(
        func(e: int, m: int) -> void: player_energy_changed.emit(e, m))
```

### 4.4 ui/hud/hud.tscn — MODIFY

**Bump `load_steps` from 6 to 8.**

**Add 2 new sub_resources** (after StyleBoxFlat_core_fill):
```
[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_energy_bg"]
bg_color = Color(0.1, 0.1, 0.1, 0.8)
corner_radius_top_left = 2
corner_radius_top_right = 2
corner_radius_bottom_right = 2
corner_radius_bottom_left = 2

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_energy_fill"]
bg_color = Color(0.2, 0.7, 0.9, 1)
corner_radius_top_left = 2
corner_radius_top_right = 2
corner_radius_bottom_right = 2
corner_radius_bottom_left = 2
```

**Add 3 new nodes** after PlayerHPIcon (children of PlayerHPContainer/VBoxContainer):
```
[node name="EnergyLabel" type="Label" parent="PlayerHPContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
text = "ENERGY"
theme_override_font_sizes/font_size = 6

[node name="EnergyBar" type="ProgressBar" parent="PlayerHPContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
custom_minimum_size = Vector2(120, 10)
max_value = 100.0
value = 0.0
show_percentage = false
theme_override_styles/background = SubResource("StyleBoxFlat_energy_bg")
theme_override_styles/fill = SubResource("StyleBoxFlat_energy_fill")

[node name="EnergyIcon" type="Label" parent="PlayerHPContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
text = "[E]"
theme_override_font_sizes/font_size = 8
theme_override_colors/font_color = Color(0.2, 0.7, 0.9, 1)
visible = false
```

**Update PlayerHPContainer offset_bottom** from `30.0` to `64.0`.

### 4.5 ui/hud/hud.gd — MODIFY

**Add @onready refs** (replace the TODO comment line):
```gdscript
@onready var _energy_bar: ProgressBar = %EnergyBar
@onready var _energy_label: Label = %EnergyLabel
@onready var _energy_icon: Label = %EnergyIcon
```

**In `_ready()`**, add:
```gdscript
GameManager.player_energy_changed.connect(_on_player_energy_changed)
```

**Add handler:**
```gdscript
func _on_player_energy_changed(current_energy: int, max_energy: int) -> void:
    _energy_bar.max_value = max_energy
    var tween: Tween = create_tween()
    tween.tween_property(_energy_bar, "value", float(current_energy), 0.15)
    _energy_label.text = "ENERGY  %d / %d" % [current_energy, max_energy]
```

**In `_on_colorblind_changed()`**, add:
```gdscript
_energy_icon.visible = enabled
```

### 4.6 save/scripts/save_manager.gd — MODIFY

**Bump `SCHEMA_VERSION` to 4.**

**In `_gather_state()`** — after the `state["player"]` dict is built and before `state["player"]["equipped_weapon"]`:
```gdscript
var player_energy: int = 0
var player_max_energy: int = 100
if is_instance_valid(GameManager.player):
    player_energy = GameManager.player.current_energy
    player_max_energy = GameManager.player.max_energy
state["player"]["current_energy"] = player_energy
state["player"]["max_energy"] = player_max_energy
```

**In `_apply_state()`** — after player HP restore (step 4), add:
```gdscript
GameManager.player.max_energy = int(pd.get("max_energy", 100))
GameManager.player.current_energy = int(pd.get("current_energy", 0))
GameManager.player.energy_changed.emit(
    GameManager.player.current_energy,
    GameManager.player.max_energy
)
```
(Inside the existing `if is_instance_valid(GameManager.player):` block.)

**In `_migrate()`** — add v3→v4 block:
```gdscript
if version < 4:
    print("[SaveManager] Migrating save from v%d to v4." % version)
    var pd: Dictionary = data.get("player", {})
    if not pd.has("current_energy"):
        pd["current_energy"] = 0
    if not pd.has("max_energy"):
        pd["max_energy"] = 100
    data["player"] = pd
    data["schema_version"] = 4
```

### 4.7 docs/design/PERSON_TASKS.md — MODIFY

Update Nice-to-Have energy row to ✅. Add debug keys Shift+F3 / Shift+F4.

## 5. Acceptance Criteria

1. Hit enemy → energy +3, visible in HUD bar.
2. Kill enemy → energy +10.
3. Stand near Core (<64px) → energy +2/sec, accumulates correctly.
4. Energy capped at max_energy (100), never goes negative.
5. Death → respawn → energy reduced by 25% (floor).
6. HUD bar: blue/teal, smooth tween fill, label shows "ENERGY X / Y".
7. Colorblind mode → [E] icon appears next to energy bar.
8. Save/Load round-trips energy and max_energy correctly.
9. Old v3 saves migrate cleanly to v4 (energy defaults to 0/100).
10. `try_spend_energy(30)` returns true if >= 30, deducts, emits signal; false otherwise.

## 6. NOT in scope (confirmed no-touch)

- Active skill input / activation (PLANT-08)
- Melati max energy upgrade (PLANT-02)
- Kecombrang/Kunyit plant effects (PLANT-05)
- Loadout system (PLANT-08)
- Any enemy FSM changes
- Any DayNightCycle changes
- Any CraftingManager/InventoryManager changes

## 7. New files: None

All changes are modifications to existing files.

## 8. Testing Checklist

```
1. Launch game. Energy bar shows "ENERGY  0 / 100" below HP bar.
2. F5 to spawn Shadowling. Attack it — energy goes up by 3 per hit.
3. Kill it — energy jumps by +10 on death.
4. Walk to Core (< 64px). Wait 5s. Energy should gain ~10.
5. Shift+F3 — energy set to 50. Shift+F4 — energy filled to 100.
6. F3 (no shift) — take 25 damage (HP). Die. Respawn. Energy = 75% of pre-death value.
7. Toggle colorblind in settings — [E] icon appears/disappears.
8. F11 to save. F12 to load. Energy value persists.
9. Delete save (Shift+F11). F12 load — fails gracefully.
10. Energy never exceeds 100 or goes below 0.
```
