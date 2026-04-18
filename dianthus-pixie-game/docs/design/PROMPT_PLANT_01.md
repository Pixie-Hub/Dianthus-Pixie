# PLANT-01 — Thornvine & Gloomshroom Plant Effects — Implementation Prompt

**Project:** Dianthus Pixie
**Engine:** Godot 4.6 (GDScript)
**Effort:** M (0.5–1 day)
**Priority:** High
**Dependencies:** CORE-06 (Shadowling FSM — Done), CORE-07 (Wave Spawner — Done)
**Downstream dependents:** Plant Placement (Person B, Week 2), DIFF-02 (Difficulty Scaling)

---

## 1. Objective

Implement two defensive garden plants — **Thornvine** and **Gloomshroom** — as placeable `StaticBody2D` entities with `Area2D` effect zones. These are the first two plants in the game that interact with enemies during the night defense phase. This task must produce:

1. A **PlantBase** class (`plants/entities/plant_base.gd`) — shared base for all garden plants (HP, destruction, signals).
2. **Thornvine** entity (`plants/entities/thornvine.gd` + `.tscn`) — damages enemies passing through its area.
3. **Gloomshroom** entity (`plants/entities/gloomshroom.gd` + `.tscn`) — slows enemies within its radius.
4. A small addition to **`EnemyBase`** to support speed modifiers (for Gloomshroom slow).
5. **Debug key F10** — cycle-place plants at mouse cursor for testing (Thornvine → Gloomshroom → remove).

---

## 2. Plant Stats (GDD §7.1 + PERSON_TASKS.md)

### Thornvine (Offensive)

| Stat | Value |
|------|-------|
| HP | 30 |
| Damage per tick | 5 |
| Tick interval | 1.0 s (= 5 DMG/sec) |
| Effect radius | 24 px (1.5 tiles) |
| Placeholder color | Dark green `Color(0.2, 0.5, 0.1)` |

### Gloomshroom (Defensive)

| Stat | Value |
|------|-------|
| HP | 40 |
| Slow multiplier | 0.6 (= 40% speed reduction) |
| Effect radius | 40 px (2.5 tiles) |
| Placeholder color | Purple-brown `Color(0.5, 0.25, 0.5)` |

---

## 3. Architecture

### 3a. PlantBase (`plants/entities/plant_base.gd`)

`extends StaticBody2D`, `class_name PlantBase`

