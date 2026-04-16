# CORE-08 & CORE-10 — Player Death & Respawn + Basic HUD

## Context

| Key | Value |
|-----|-------|
| **Project** | Dianthus Pixie — 2D survival crafting action game |
| **Engine** | Godot 4.6 (Forward Plus) |
| **Viewport** | 640×360, stretch mode `canvas_items`, integer scale |
| **Art** | 2D Pixel Art — 16×16 tiles, 64×64 character sprite frames |
| **Repo root** | `c:\Users\Indra\Programming\GIGA\Dianthus Pixie\dianthus-pixie-game` |

---

## Current State — What Already Exists

> **Do NOT recreate these from scratch.** Only modify or extend as needed.

### 1. `GameManager` — `shared/autoloads/game_manager.gd`

- Autoload singleton.
- `GameState` enum: `EXPLORATION`, `PREPARATION`, `DEFENSE`, `GAME_OVER`, `TRANSITIONING`.
- `set_state()` method and `game_state_changed` signal.
- `player_data` dictionary with `position`, `last_zone`, `inventory` keys.
- `core_hp_changed`, `core_destroyed`, `game_over_triggered` signals.
- `dianthus_core: Node` reference, `register_core()` method.

Full source:

```gdscript
extends Node

signal game_state_changed(new_state: String)
signal core_hp_changed(current_hp: int, max_hp: int)
signal core_destroyed
signal game_over_triggered

enum GameState {
    EXPLORATION,
    PREPARATION,
    DEFENSE,
    GAME_OVER,
    TRANSITIONING,
}

var current_state: GameState = GameState.EXPLORATION
var dianthus_core: Node = null

var player_data: Dictionary = {
    "position": Vector2.ZERO,
    "last_zone": "",
    "inventory": {},
}

func set_state(new_state: GameState) -> void:
    if current_state == new_state:
        return
    current_state = new_state
    game_state_changed.emit(GameState.keys()[new_state])

func register_core(core: Node) -> void:
    dianthus_core = core
    if core.has_signal("hp_changed"):
        core.hp_changed.connect(func(hp: int, max_hp: int) -> void: core_hp_changed.emit(hp, max_hp))
    if core.has_signal("core_destroyed"):
        core.core_destroyed.connect(_on_core_destroyed)

func _on_core_destroyed() -> void:
    set_state(GameState.GAME_OVER)
    game_over_triggered.emit()
```

### 2. `DayNightCycle` — `core/day_night/day_night_cycle.gd`

- Autoload singleton.
- `Phase` enum: `MORNING`, `AFTERNOON`, `NIGHT`.
- Phase durations: 120 s / 60 s / 90 s.
- `phase_changed` signal, `day_count`, tint system via `register_canvas_modulate()`.
- Utility: `get_phase_name()`, `get_time_remaining()`, `get_phase_progress()`, `is_night()`.

### 3. `SceneTransition` — `core/transitions/scene_transition.gd`

- Autoload `CanvasLayer` (layer 128) with fade-in/fade-out overlay.
- `transition_to(target_scene)` blocked during `DEFENSE` state.

### 4. Player Scene — `player/scenes/player.tscn`

Node tree:
```
Player (CharacterBody2D) — collision_layer = 4 (PLAYER), collision_mask = 2 (TERRAIN)
├── AnimatedSprite2D (unique_name_in_owner) — SpriteFrames with 8 animations (idle/walk × 4 directions), 64×64 frames
├── CollisionShape2D — CapsuleShape2D (radius 5, height 22)
└── Camera2D (unique_name_in_owner) — zoom Vector2(1.5, 1.5), uses smooth_camera.gd
```

### 5. Player Controller — `player/scripts/player_controller.gd`

Full source:

