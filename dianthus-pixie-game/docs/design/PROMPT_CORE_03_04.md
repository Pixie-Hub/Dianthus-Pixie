# CORE-03 & CORE-04 — Dianthus Core Entity, HP & Game Over

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

- `GameState` enum: `EXPLORATION`, `PREPARATION`, `DEFENSE`, `GAME_OVER`, `TRANSITIONING`.
- `set_state()` method and `game_state_changed` signal.
- `player_data` dictionary with `position`, `last_zone`, `inventory` keys.

### 2. `DayNightCycle` — `core/day_night/day_night_cycle.gd`

- `Phase` enum: `MORNING`, `AFTERNOON`, `NIGHT`.
- Phase durations: 120 s / 60 s / 90 s.
- `phase_changed` signal, `day_count`, tint system via `register_canvas_modulate()`.
- Utility: `get_phase_name()`, `get_time_remaining()`, `get_phase_progress()`, `is_night()`.

### 3. `SceneTransition` — `core/transitions/scene_transition.gd`

- `CanvasLayer` (layer 128) with fade-in/fade-out overlay.
- `transition_to(target_scene)` blocked during `DEFENSE` state.

### 4. Player Scene — `player/scenes/player.tscn`

- `CharacterBody2D` on collision layer 3 (player), mask layer 2 (terrain).
- `AnimatedSprite2D` with 8 animations (idle/walk × 4 directions).
- `CollisionShape2D` — `CapsuleShape2D` (radius 5, height 22).
- `Camera2D` with custom `smooth_camera.gd` (look-ahead, deadzone, limit clamping).
- Script: `player/scripts/player_controller.gd` — 8-dir movement at 80 px/s, `set_camera_limits()`.

### 5. Meadow Edge Zone — `world/zones/meadow_edge/`

- `meadow_edge.tscn`: `Node2D` with `CanvasModulate`, `TileMapLayer` (16×16 px tiles), Player instance, `DebugOverlay`.
- `meadow_edge.gd`: Registers canvas modulate, sets camera limits (`ZONE_WIDTH=40`, `ZONE_HEIGHT=30`, `TILE_SIZE=16`), restores player position.

### 6. Collision Layers — `shared/collision_layers.gd`

```
INTERACTABLE = 1, TERRAIN = 2, PLAYER = 4, ENEMY = 8, PROJECTILE = 16
```

### 7. Empty Folders Awaiting Content

- `core/dianthus_core/` — empty, target for Core entity.
- `ui/hud/` — empty, target for HUD elements.
- `ui/screens/` — empty, target for Game Over screen.

### 8. Available Sprite for Core

- Use Godot's default icon at `res://icon.svg` as the placeholder Dianthus Core sprite. Do **not** create or import any new image assets.

---

## Tasks To Complete

Work in dependency order: CORE-03 first, then CORE-04.

---

### CORE-03 — Dianthus Core Entity & HP

> **GDD refs:** §10.2 (garden layout, Core at center), §12.1 (glowing pink-white aura, dims with HP), §13.2 (Core HP mechanics), §11.1 (Core HP bar on HUD), §12.2 (idle glow, damage state, destruction animations).

#### A. Dianthus Core Scene — `core/dianthus_core/dianthus_core.tscn`

Create a new scene with this node tree:

```
DianthusCore (StaticBody2D)
├── Sprite2D              — texture: res://icon.svg, scale to 1×1 (it's already 128×128 SVG, scale down to ~32×32 effective via scale property)
├── CollisionShape2D      — CircleShape2D, radius ~12 px
├── AuraLight (PointLight2D) — glowing pink-white aura
└── DamageArea (Area2D)
    └── CollisionShape2D  — CircleShape2D, radius ~16 px (slightly larger than body)
```