**Responsibilities:**
- Exports: `max_hp: int`, `effect_radius: float`.
- Variables: `current_hp: int`, `is_destroyed: bool`.
- Signals: `plant_destroyed(plant: PlantBase)`, `hp_changed(current_hp: int, max_hp: int)`.
- `take_damage(amount: int)` — Reduce HP, flash sprite, emit `hp_changed`. If HP ≤ 0, call `destroy()`.
- `destroy()` — Set `is_destroyed = true`, emit `plant_destroyed`, play wither animation (fade out over 0.5 s), then `queue_free()`.
- On `_ready()`: add self to group `"plants"`, set `current_hp = max_hp`.
- Collision setup: `collision_layer = CollisionLayers.INTERACTABLE` (1), `collision_mask = 0` (plants don't move).

**Scene tree structure (all plants follow this pattern):**
```
PlantNode (StaticBody2D) [thornvine.gd or gloomshroom.gd]
├── Sprite2D (%Sprite2D)
├── CollisionShape2D (RectangleShape2D, 16×16 px — one tile)
└── EffectArea (Area2D)
    └── CollisionShape2D (CircleShape2D, radius = effect_radius)
```

**EffectArea collision setup:**
- `collision_layer = 0` (the area itself is not on any layer)
- `collision_mask = CollisionLayers.ENEMY` (8) — detects enemies entering/exiting
- `monitoring = true`, `monitorable = false`

### 3b. Thornvine (`plants/entities/thornvine.gd`)

`extends PlantBase`, `class_name Thornvine`

**Behaviour:**
- Tracks enemies inside `EffectArea` using `body_entered` / `body_exited` signals → maintain an `Array[EnemyBase]` of enemies in range.
- Every `tick_interval` (1.0 s), iterate over all enemies in range and call `enemy.take_damage(damage_per_tick)`.
- Use a `Timer` node or manual `_process` accumulator for the tick. Prefer manual accumulator (no extra node).
- Clean up references: remove enemies from the array when they die or exit.

**Exports:**
- `damage_per_tick: int = 5`
- `tick_interval: float = 1.0`

**Key logic (pseudocode):**
```gdscript
var _enemies_in_range: Array[EnemyBase] = []
var _tick_timer: float = 0.0

func _process(delta: float) -> void:
    if _enemies_in_range.is_empty():
        return
    _tick_timer += delta
    if _tick_timer >= tick_interval:
        _tick_timer -= tick_interval
        for enemy in _enemies_in_range.duplicate():
            if is_instance_valid(enemy) and not enemy.is_dead:
                enemy.take_damage(damage_per_tick)
```

### 3c. Gloomshroom (`plants/entities/gloomshroom.gd`)

`extends PlantBase`, `class_name Gloomshroom`

**Behaviour:**
- Tracks enemies inside `EffectArea` using `body_entered` / `body_exited` signals.
- On `body_entered`: apply slow → set `enemy.speed_modifier = min(enemy.speed_modifier, slow_multiplier)` (stacking rule: strongest slow wins, i.e. lowest multiplier).
- On `body_exited` or enemy death: remove slow → recalculate `enemy.speed_modifier` by checking if any other Gloomshroom still covers them. If none, reset to `1.0`.
- Clean up on `destroy()`: remove slow from all enemies currently in range.

**Exports:**
- `slow_multiplier: float = 0.6`

**Key logic (pseudocode):**
```gdscript
var _enemies_in_range: Array[EnemyBase] = []

func _on_effect_area_body_entered(body: Node2D) -> void:
    if body is EnemyBase and not body.is_dead:
        _enemies_in_range.append(body)
        _apply_slow(body)

func _on_effect_area_body_exited(body: Node2D) -> void:
    if body is EnemyBase:
        _enemies_in_range.erase(body)
        _recalculate_slow(body)

func _apply_slow(enemy: EnemyBase) -> void:
    enemy.speed_modifier = min(enemy.speed_modifier, slow_multiplier)

func _recalculate_slow(enemy: EnemyBase) -> void:
    # Check all active Gloomshrooms to see if any still cover this enemy
    var strongest: float = 1.0
    for plant in get_tree().get_nodes_in_group("gloomshrooms"):
        if plant is Gloomshroom and not plant.is_destroyed:
            if plant._enemies_in_range.has(enemy):
                strongest = min(strongest, plant.slow_multiplier)
    enemy.speed_modifier = strongest
```

### 3d. EnemyBase Modification (`enemies/enemy_base.gd`)

Add a **`speed_modifier`** property to `EnemyBase` so that Gloomshroom (and future plants) can affect enemy movement speed without overriding `move_speed` directly.

**Changes (minimal):**
```gdscript
# Add this variable near `is_dead`:
var speed_modifier: float = 1.0

# Add this helper method:
func get_effective_speed() -> float:
    return move_speed * speed_modifier
```

**Impact on existing FSM states:** The Shadowling states (`shadowling_scout.gd`, `shadowling_siege.gd`, `shadowling_attack.gd`, `shadowling_retreat.gd`) currently use `enemy.move_speed` directly in their movement calculations. Update these to use `enemy.get_effective_speed()` instead. This is a find-and-replace of `enemy.move_speed` → `enemy.get_effective_speed()` in the velocity/movement lines of each state script. **Do not change anything else in the FSM states.**

---

## 4. File Structure to Create

```
plants/
└── entities/
    ├── plant_base.gd            # Base class for all garden plants
    ├── plant_base.gd.uid
    ├── thornvine.gd             # Thornvine: damage-over-time area
    ├── thornvine.gd.uid
    ├── thornvine.tscn           # Thornvine scene
    ├── gloomshroom.gd           # Gloomshroom: slow aura
    ├── gloomshroom.gd.uid
    └── gloomshroom.tscn         # Gloomshroom scene
```

**Modified files:**
- `enemies/enemy_base.gd` — add `speed_modifier` var + `get_effective_speed()` method.
- `enemies/shadowling/states/shadowling_scout.gd` — replace `enemy.move_speed` with `enemy.get_effective_speed()`.
- `enemies/shadowling/states/shadowling_attack.gd` — same replacement.
- `enemies/shadowling/states/shadowling_retreat.gd` — same replacement.
- `player/scripts/player_controller.gd` — add F10 debug key.

---

## 5. Placeholder Visuals

No plant sprite art exists yet. Use placeholders:

- **Thornvine:** `Sprite2D` using `res://icon.svg` scaled down (`scale = Vector2(0.15, 0.15)`), tinted dark green (`modulate = Color(0.2, 0.5, 0.1)`).
- **Gloomshroom:** `Sprite2D` using `res://icon.svg` scaled down (`scale = Vector2(0.15, 0.15)`), tinted purple-brown (`modulate = Color(0.5, 0.25, 0.5)`).

For the **EffectArea** visual feedback:
- Add a second `Sprite2D` (child of the plant root, behind the main sprite) as a semi-transparent circle to visualize the effect radius. Use a simple approach: a `ColorRect` or another `icon.svg` scaled to match the radius, with low alpha (`modulate.a = 0.15`). This is optional but helpful for debugging.

**Wither animation** (on destroy): tween `modulate.a` → 0 over 0.5 s, then `queue_free()`. Same pattern as `EnemyBase._play_death_animation()`.

---

## 6. Debug / Testing Integration

Add a debug key for testing plant placement (consistent with existing debug keys F1–F9):

- **F10** — Cycle-place at mouse cursor: first press places Thornvine, second press places Gloomshroom, third press removes all debug-placed plants. Print to console which action was taken.

Add this to `player_controller.gd` in `_unhandled_input()` alongside the existing debug keys.

**Implementation:**
```gdscript
# In player_controller.gd, add:
var _debug_plant_cycle: int = 0  # 0=thornvine, 1=gloomshroom, 2=clear

func _debug_place_plant() -> void:
    var mouse_pos: Vector2 = get_global_mouse_position()
    match _debug_plant_cycle:
        0:
            var scene: PackedScene = preload("res://plants/entities/thornvine.tscn")
            var plant: Node2D = scene.instantiate()
            plant.global_position = mouse_pos
            get_tree().current_scene.add_child(plant)
            print("[Debug] Placed Thornvine at %s" % mouse_pos)
        1:
            var scene: PackedScene = preload("res://plants/entities/gloomshroom.tscn")
            var plant: Node2D = scene.instantiate()
            plant.global_position = mouse_pos
            get_tree().current_scene.add_child(plant)
            print("[Debug] Placed Gloomshroom at %s" % mouse_pos)
        2:
            for plant in get_tree().get_nodes_in_group("plants"):
                plant.queue_free()
            print("[Debug] Cleared all plants")
    _debug_plant_cycle = (_debug_plant_cycle + 1) % 3
```

---

## 7. Existing Codebase Context

You must integrate with these existing systems. **Do NOT modify them unless explicitly stated.**

### Autoloads (already registered in `project.godot`):
- **`GameManager`** (`shared/autoloads/game_manager.gd`) — Access `GameManager.dianthus_core`, `GameManager.player`.
- **`DayNightCycle`** (`core/day_night/day_night_cycle.gd`) — Access `DayNightCycle.is_night()`, `DayNightCycle.current_phase`, signal `phase_changed(phase: String)`.

### Collision Layers (from `shared/collision_layers.gd`):
- `INTERACTABLE = 1` (layer 1)
- `TERRAIN = 2` (layer 2)
- `PLAYER = 4` (layer 3)
- `ENEMY = 8` (layer 4)
- `PROJECTILE = 16` (layer 5)

### EnemyBase (`enemies/enemy_base.gd`):
- `extends CharacterBody2D`, `class_name EnemyBase`
- Has `take_damage(amount: int)`, `is_dead: bool`, `move_speed: float`, `die()`.
- Collision layer = `ENEMY` (8). All enemies are in group `"enemies"`.
- Death plays fade-out tween → `queue_free()`.

### Shadowling FSM states:
- States use `enemy.move_speed` for velocity calculations.
- States reference `enemy` (set by `StateMachine`) as the parent `EnemyBase`.

### WaveSpawner (`enemies/spawner/wave_spawner.gd`):
- Spawns enemies into `EnemyContainer` node.
- Enemies are tracked by `enemy_died` signal and `tree_exiting` signal.
- Plants do NOT interact with the WaveSpawner — they independently damage/slow enemies.

---

## 8. Acceptance Criteria

1. **Thornvine damages enemies:** Enemies inside Thornvine's EffectArea take 5 damage every 1.0 s. Verified by placing a Thornvine (F10), spawning a Shadowling (F5), and observing HP decrease.
2. **Gloomshroom slows enemies:** Enemies inside Gloomshroom's EffectArea move at 60% speed. Verified by placing a Gloomshroom (F10×2), spawning a Shadowling (F5), and observing visibly slower movement.
3. **Slow removal works:** When an enemy exits a Gloomshroom's area, its speed returns to normal (or to the next strongest slow if overlapping another Gloomshroom).
4. **Plants have HP and can be destroyed:** Calling `plant.take_damage(amount)` reduces HP. At 0 HP the plant fades out and is freed. (Enemy attack on plants is a future task — for now, test with a debug call or extending enemy Siege state is NOT required.)
5. **No double-damage or double-slow:** Thornvine only damages enemies currently in range. Gloomshroom correctly recalculates slow on exit. Dead enemies are cleaned from tracking arrays.
6. **PlantBase is reusable:** Future plants (Sunpetal, Nightbloom, etc.) can extend `PlantBase` and add their own EffectArea logic.
7. **EnemyBase speed_modifier works:** `get_effective_speed()` returns `move_speed * speed_modifier`. All Shadowling movement states use `get_effective_speed()`. Default `speed_modifier = 1.0` means no change to existing behaviour.
8. **Debug key F10 works:** Cycles through Thornvine → Gloomshroom → clear all plants.
9. **No regressions:** Player, Core, Day/Night cycle, HUD, Wave Spawner, and Shadowling FSM all remain functional. Existing debug keys F1–F9 unaffected.
10. **Groups:** Thornvine is in groups `"plants"` and `"thornvines"`. Gloomshroom is in groups `"plants"` and `"gloomshrooms"`.

---

## 9. Important Constraints

- **GDScript only** — no C#, no GDExtension.
- **Do NOT use `@onready` for nodes that might not exist** — use `%UniqueNameInOwner` syntax where possible, and null-check otherwise.
- **Plants are StaticBody2D** — they don't move. Use `Area2D` children for effect detection.
- **Minimal EnemyBase changes** — only add `speed_modifier: float = 1.0` and `get_effective_speed()`. Do not refactor existing enemy logic.
- **Signals over direct references** — use groups and signals for communication where possible.
- **Match existing code style** — tabs for indentation, type hints on all parameters and return types, `_` prefix for private methods/vars. Follow patterns in `enemy_base.gd` and `player_controller.gd`.
- **UID files** — Godot 4.6 generates `.gd.uid` files automatically. Do not manually create them; they will be created when Godot opens the project.
- **Scene files (.tscn)** — Create these programmatically in the prompt or let the implementer build them in the Godot editor. If creating via code, follow the format of `shadowling.tscn` as reference.