```gdscript
extends CharacterBody2D

const TILE_SIZE: int = 16
const SPEED: float = TILE_SIZE * 5.0

@onready var _sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var _camera: Camera2D = %Camera2D

var last_direction: Vector2 = Vector2.DOWN

func _physics_process(_delta: float) -> void:
    var dir: Vector2 = Vector2(
        Input.get_axis("move_left", "move_right"),
        Input.get_axis("move_up", "move_down")
    )
    if dir != Vector2.ZERO:
        dir = dir.normalized()
        last_direction = _dominant_direction(dir)
        velocity = dir * SPEED
        _play_animation("walk")
    else:
        velocity = Vector2.ZERO
        _play_animation("idle")
    move_and_slide()

func _dominant_direction(dir: Vector2) -> Vector2:
    if abs(dir.x) >= abs(dir.y):
        return Vector2.RIGHT if dir.x > 0.0 else Vector2.LEFT
    return Vector2.DOWN if dir.y > 0.0 else Vector2.UP

func _play_animation(prefix: String) -> void:
    var suffix: String
    if last_direction == Vector2.UP:
        suffix = "_up"
    elif last_direction == Vector2.DOWN:
        suffix = "_down"
    elif last_direction == Vector2.LEFT:
        suffix = "_left"
    else:
        suffix = "_right"
    var anim: String = prefix + suffix
    if _sprite.animation != anim:
        _sprite.play(anim)

func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
    _camera.limit_left = left
    _camera.limit_top = top
    _camera.limit_right = right
    _camera.limit_bottom = bottom
```

**Key notes:**
- The player has **no HP system** yet. No `current_hp`, `max_hp`, `take_damage()`, `is_dead` flag, or death/respawn logic.
- The player is in the `"player"` group (accessed via `get_tree().get_first_node_in_group("player")` in `scene_transition.gd`).
- No energy system exists yet (that is PLANT-07, a future task).

### 6. Dianthus Core — `core/dianthus_core/dianthus_core.gd`

- `StaticBody2D` at position `Vector2(320, 240)` in `meadow_edge.tscn`.
- `MAX_HP = 200`, `current_hp`, `take_damage()`, `heal()`, `_update_aura()`.
- Signals: `hp_changed`, `core_destroyed`, `core_damaged`.
- Registered with `GameManager` via `register_core()` in `meadow_edge.gd`.
- Debug keys: F1 = damage Core 20, F2 = heal Core 20.

### 7. Core HP Bar (HUD) — `ui/hud/core_hp_bar.tscn`

- `CanvasLayer` (layer 10) with `ProgressBar` (green fill, max 200) and `Label`.
- Script `core_hp_bar.gd` listens to `GameManager.core_hp_changed`.
- Positioned top-center of the screen (anchor 0.5, offset ±80 px).
- **No damage shake** implemented yet.

### 8. Game Over Screen — `ui/screens/game_over_screen.tscn`

- `CanvasLayer` (layer 100), starts hidden.
- Shows "GAME OVER", days survived label, Restart and Main Menu buttons.
- Pauses tree on game over; Restart reloads scene with reset day/phase/state.

### 9. Meadow Edge Zone — `world/zones/meadow_edge/meadow_edge.tscn`

Node tree:
```
MeadowEdge (Node2D) — script: meadow_edge.gd
├── CanvasModulate
├── TileMapLayer — 16×16 tiles, physics layer 2 (TERRAIN)
├── Player (instance of player.tscn) — position (160, 120)
├── DebugOverlay (CanvasLayer, layer 10)
│   ├── PhaseLabel
│   ├── DayLabel
│   └── TimerLabel
├── DianthusCore (instance of dianthus_core.tscn) — position (320, 240)
├── CoreHPBar (instance of core_hp_bar.tscn)
└── GameOverScreen (instance of game_over_screen.tscn)
```

`meadow_edge.gd` constants: `ZONE_WIDTH = 40`, `ZONE_HEIGHT = 30`, `TILE_SIZE = 16`.

### 10. Collision Layers — `shared/collision_layers.gd`

```
INTERACTABLE = 1, TERRAIN = 2, PLAYER = 4, ENEMY = 8, PROJECTILE = 16
```

### 11. Empty Folders Awaiting Content

- `ui/components/` — empty.
- `ui/menus/` — empty.
- `combat/` — empty.

---

## Tasks To Complete