Node configuration:
- **`DianthusCore`** (`StaticBody2D`): collision layer = `INTERACTABLE` (1), collision mask = 0 (does not scan).
- **`Sprite2D`**: `texture = preload("res://icon.svg")`. Set `scale = Vector2(0.25, 0.25)` so the 128×128 SVG renders at ~32×32 px. Apply `self_modulate = Color(1.0, 0.8, 0.9)` for a subtle pink tint.
- **`AuraLight`** (`PointLight2D`): `color = Color(1.0, 0.75, 0.85)` (pink-white), `energy = 1.5`, `texture` = Godot's default light texture (or a soft radial gradient). Set `texture_scale = 3.0` so the glow extends visibly around the Core. This light's `energy` will be modulated proportionally to current HP.
- **`DamageArea`** (`Area2D`): collision layer = 0, collision mask = `ENEMY` (8). This detects enemies that reach the Core. Connect `body_entered` signal in the script to process enemy damage.

#### B. Dianthus Core Script — `core/dianthus_core/dianthus_core.gd`

```gdscript
extends StaticBody2D
```

**Signals:**

```gdscript
signal hp_changed(current_hp: int, max_hp: int)
signal core_destroyed
signal core_damaged(amount: int)
```

**Constants & variables:**

| Name | Type | Value | Note |
|------|------|-------|------|
| `MAX_HP` | `int` | `200` | GDD does not specify — use 200 as vertical-slice default |
| `DAYTIME_REGEN_RATE` | `float` | `5.0 / 60.0` | 5 HP per minute = ~0.083 HP/s (GDD §13.2) |
| `current_hp` | `int` | `MAX_HP` | |
| `_aura_light` | `PointLight2D` | `@onready %AuraLight` | |
| `_sprite` | `Sprite2D` | `@onready %Sprite2D` | |
| `_base_aura_energy` | `float` | `1.5` | Store initial energy to scale proportionally |
| `_regen_accumulator` | `float` | `0.0` | Accumulates fractional regen |

**Methods:**

1. **`_ready()`**: Store `_base_aura_energy = _aura_light.energy`. Connect `DamageArea.body_entered` to `_on_enemy_entered`. Connect `DayNightCycle.phase_changed` to `_on_phase_changed`.

2. **`_process(delta)`**: If NOT night (`!DayNightCycle.is_night()`), accumulate regen:
   ```gdscript
   _regen_accumulator += DAYTIME_REGEN_RATE * delta
   if _regen_accumulator >= 1.0:
       var amount: int = int(_regen_accumulator)
       _regen_accumulator -= float(amount)
       heal(amount)
   ```

3. **`take_damage(amount: int) -> void`**:
   - Clamp: `current_hp = max(current_hp - amount, 0)`.
   - Emit `hp_changed`.
   - Emit `core_damaged` (for future HUD shake).
   - Call `_update_aura()`.
   - Flash sprite red briefly: tween `_sprite.modulate` to `Color(1, 0.3, 0.3)` over 0.1 s, then back to `Color(1.0, 0.8, 0.9)` over 0.2 s.
   - If `current_hp <= 0`: emit `core_destroyed`.

4. **`heal(amount: int) -> void`**:
   - Clamp: `current_hp = min(current_hp + amount, MAX_HP)`.
   - Emit `hp_changed`.
   - Call `_update_aura()`.

5. **`_update_aura() -> void`**:
   - Calculate HP ratio: `var ratio: float = float(current_hp) / float(MAX_HP)`.
   - Tween `_aura_light.energy` to `_base_aura_energy * ratio` over 0.5 s.
   - Tween `_sprite.modulate.a` between 0.5 (dead) and 1.0 (full HP) proportionally: `lerp(0.5, 1.0, ratio)`.

6. **`_on_enemy_entered(body: Node2D) -> void`**: Stub for now — when enemies are implemented (CORE-06), this will call `take_damage(body.attack_damage)`. For testing, add a print: `print("Core hit by: ", body.name)`.

7. **`get_hp_ratio() -> float`**: Returns `float(current_hp) / float(MAX_HP)`.

#### C. Modify `GameManager` — `shared/autoloads/game_manager.gd`

Add to the existing file:

```gdscript
signal core_hp_changed(current_hp: int, max_hp: int)
signal core_destroyed
signal game_over_triggered

var dianthus_core: Node = null
```

Add method:

```gdscript
func register_core(core: Node) -> void:
    dianthus_core = core
    if core.has_signal("hp_changed"):
        core.hp_changed.connect(func(hp: int, max_hp: int): core_hp_changed.emit(hp, max_hp))
    if core.has_signal("core_destroyed"):
        core.core_destroyed.connect(_on_core_destroyed)

func _on_core_destroyed() -> void:
    set_state(GameState.GAME_OVER)
    game_over_triggered.emit()
```

This lets the HUD and Game Over screen listen to `GameManager` without needing a direct reference to the Core node.

#### D. Place Core in Meadow Edge (Temporary for Testing)

> The Garden zone (GDD §10.2) does not exist yet. Place the Dianthus Core in `meadow_edge.tscn` at the center of the zone for vertical-slice testing. It will be relocated to the garden scene when that is built.

In `world/zones/meadow_edge/meadow_edge.tscn`:
- Instance `core/dianthus_core/dianthus_core.tscn` as a child of the root `Node2D`.
- Position it at the zone center: `Vector2(ZONE_WIDTH * TILE_SIZE / 2, ZONE_HEIGHT * TILE_SIZE / 2)` = `Vector2(320, 240)`.
- Name the node `DianthusCore`.

In `world/zones/meadow_edge/meadow_edge.gd`, add to `_ready()`:

```gdscript
var core: Node = $DianthusCore
if is_instance_valid(core) and core.has_method("get_hp_ratio"):
    GameManager.register_core(core)
```

#### E. Core HP Bar (HUD) — `ui/hud/core_hp_bar.gd`

Create a `CanvasLayer` scene at `ui/hud/core_hp_bar.tscn`:

```
CoreHPBar (CanvasLayer)
└── MarginContainer
    └── VBoxContainer
        ├── Label          — "DIANTHUS CORE", centered, small font
        └── ProgressBar    — stylized green bar
```

Node configuration:
- **`CoreHPBar`** (`CanvasLayer`): `layer = 10` (above game, below transitions).
- **`MarginContainer`**: anchored top-center, `offset_left = -80`, `offset_right = 80`, `offset_top = 4`, `offset_bottom = 30`.
- **`Label`**: text = `"DIANTHUS CORE"`, horizontal alignment center, font size 6 (pixel scale appropriate).
- **`ProgressBar`**: `min_value = 0`, `max_value = 200`, `value = 200`, `custom_minimum_size = Vector2(160, 10)`. Style: green fill (`Color(0.2, 0.9, 0.3)`), dark background.

Script `ui/hud/core_hp_bar.gd`:

```gdscript
extends CanvasLayer

@onready var _bar: ProgressBar = %ProgressBar
@onready var _label: Label = %Label

func _ready() -> void:
    GameManager.core_hp_changed.connect(_on_core_hp_changed)

func _on_core_hp_changed(current_hp: int, max_hp: int) -> void:
    _bar.max_value = max_hp
    _bar.value = current_hp
    _label.text = "DIANTHUS CORE  %d / %d" % [current_hp, max_hp]
```