Work in dependency order: CORE-08 first, then CORE-10.

---

### CORE-08 — Player Death & Respawn

> **GDD refs:** §5.1 (Player respawns near Core after 5 s; -25% stored energy on respawn; 3 s invincibility window; equipped items retained), §9.1 (player stats), §13.3 (energy system).

#### A. Add HP System to Player Controller — `player/scripts/player_controller.gd`

Add the following to the **existing** script (do not rewrite the movement logic):

**New signals:**

```gdscript
signal hp_changed(current_hp: int, max_hp: int)
signal player_died
signal player_respawned
```

**New constants & variables:**

| Name | Type | Value | Note |
|------|------|-------|------|
| `MAX_HP` | `int` | `100` | GDD does not specify exact player HP — use 100 as vertical-slice default |
| `current_hp` | `int` | `MAX_HP` | |
| `is_dead` | `bool` | `false` | Blocks input during death |
| `is_invincible` | `bool` | `false` | True during 3 s post-respawn window |
| `RESPAWN_DELAY` | `float` | `5.0` | 5 seconds before respawn per GDD §5.1 |
| `INVINCIBILITY_DURATION` | `float` | `3.0` | 3 seconds post-respawn per GDD §5.1 |
| `ENERGY_DEATH_PENALTY` | `float` | `0.25` | 25% energy loss on death per GDD §5.1 |

**New methods:**

1. **`take_damage(amount: int) -> void`**:
   - If `is_dead` or `is_invincible`: return early (ignore damage).
   - `current_hp = max(current_hp - amount, 0)`.
   - Emit `hp_changed(current_hp, MAX_HP)`.
   - Flash sprite red briefly: tween `_sprite.modulate` to `Color(1, 0.3, 0.3)` over 0.05 s, then back to `Color.WHITE` over 0.15 s.
   - If `current_hp <= 0`: call `_die()`.

2. **`heal(amount: int) -> void`**:
   - If `is_dead`: return.
   - `current_hp = min(current_hp + amount, MAX_HP)`.
   - Emit `hp_changed(current_hp, MAX_HP)`.

3. **`_die() -> void`**:
   - `is_dead = true`.
   - `velocity = Vector2.ZERO`.
   - Emit `player_died`.
   - Hide the sprite: `_sprite.modulate.a = 0.3` (ghost effect).
   - Disable collision: `set_collision_layer_value(3, false)` (remove from player layer).
   - Start a respawn timer: create a `get_tree().create_timer(RESPAWN_DELAY)` and `await` its `timeout`, then call `_respawn()`.