Instance this scene in `meadow_edge.tscn` (or add it as a child in `meadow_edge.gd`'s `_ready()`).

#### F. Debug: Test Damage Input

Add a temporary debug keybind in `core/dianthus_core/dianthus_core.gd` so you can test without enemies:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_F1:
            take_damage(20)
            print("DEBUG: Core took 20 damage. HP: %d/%d" % [current_hp, MAX_HP])
        elif event.keycode == KEY_F2:
            heal(20)
            print("DEBUG: Core healed 20. HP: %d/%d" % [current_hp, MAX_HP])
```

---

### CORE-04 — Game Over on Core HP 0

> **GDD refs:** §5.1 (Game Over — immediate, no grace period; show days survived; Restart + Main Menu), §5.1 (no last-stand mechanic).

#### A. Game Over Screen — `ui/screens/game_over_screen.tscn`

Create a `CanvasLayer` scene:

```
GameOverScreen (CanvasLayer)
└── ColorRect             — full-screen dark overlay
    └── CenterContainer
        └── VBoxContainer
            ├── TitleLabel      — "GAME OVER"
            ├── DaysLabel       — "You survived X days"
            ├── HSeparator
            ├── RestartButton   — "Restart"
            └── MainMenuButton  — "Main Menu"
```

Node configuration:
- **`GameOverScreen`** (`CanvasLayer`): `layer = 100` (above HUD, below SceneTransition at 128).
- **`ColorRect`**: full rect, `color = Color(0, 0, 0, 0.75)` — semi-transparent black.
- **`TitleLabel`**: text = `"GAME OVER"`, horizontal alignment center, font size 24 (or theme-appropriate), color `Color(0.9, 0.2, 0.2)` (red).
- **`DaysLabel`**: text placeholder = `"You survived 1 day"`, horizontal alignment center, font size 10.
- **`RestartButton`**: text = `"Restart"`, `custom_minimum_size = Vector2(120, 30)`.
- **`MainMenuButton`**: text = `"Main Menu"`, `custom_minimum_size = Vector2(120, 30)`.
- The entire `GameOverScreen` starts **hidden** (`visible = false`).

#### B. Game Over Script — `ui/screens/game_over_screen.gd`

```gdscript
extends CanvasLayer
```

**Onready refs:**

```gdscript
@onready var _days_label: Label = %DaysLabel
@onready var _restart_button: Button = %RestartButton
@onready var _main_menu_button: Button = %MainMenuButton
```

**Methods:**

1. **`_ready()`**:
   - `visible = false`.
   - `GameManager.game_over_triggered.connect(_on_game_over)`.
   - `_restart_button.pressed.connect(_on_restart)`.
   - `_main_menu_button.pressed.connect(_on_main_menu)`.

2. **`_on_game_over()`**:
   - `get_tree().paused = true` — freeze the game immediately (no grace period).
   - Set `process_mode = Node.PROCESS_MODE_ALWAYS` on this CanvasLayer so UI remains interactive while tree is paused.
   - Update label: `_days_label.text = "You survived %d day%s" % [DayNightCycle.day_count, "s" if DayNightCycle.day_count != 1 else ""]`.
   - `visible = true`.

3. **`_on_restart()`**:
   - `get_tree().paused = false`.
   - `visible = false`.
   - Reset `DayNightCycle.day_count = 1` and `DayNightCycle.current_phase = DayNightCycle.Phase.MORNING`.
   - Reset `GameManager.current_state = GameManager.GameState.EXPLORATION`.
   - `get_tree().reload_current_scene()`.

4. **`_on_main_menu()`**:
   - `get_tree().paused = false`.
   - `visible = false`.
   - For now, reload current scene (no main menu exists yet):
     `get_tree().reload_current_scene()`.
   - Add a `# TODO: Replace with SceneTransition.transition_to("res://ui/menus/main_menu.tscn") when main menu exists.`

#### C. Instance Game Over Screen

Add the `GameOverScreen` scene instance to `meadow_edge.tscn` (or whichever zone contains the Core). It should be a sibling of the root node or instanced via `GameManager` — for simplicity, instance it directly in the zone scene.

Alternatively, if you prefer a global approach: register `GameOverScreen` as an autoload. However, since it's UI with visual nodes, instancing it in the zone scene is cleaner for now.

#### D. Pause Mode Configuration

Ensure the `GameOverScreen` node has `process_mode = PROCESS_MODE_ALWAYS` set either in the scene or in `_on_game_over()`. This is critical — without it, the buttons won't respond when the tree is paused.

---

## Technical Standards

Apply these rules across all files:

- **Static typing everywhere:** `var x: int = 0`, `func foo(bar: String) -> void:`
- **Unique name references:** Use `%NodeName` syntax for `@onready var` node references where appropriate.
- **Godot 4 signal syntax:** `signal my_signal(arg: Type)`
- **No new comments or documentation** unless they were already present in the file.
- **No deletion** of existing data in `.tscn` files.
- **Prefer minimal edits** — do not rewrite files that already work correctly.
- **Sprite for Core:** Use only `res://icon.svg` (Godot default icon). Do not create or import new image assets.

---

## File Checklist

| Action | File | Reason |
|--------|------|--------|
| **Create** | `core/dianthus_core/dianthus_core.tscn` | Core entity scene (StaticBody2D + Sprite2D using icon.svg + PointLight2D aura + DamageArea) |
| **Create** | `core/dianthus_core/dianthus_core.gd` | Core HP logic, aura dimming, damage/heal, regen, signals |
| **Modify** | `shared/autoloads/game_manager.gd` | Add `core_hp_changed`, `core_destroyed`, `game_over_triggered` signals; `register_core()` method; `dianthus_core` reference |
| **Modify** | `world/zones/meadow_edge/meadow_edge.tscn` | Instance DianthusCore at zone center (320, 240); instance CoreHPBar and GameOverScreen |
| **Modify** | `world/zones/meadow_edge/meadow_edge.gd` | Call `GameManager.register_core()` in `_ready()` |
| **Create** | `ui/hud/core_hp_bar.tscn` | HUD CanvasLayer with ProgressBar for Core HP |
| **Create** | `ui/hud/core_hp_bar.gd` | Listens to `GameManager.core_hp_changed`, updates bar |
| **Create** | `ui/screens/game_over_screen.tscn` | Game Over CanvasLayer with days survived, Restart, Main Menu |
| **Create** | `ui/screens/game_over_screen.gd` | Pauses tree, shows days, handles Restart/Main Menu |

---

## Acceptance Criteria

Run the project and confirm all of the following:

### CORE-03

1. **Core renders.** The Dianthus Core appears at the center of the Meadow Edge zone using the Godot default `icon.svg`, tinted pink, scaled to ~32×32 px.
2. **Aura glows.** A pink-white `PointLight2D` aura is visible around the Core.
3. **HP system works.** Press F1 to deal 20 damage — `hp_changed` signal fires, HP decreases. Press F2 to heal.
4. **Aura dims proportionally.** As HP drops, the `PointLight2D` energy decreases and the sprite becomes more transparent. At full HP, aura is at full intensity.
5. **Damage flash.** Sprite briefly flashes red on damage, then returns to pink tint.
6. **Daytime regen.** During Morning/Afternoon phases, Core HP slowly regenerates at ~5 HP/min. During Night, regen stops.
7. **HUD bar.** A green progress bar labeled "DIANTHUS CORE" appears at the top center of the screen, showing current/max HP. Updates in real time when damage or healing occurs.

### CORE-04

8. **Game Over triggers.** When Core HP reaches 0 (press F1 repeatedly), the game immediately pauses and a Game Over screen appears.
9. **Days survived.** The Game Over screen displays `"You survived X days"` using `DayNightCycle.day_count`.
10. **Restart works.** Clicking "Restart" unpauses the game, resets the day counter to 1, and reloads the current scene with full Core HP.
11. **Main Menu button.** Clicking "Main Menu" reloads the scene (placeholder behavior until main menu exists).
12. **No grace period.** Game Over is instant — no last-stand mechanic, no delay.
13. **No input bleed.** While Game Over screen is visible, player movement and game input are frozen (tree is paused). Only the Game Over UI buttons respond.

### Post-Implementation

14. **Update `TASK_BREAKDOWN.md`.** Mark CORE-03 and CORE-04 as `Done`.