4. **`_respawn() -> void`**:
   - Teleport player near the Dianthus Core: `global_position = GameManager.dianthus_core.global_position + Vector2(0, 32)` (32 px below Core, so the player doesn't overlap it). If `GameManager.dianthus_core` is null, use current position (fallback).
   - `current_hp = MAX_HP`.
   - `is_dead = false`.
   - Restore sprite: `_sprite.modulate = Color.WHITE`.
   - Re-enable collision: `set_collision_layer_value(3, true)`.
   - Emit `hp_changed(current_hp, MAX_HP)`.
   - Emit `player_respawned`.
   - Apply energy penalty: this is a **stub** for now since the energy system (PLANT-07) does not exist yet. Add a comment: `# TODO (PLANT-07): Apply -25% stored energy penalty here.`
   - Call `_start_invincibility()`.

5. **`_start_invincibility() -> void`**:
   - `is_invincible = true`.
   - Visual feedback: create a looping tween that blinks `_sprite.modulate.a` between 1.0 and 0.4 every 0.15 s.
   - After `INVINCIBILITY_DURATION` seconds (`await get_tree().create_timer(INVINCIBILITY_DURATION).timeout`), set `is_invincible = false`, kill the blink tween, and restore `_sprite.modulate = Color.WHITE`.

**Modify `_physics_process()`:**

- At the very beginning of `_physics_process()`, add: `if is_dead: return` — this prevents all movement input while dead.

#### B. Modify `GameManager` — `shared/autoloads/game_manager.gd`

Add these new signals to the existing file:

```gdscript
signal player_hp_changed(current_hp: int, max_hp: int)
signal player_died
signal player_respawned
```

Add a `player` reference variable and a registration method:

```gdscript
var player: Node = null

func register_player(p: Node) -> void:
    player = p
    if p.has_signal("hp_changed"):
        p.hp_changed.connect(func(hp: int, max_hp: int) -> void: player_hp_changed.emit(hp, max_hp))
    if p.has_signal("player_died"):
        p.player_died.connect(func() -> void: player_died.emit())
    if p.has_signal("player_respawned"):
        p.player_respawned.connect(func() -> void: player_respawned.emit())
```

#### C. Register Player in Meadow Edge — `world/zones/meadow_edge/meadow_edge.gd`

Add to `_ready()`, after the existing Core registration block:

```gdscript
if is_instance_valid(_player):
    GameManager.register_player(_player)
```

#### D. Debug: Test Damage Input on Player

Add a temporary debug keybind in `player/scripts/player_controller.gd`:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_F3:
            take_damage(25)
            print("DEBUG: Player took 25 damage. HP: %d/%d" % [current_hp, MAX_HP])
        elif event.keycode == KEY_F4:
            heal(25)
            print("DEBUG: Player healed 25. HP: %d/%d" % [current_hp, MAX_HP])
```

---

### CORE-10 — Basic HUD (Player HP + Core HP)

> **GDD refs:** §11.1 (Player HP bar red top-left, Core HP bar green top-center), §12.2 (bar shakes briefly on damage received).

#### A. Create Player HP Bar — `ui/hud/player_hp_bar.tscn`

Create a new `CanvasLayer` scene:

```
PlayerHPBar (CanvasLayer)
└── MarginContainer
    └── VBoxContainer
        ├── Label          — "PLAYER HP", left-aligned, small font
        └── ProgressBar    — stylized red bar
```

Node configuration:
- **`PlayerHPBar`** (`CanvasLayer`): `layer = 10` (same layer as Core HP bar and DebugOverlay).
- **`MarginContainer`**: anchored top-left, `offset_left = 8`, `offset_top = 4`, `offset_right = 128`, `offset_bottom = 30`.
- **`Label`**: text = `"PLAYER HP"`, horizontal alignment left, font size 6.
- **`ProgressBar`**: `min_value = 0`, `max_value = 100`, `value = 100`, `custom_minimum_size = Vector2(120, 10)`, `show_percentage = false`. Style: **red fill** (`Color(0.9, 0.2, 0.2)`) with dark background (`Color(0.1, 0.1, 0.1, 0.8)`), corner radius 2.

#### B. Player HP Bar Script — `ui/hud/player_hp_bar.gd`

```gdscript
extends CanvasLayer

@onready var _bar: ProgressBar = %ProgressBar
@onready var _label: Label = %Label

func _ready() -> void:
    GameManager.player_hp_changed.connect(_on_player_hp_changed)

func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
    _bar.max_value = max_hp
    _bar.value = current_hp
    _label.text = "PLAYER HP  %d / %d" % [current_hp, max_hp]
```

#### C. Add Damage Shake to Both HP Bars

Per GDD §12.2, both HP bars should shake briefly on damage. Implement a shared shake utility.

**In `ui/hud/core_hp_bar.gd`**, add a damage shake:

```gdscript
@onready var _container: MarginContainer = %MarginContainer  # or get the MarginContainer node

func _ready() -> void:
    GameManager.core_hp_changed.connect(_on_core_hp_changed)
    GameManager.core_hp_changed.connect(_on_core_damaged)

func _on_core_damaged(current_hp: int, _max_hp: int) -> void:
    _shake(_container)

func _shake(node: Control) -> void:
    var original_pos: Vector2 = node.position
    var tween: Tween = create_tween()
    tween.tween_property(node, "position", original_pos + Vector2(2, 0), 0.03)
    tween.tween_property(node, "position", original_pos + Vector2(-2, 0), 0.03)
    tween.tween_property(node, "position", original_pos + Vector2(0, 2), 0.03)
    tween.tween_property(node, "position", original_pos + Vector2(-1, -1), 0.03)
    tween.tween_property(node, "position", original_pos, 0.03)
```

**Important caveat about shake direction:** The shake should only trigger when HP *decreases*, not on heal. To properly detect damage vs. heal, track the previous HP value and only shake when `current_hp < _prev_hp`. Store `_prev_hp` as a variable and update it in `_on_core_hp_changed`.

Apply the same shake pattern to `ui/hud/player_hp_bar.gd`:

```gdscript
var _prev_hp: int = -1

func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
    _bar.max_value = max_hp
    _bar.value = current_hp
    _label.text = "PLAYER HP  %d / %d" % [current_hp, max_hp]
    if _prev_hp >= 0 and current_hp < _prev_hp:
        _shake(_bar.get_parent().get_parent())  # shake the MarginContainer
    _prev_hp = current_hp
```

Use the same `_shake()` function body as Core HP bar.

#### D. Modify Core HP Bar — `ui/hud/core_hp_bar.gd`

Update the existing Core HP bar script to also track previous HP and shake only on damage:

```gdscript
extends CanvasLayer

@onready var _bar: ProgressBar = %ProgressBar
@onready var _label: Label = %Label

var _prev_hp: int = -1

func _ready() -> void:
    GameManager.core_hp_changed.connect(_on_core_hp_changed)

func _on_core_hp_changed(current_hp: int, max_hp: int) -> void:
    _bar.max_value = max_hp
    _bar.value = current_hp
    _label.text = "DIANTHUS CORE  %d / %d" % [current_hp, max_hp]
    if _prev_hp >= 0 and current_hp < _prev_hp:
        _shake()
    _prev_hp = current_hp

func _shake() -> void:
    var node: Control = _bar.get_parent().get_parent()  # MarginContainer
    var original_pos: Vector2 = node.position
    var tween: Tween = create_tween()
    tween.tween_property(node, "position", original_pos + Vector2(2, 0), 0.03)
    tween.tween_property(node, "position", original_pos + Vector2(-2, 0), 0.03)
    tween.tween_property(node, "position", original_pos + Vector2(0, 2), 0.03)
    tween.tween_property(node, "position", original_pos + Vector2(-1, -1), 0.03)
    tween.tween_property(node, "position", original_pos, 0.03)
```

#### E. Instance Player HP Bar in Meadow Edge

In `world/zones/meadow_edge/meadow_edge.tscn`, add a new instance of `ui/hud/player_hp_bar.tscn` as a sibling to the existing `CoreHPBar` node.

#### F. Emit Initial HP on Ready

In `player_controller.gd`, at the end of `_ready()` (add a `_ready()` function if one doesn't exist), emit the initial HP so the HUD bar is correct on scene load:

```gdscript
func _ready() -> void:
    hp_changed.emit(current_hp, MAX_HP)
```

Similarly, in `dianthus_core.gd`, ensure `hp_changed` is emitted in `_ready()` (after `GameManager.register_core()` is called in meadow_edge) so the Core HP bar has correct initial values. The current code does NOT emit on ready — it only emits on damage/heal. Either:
- Add `hp_changed.emit(current_hp, MAX_HP)` at the end of `dianthus_core.gd`'s `_ready()`, OR
- Call it from `meadow_edge.gd` after `register_core()`.

The simplest fix: add `call_deferred("_emit_initial_hp")` in `dianthus_core.gd`'s `_ready()`:

```gdscript
func _emit_initial_hp() -> void:
    hp_changed.emit(current_hp, MAX_HP)
```

---

## Technical Standards

Apply these rules across all files:

- **Static typing everywhere:** `var x: int = 0`, `func foo(bar: String) -> void:`
- **Unique name references:** Use `%NodeName` syntax for `@onready var` node references where appropriate. Mark nodes with `unique_name_in_owner = true` in the `.tscn` files.
- **Godot 4 signal syntax:** `signal my_signal(arg: Type)`
- **No new comments or documentation** unless they were already present in the file. Exception: the single `# TODO (PLANT-07)` comment specified above.
- **No deletion** of existing data in `.tscn` files — only add new nodes or modify existing properties.
- **Prefer minimal edits** — do not rewrite files that already work correctly. Extend them.
- **Player group:** The player node is accessed via `get_tree().get_first_node_in_group("player")` in `scene_transition.gd`. Ensure the Player remains in the `"player"` group. (It is currently set via the scene, not code — do not remove it.)

---

## File Checklist

| Action | File | Reason |
|--------|------|--------|
| **Modify** | `player/scripts/player_controller.gd` | Add HP system (signals, `current_hp`, `MAX_HP`, `take_damage()`, `heal()`, `_die()`, `_respawn()`, `_start_invincibility()`, `is_dead` guard in `_physics_process()`), debug keys F3/F4, `_ready()` with initial HP emit |
| **Modify** | `shared/autoloads/game_manager.gd` | Add `player_hp_changed`, `player_died`, `player_respawned` signals; `player` reference; `register_player()` method |
| **Modify** | `world/zones/meadow_edge/meadow_edge.gd` | Call `GameManager.register_player(_player)` in `_ready()` |
| **Create** | `ui/hud/player_hp_bar.tscn` | HUD CanvasLayer with red ProgressBar for Player HP, top-left |
| **Create** | `ui/hud/player_hp_bar.gd` | Listens to `GameManager.player_hp_changed`, updates bar, shakes on damage |
| **Modify** | `ui/hud/core_hp_bar.gd` | Add damage shake (only when HP decreases), track `_prev_hp` |
| **Modify** | `core/dianthus_core/dianthus_core.gd` | Emit `hp_changed` on `_ready()` (deferred) so HUD initializes correctly |
| **Modify** | `world/zones/meadow_edge/meadow_edge.tscn` | Instance `player_hp_bar.tscn` as a child node |

---

## Acceptance Criteria

Run the project and confirm all of the following:

### CORE-08

1. **Player has HP.** Player starts with 100/100 HP. Press F3 to deal 25 damage — HP decreases. Press F4 to heal.
2. **Damage flash.** Player sprite briefly flashes red when taking damage, then returns to normal.
3. **Invincibility blocks damage.** During the 3 s invincibility window, F3 does not reduce HP.
4. **Player death.** When Player HP reaches 0, the player stops moving, the sprite becomes ghostly (low alpha), and collision is disabled.
5. **Respawn after 5 s.** After 5 seconds, the player teleports near the Dianthus Core (32 px below it), HP resets to full, sprite restores, collision re-enables.
6. **Respawn invincibility.** After respawning, the sprite blinks for 3 seconds. During blinking, damage is ignored.
7. **Invincibility ends.** After 3 s the blinking stops, sprite is fully opaque, and the player can take damage again.
8. **Death during game over.** If the Core is destroyed (CORE-04 game over) while the player is dead/respawning, no crash occurs.
9. **Equipped items retained.** (No items exist yet — this criterion is satisfied by default since no inventory is cleared on respawn.)

### CORE-10

10. **Player HP bar visible.** A red progress bar labeled "PLAYER HP" appears at the top-left of the screen, showing 100/100 on load.
11. **Core HP bar visible.** The existing green Core HP bar remains at top-center, showing 200/200 on load (initial emit fix).
12. **Player HP bar updates.** Pressing F3/F4 updates the Player HP bar in real time.
13. **Core HP bar updates.** Pressing F1/F2 updates the Core HP bar in real time (existing behavior preserved).
14. **Player HP bar shakes on damage.** When Player HP decreases, the bar shakes briefly (~0.15 s). Does NOT shake on heal.
15. **Core HP bar shakes on damage.** When Core HP decreases, the bar shakes briefly (~0.15 s). Does NOT shake on heal.
16. **Both bars coexist.** Player HP (top-left, red) and Core HP (top-center, green) are both visible simultaneously without overlapping.

### Post-Implementation

17. **Update `TASK_BREAKDOWN.md`.** Mark CORE-08 and CORE-10 as `Done`.
