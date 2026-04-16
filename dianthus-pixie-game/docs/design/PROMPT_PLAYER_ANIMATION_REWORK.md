# Player Animation Rework — Sprite2D + AnimationPlayer + AnimationTree

## Context

| Key | Value |
|-----|-------|
| **Project** | Dianthus Pixie — 2D survival crafting action game |
| **Engine** | Godot 4.6 (Forward Plus) |
| **Viewport** | 640×360, stretch mode `canvas_items`, integer scale |
| **Art** | 2D Pixel Art — 16×16 tiles, 64×64 character sprite frames |
| **Repo root** | `c:\Users\Indra\Programming\GIGA\Dianthus Pixie\dianthus-pixie-game` |

---

## Why This Rework

The current player scene uses `AnimatedSprite2D` with an inline `SpriteFrames` resource containing ~450 lines of `AtlasTexture` sub_resources. This approach:
- Bloats `player.tscn` (~900 lines, mostly atlas data).
- Makes adding new animation states (run, attack, sword variants) tedious.
- Provides no state machine — animation selection is done via string concatenation in code (`_sprite.play("walk_down")`).
- Cannot blend or manage transitions between animation states.

Replacing with **Sprite2D + AnimationPlayer + AnimationTree** gives us:
- A proper **state machine** for animation states (idle, walk, hurt, death, and future: run, attack).
- **BlendSpace2D** nodes for automatic directional animation selection based on facing direction.
- Cleaner `.tscn` file (animations built programmatically from sprite sheet data).
- Easy extensibility for sword animations, attack combos, etc.

---

## Current State — What Exists

> **Do NOT recreate or modify** anything listed here unless this prompt explicitly says to.

### 1. Player Scene — `player/scenes/player.tscn`

Current node tree:
```
Player (CharacterBody2D) — collision_layer = 4 (PLAYER), collision_mask = 2 (TERRAIN)
├── AnimatedSprite2D (unique_name_in_owner) — SpriteFrames with 16 animations
├── CollisionShape2D — CapsuleShape2D (radius 5, height 22)
└── Camera2D (unique_name_in_owner) — zoom Vector2(1.5, 1.5), smooth_camera.gd
```

The `AnimatedSprite2D` uses an inline `SpriteFrames` resource with these animations (all at speed 10.0 FPS):

| Animation | Sprite Sheet | Frames | Loop | Duration |
|-----------|-------------|--------|------|----------|
| idle_down | Unarmed_Idle_full.png | 12 (dur 1.0 each) | true | 1.2 s |
| idle_left | Unarmed_Idle_full.png | 12 (dur 1.0 each) | true | 1.2 s |
| idle_right | Unarmed_Idle_full.png | 12 (dur 1.0 each) | true | 1.2 s |
| idle_up | Unarmed_Idle_full.png | 4 (dur 3.0 each) | true | 1.2 s |
| walk_down | Unarmed_Walk_full.png | 6 | true | 0.6 s |
| walk_left | Unarmed_Walk_full.png | 6 | true | 0.6 s |
| walk_right | Unarmed_Walk_full.png | 6 | true | 0.6 s |
| walk_up | Unarmed_Walk_full.png | 6 | true | 0.6 s |
| hurt_down | Unarmed_Hurt_full.png | 5 | false | 0.5 s |
| hurt_left | Unarmed_Hurt_full.png | 5 | false | 0.5 s |
| hurt_right | Unarmed_Hurt_full.png | 5 | false | 0.5 s |
| hurt_up | Unarmed_Hurt_full.png | 5 | false | 0.5 s |
| death_down | Unarmed_Death_full.png | 7 | false | 0.7 s |
| death_left | Unarmed_Death_full.png | 7 | false | 0.7 s |
| death_right | Unarmed_Death_full.png | 7 | false | 0.7 s |
| death_up | Unarmed_Death_full.png | 7 | false | 0.7 s |

**Key detail — idle_up**: Only 4 frames exist in the sprite sheet (row 3 has 4 filled cells out of 12 columns). The SpriteFrames compensates by setting frame duration to 3.0× so total animation time matches other idle directions (1.2 s).

### 2. Player Controller — `player/scripts/player_controller.gd`

Current animation-related code:

```gdscript
@onready var _sprite: AnimatedSprite2D = %AnimatedSprite2D

func _physics_process(_delta: float) -> void:
    if is_dead:
        return
    # ... input handling ...
    if dir != Vector2.ZERO:
        _play_animation("walk")
    else:
        _play_animation("idle")
    move_and_slide()

func _play_animation(prefix: String) -> void:
    var suffix: String
    if last_direction == Vector2.UP: suffix = "_up"
    elif last_direction == Vector2.DOWN: suffix = "_down"
    elif last_direction == Vector2.LEFT: suffix = "_left"
    else: suffix = "_right"
    var anim: String = prefix + suffix
    if _sprite.animation != anim:
        _sprite.play(anim)
```

Other code that references `_sprite` (keep this behavior):
- `take_damage()` — tweens `_sprite.modulate` red→white for damage flash.
- `_die()` — sets `_sprite.modulate.a = 0.3` for ghost effect.
- `_respawn()` — resets `_sprite.modulate = Color.WHITE`.
- `_start_invincibility()` — blink tween on `_sprite.modulate.a`.

### 3. Sprite Sheet Catalog

All sheets are in `res://player/sprites/PNG/`. Each `*_full.png` is a grid of 64×64 px frames with **4 rows** (row 0 = down, row 1 = left, row 2 = right, row 3 = up).

#### Unarmed Set (implement these)

| Sheet Path | Columns | Frames per Direction (D/L/R/U) |
|------------|---------|-------------------------------|
| `Unarmed_Idle/Unarmed_Idle_full.png` | 12 | 12 / 12 / 12 / 4 |
| `Unarmed_Walk/Unarmed_Walk_full.png` | 6 | 6 / 6 / 6 / 6 |
| `Unarmed_Run/Unarmed_Run_full.png` | 8 | 8 / 8 / 8 / 8 |
| `Unarmed_Hurt/Unarmed_Hurt_full.png` | 5 | 5 / 5 / 5 / 5 |
| `Unarmed_Death/Unarmed_Death_full.png` | 7 | 7 / 7 / 7 / 7 |

#### Sword Set (DO NOT implement — documented for future reference)

| Sheet Path | Columns | Frames per Direction (D/L/R/U) |
|------------|---------|-------------------------------|
| `Sword_Idle/Sword_Idle_full.png` | 12 | 12 / 12 / 12 / 4 |
| `Sword_Walk/Sword_Walk_full.png` | 6 | 6 / 6 / 6 / 6 |
| `Sword_Run/Sword_Run_full.png` | 8 | 8 / 8 / 8 / 8 |
| `Sword_Hurt/Sword_Hurt_full.png` | 5 | 5 / 5 / 5 / 5 |
| `Sword_Death/Sword_Death_full.png` | 7 | 7 / 7 / 7 / 7 |
| `Sword_attack/Sword_attack_full.png` | 8 | 8 / 8 / 8 / 8 |
| `Sword_Walk_Attack/Sword_Walk_Attack_full.png` | 6 | 6 / 6 / 6 / 6 |
| `Sword_Run_Attack/Sword_Run_Attack_full.png` | 8 | 8 / 8 / 8 / 8 |

### 4. Other Files (DO NOT modify unless stated)

- `shared/autoloads/game_manager.gd` — Has `register_player()`, player signals. No changes needed.
- `world/zones/meadow_edge/meadow_edge.gd` — Registers player. No changes needed.
- `ui/hud/player_hp_bar.gd`, `ui/hud/core_hp_bar.gd` — HUD bars. No changes needed.
- `player/scripts/smooth_camera.gd` — Camera script. No changes needed.

---

## Tasks To Complete

---

### A. New Node Tree — Modify `player/scenes/player.tscn`

**Remove entirely:**
- The `AnimatedSprite2D` node.
- ALL `AtlasTexture` sub_resources (IDs like `AtlasTexture_qplgm`, `AtlasTexture_hcvc7`, etc.).
- The `SpriteFrames` sub_resource (`SpriteFrames_qm8bx`).

**Add these new nodes** (keep CollisionShape2D and Camera2D unchanged):

```
Player (CharacterBody2D)
├── Sprite2D (unique_name_in_owner)
├── AnimationPlayer (unique_name_in_owner)
├── AnimationTree (unique_name_in_owner)
├── CollisionShape2D  [KEEP AS-IS]
└── Camera2D           [KEEP AS-IS]
```

**Sprite2D** configuration:
- `unique_name_in_owner = true`
- `texture_filter = 1` (TEXTURE_FILTER_NEAREST — pixel art)
- `region_enabled = true`
- `region_rect = Rect2(0, 0, 64, 64)`
- `texture` = `res://player/sprites/PNG/Unarmed_Idle/Unarmed_Idle_full.png` (default)

**AnimationPlayer** configuration:
- `unique_name_in_owner = true`
- Animations will be built programmatically in `_ready()` (see section C).

**AnimationTree** configuration:
- `unique_name_in_owner = true`
- `anim_player` (or `animation_player`) = path to the AnimationPlayer node (e.g., `../AnimationPlayer` or use NodePath)
- `active = false` initially (activated after setup in `_ready()`)
- `tree_root` will be set programmatically (see section D).

---

### B. Create Animation Builder — `player/scripts/player_animation_builder.gd`

Create a new static utility script that programmatically generates all AnimationPlayer animations from the sprite sheet data. This avoids embedding hundreds of keyframe lines in the `.tscn`.

```gdscript
class_name PlayerAnimationBuilder

const FRAME_SIZE: int = 64

const DIR_DOWN: int = 0
const DIR_LEFT: int = 1
const DIR_RIGHT: int = 2
const DIR_UP: int = 3

const DIR_NAMES: PackedStringArray = ["down", "left", "right", "up"]

const ANIM_DEFS: Array[Dictionary] = [
    {
        "prefix": "idle",
        "sheet": "res://player/sprites/PNG/Unarmed_Idle/Unarmed_Idle_full.png",
        "columns": 12,
        "frames": [12, 12, 12, 4],
        "loop": true,
        "duration": 1.2,
    },
    {
        "prefix": "walk",
        "sheet": "res://player/sprites/PNG/Unarmed_Walk/Unarmed_Walk_full.png",
        "columns": 6,
        "frames": [6, 6, 6, 6],
        "loop": true,
        "duration": 0.6,
    },
    {
        "prefix": "run",
        "sheet": "res://player/sprites/PNG/Unarmed_Run/Unarmed_Run_full.png",
        "columns": 8,
        "frames": [8, 8, 8, 8],
        "loop": true,
        "duration": 0.8,
    },
    {
        "prefix": "hurt",
        "sheet": "res://player/sprites/PNG/Unarmed_Hurt/Unarmed_Hurt_full.png",
        "columns": 5,
        "frames": [5, 5, 5, 5],
        "loop": false,
        "duration": 0.5,
    },
    {
        "prefix": "death",
        "sheet": "res://player/sprites/PNG/Unarmed_Death/Unarmed_Death_full.png",
        "columns": 7,
        "frames": [7, 7, 7, 7],
        "loop": false,
        "duration": 0.7,
    },
]


static func build(anim_player: AnimationPlayer, sprite_path: String) -> void:
    var lib: AnimationLibrary = AnimationLibrary.new()

    for def: Dictionary in ANIM_DEFS:
        var sheet: Texture2D = load(def["sheet"])
        for dir_idx: int in 4:
            var anim_name: String = "%s_%s" % [def["prefix"], DIR_NAMES[dir_idx]]
            var frame_count: int = def["frames"][dir_idx]
            var total_time: float = def["duration"]
            var frame_dur: float = total_time / float(frame_count)

            var anim: Animation = Animation.new()
            anim.length = total_time
            anim.loop_mode = Animation.LOOP_LINEAR if def["loop"] else Animation.LOOP_NONE

            # Track 0: texture (discrete, set once at t=0)
            var t_tex: int = anim.add_track(Animation.TYPE_VALUE)
            anim.track_set_path(t_tex, "%s:texture" % sprite_path)
            anim.track_set_interpolation_type(t_tex, Animation.INTERPOLATION_NEAREST)
            anim.value_track_set_update_mode(t_tex, Animation.UPDATE_DISCRETE)
            anim.track_insert_key(t_tex, 0.0, sheet)

            # Track 1: region_enabled (discrete, set once at t=0)
            var t_reg: int = anim.add_track(Animation.TYPE_VALUE)
            anim.track_set_path(t_reg, "%s:region_enabled" % sprite_path)
            anim.value_track_set_update_mode(t_reg, Animation.UPDATE_DISCRETE)
            anim.track_insert_key(t_reg, 0.0, true)

            # Track 2: region_rect (discrete, one key per frame)
            var t_rect: int = anim.add_track(Animation.TYPE_VALUE)
            anim.track_set_path(t_rect, "%s:region_rect" % sprite_path)
            anim.track_set_interpolation_type(t_rect, Animation.INTERPOLATION_NEAREST)
            anim.value_track_set_update_mode(t_rect, Animation.UPDATE_DISCRETE)

            for f: int in frame_count:
                var rect: Rect2 = Rect2(
                    f * FRAME_SIZE,
                    dir_idx * FRAME_SIZE,
                    FRAME_SIZE,
                    FRAME_SIZE
                )
                anim.track_insert_key(t_rect, f * frame_dur, rect)

            lib.add_animation(anim_name, anim)

    # RESET animation (required by AnimationTree for rest pose)
    var reset: Animation = Animation.new()
    reset.length = 0.001
    var rt: int = reset.add_track(Animation.TYPE_VALUE)
    reset.track_set_path(rt, "%s:region_rect" % sprite_path)
    reset.value_track_set_update_mode(rt, Animation.UPDATE_DISCRETE)
    reset.track_insert_key(rt, 0.0, Rect2(0, 0, FRAME_SIZE, FRAME_SIZE))
    lib.add_animation("RESET", reset)

    if anim_player.has_animation_library(""):
        anim_player.remove_animation_library("")
    anim_player.add_animation_library("", lib)
```

**Key design decisions:**
- `duration` for each animation set is the **total animation time** (all directional variants within a set share the same total time so BlendSpace2D works correctly).
- `idle_up` has 4 frames over 1.2 s = 0.3 s per frame. Other idle directions have 12 frames over 1.2 s = 0.1 s per frame. Visually consistent timing.
- `run` animations are included (8 frames over 0.8 s) even though not currently triggered — ready for future use.
- Track paths are relative to AnimationPlayer's `root_node` (which defaults to `..` = Player). So `sprite_path = "Sprite2D"` resolves to the Sprite2D child of Player.

---

### C. AnimationTree Setup — Add to `player/scripts/player_animation_builder.gd`

Add a second static method to build the AnimationTree state machine:

```gdscript
const BLEND_POSITIONS: Dictionary = {
    "down": Vector2(0, 1),
    "up": Vector2(0, -1),
    "left": Vector2(-1, 0),
    "right": Vector2(1, 0),
}

static func build_tree(anim_tree: AnimationTree) -> void:
    var sm: AnimationNodeStateMachine = AnimationNodeStateMachine.new()

    # Create BlendSpace2D for each animation state
    for def: Dictionary in ANIM_DEFS:
        var bs: AnimationNodeBlendSpace2D = AnimationNodeBlendSpace2D.new()
        bs.blend_mode = AnimationNodeBlendSpace2D.BLEND_MODE_DISCRETE
        bs.set_auto_triangles(true)
        bs.min_space = Vector2(-1, -1)
        bs.max_space = Vector2(1, 1)

        for dir_idx: int in 4:
            var anim_node: AnimationNodeAnimation = AnimationNodeAnimation.new()
            anim_node.animation = &"%s_%s" % [def["prefix"], DIR_NAMES[dir_idx]]
            bs.add_blend_point(anim_node, BLEND_POSITIONS[DIR_NAMES[dir_idx]])

        sm.add_node(def["prefix"], bs)

    # Transitions: idle ↔ walk (immediate)
    sm.add_transition("idle", "walk", AnimationNodeStateMachineTransition.new())
    sm.add_transition("walk", "idle", AnimationNodeStateMachineTransition.new())

    # Transitions: idle ↔ run (immediate, for future use)
    sm.add_transition("idle", "run", AnimationNodeStateMachineTransition.new())
    sm.add_transition("run", "idle", AnimationNodeStateMachineTransition.new())
    sm.add_transition("walk", "run", AnimationNodeStateMachineTransition.new())
    sm.add_transition("run", "walk", AnimationNodeStateMachineTransition.new())

    # Transitions: any → hurt (immediate)
    for src: String in ["idle", "walk", "run"]:
        sm.add_transition(src, "hurt", AnimationNodeStateMachineTransition.new())

    # Transition: hurt → idle (auto, when hurt animation finishes)
    var hurt_to_idle: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
    hurt_to_idle.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
    sm.add_transition("hurt", "idle", hurt_to_idle)

    # Transitions: any → death (immediate)
    for src: String in ["idle", "walk", "run", "hurt"]:
        sm.add_transition(src, "death", AnimationNodeStateMachineTransition.new())

    # Transition: death → idle (for respawn — NOT auto, must be triggered via travel())
    sm.add_transition("death", "idle", AnimationNodeStateMachineTransition.new())

    sm.set_graph_offset(Vector2(0, 0))
    anim_tree.tree_root = sm
```

**AnimationTree state machine diagram:**

```
           ┌──────────────────────┐
           │                      │
     ┌─────┤  idle ◄──── hurt ◄───┤──── (any)
     │     │   ▲    (auto@end)    │
     │     │   │                  │
     │     │   ▼                  │
     │     │  walk                │
     │     │   ▲                  │
     │     │   │                  │
     │     │   ▼                  │
     │     │  run                 │
     │     │                      │
     │     └──────────────────────┘
     │
     └────► death ─────► idle (manual, on respawn)
```

**BlendSpace2D configuration** (same for all states):
- `blend_mode = BLEND_MODE_DISCRETE` — critical for pixel art; selects the closest animation with no cross-fade.
- 4 blend points at cardinal positions: down `(0, 1)`, up `(0, -1)`, left `(-1, 0)`, right `(1, 0)`.
- `auto_triangles = true`.
- `min_space = Vector2(-1, -1)`, `max_space = Vector2(1, 1)`.

---

### D. Update Player Controller — `player/scripts/player_controller.gd`

Replace animation-related code. **Do NOT change** HP system, signals, constants, camera logic, debug keys, invincibility, or any non-animation logic.

#### D1. Replace `@onready` references

**Old:**
```gdscript
@onready var _sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var _camera: Camera2D = %Camera2D
```

**New:**
```gdscript
@onready var _sprite: Sprite2D = %Sprite2D
@onready var _anim_player: AnimationPlayer = %AnimationPlayer
@onready var _anim_tree: AnimationTree = %AnimationTree
@onready var _camera: Camera2D = %Camera2D

var _state_machine: AnimationNodeStateMachinePlayback
```

#### D2. Replace `_ready()`

**Old:**
```gdscript
func _ready() -> void:
    hp_changed.emit(current_hp, MAX_HP)
```

**New:**
```gdscript
func _ready() -> void:
    PlayerAnimationBuilder.build(_anim_player, "Sprite2D")
    PlayerAnimationBuilder.build_tree(_anim_tree)
    _anim_tree.active = true
    _state_machine = _anim_tree["parameters/playback"]
    _update_blend_position()
    hp_changed.emit(current_hp, MAX_HP)
```

#### D3. Replace animation calls in `_physics_process()`

**Old:**
```gdscript
func _physics_process(_delta: float) -> void:
    if is_dead:
        return
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
```

**New:**
```gdscript
func _physics_process(_delta: float) -> void:
    if is_dead:
        return
    var dir: Vector2 = Vector2(
        Input.get_axis("move_left", "move_right"),
        Input.get_axis("move_up", "move_down")
    )
    if dir != Vector2.ZERO:
        dir = dir.normalized()
        last_direction = _dominant_direction(dir)
        velocity = dir * SPEED
        _travel("walk")
    else:
        velocity = Vector2.ZERO
        _travel("idle")
    _update_blend_position()
    move_and_slide()
```

#### D4. Replace `_play_animation()` with new animation methods

**Remove entirely:** the `_play_animation()` function.

**Add these new functions:**

```gdscript
func _travel(state: String) -> void:
    var current: StringName = _state_machine.get_current_node()
    if current == state:
        return
    if current == &"hurt" or current == &"death":
        return
    _state_machine.travel(state)

func _direction_to_blend() -> Vector2:
    if last_direction == Vector2.DOWN:
        return Vector2(0, 1)
    if last_direction == Vector2.UP:
        return Vector2(0, -1)
    if last_direction == Vector2.LEFT:
        return Vector2(-1, 0)
    return Vector2(1, 0)

func _update_blend_position() -> void:
    var blend: Vector2 = _direction_to_blend()
    _anim_tree["parameters/idle/blend_position"] = blend
    _anim_tree["parameters/walk/blend_position"] = blend
    _anim_tree["parameters/run/blend_position"] = blend
    _anim_tree["parameters/hurt/blend_position"] = blend
    _anim_tree["parameters/death/blend_position"] = blend
```

**`_travel()` rules:**
- Does nothing if already in the requested state (avoids restarting animations).
- Does NOT interrupt `hurt` or `death` states — those must finish on their own (hurt auto-transitions to idle; death stays until respawn).

#### D5. Update `_die()` to use death animation state

**Old:**
```gdscript
func _die() -> void:
    is_dead = true
    velocity = Vector2.ZERO
    player_died.emit()
    _sprite.modulate.a = 0.3
    set_collision_layer_value(3, false)
    await get_tree().create_timer(RESPAWN_DELAY).timeout
    _respawn()
```

**New:**
```gdscript
func _die() -> void:
    is_dead = true
    velocity = Vector2.ZERO
    player_died.emit()
    _state_machine.travel("death")
    _sprite.modulate.a = 0.3
    set_collision_layer_value(3, false)
    await get_tree().create_timer(RESPAWN_DELAY).timeout
    _respawn()
```

#### D6. Update `_respawn()` to reset animation state

**Old:**
```gdscript
func _respawn() -> void:
    if is_instance_valid(GameManager.dianthus_core):
        global_position = GameManager.dianthus_core.global_position + Vector2(0, 32)
    current_hp = MAX_HP
    is_dead = false
    _sprite.modulate = Color.WHITE
    set_collision_layer_value(3, true)
    hp_changed.emit(current_hp, MAX_HP)
    player_respawned.emit()
    # TODO (PLANT-07): Apply -25% stored energy penalty here.
    _start_invincibility()
```

**New:**
```gdscript
func _respawn() -> void:
    if is_instance_valid(GameManager.dianthus_core):
        global_position = GameManager.dianthus_core.global_position + Vector2(0, 32)
    current_hp = MAX_HP
    is_dead = false
    _sprite.modulate = Color.WHITE
    set_collision_layer_value(3, true)
    hp_changed.emit(current_hp, MAX_HP)
    player_respawned.emit()
    # TODO (PLANT-07): Apply -25% stored energy penalty here.
    _state_machine.travel("idle")
    _update_blend_position()
    _start_invincibility()
```

#### D7. Keep `take_damage()` as-is

The existing `take_damage()` uses a modulate tween for a quick red flash. **Do NOT change it.** The hurt animation state exists in the AnimationTree but is reserved for future use (stagger, knockback, heavy hits). Basic damage feedback remains the quick modulate flash.

#### D8. Keep `_dominant_direction()` as-is

No changes needed.

#### D9. Keep all other methods as-is

`heal()`, `set_camera_limits()`, `_unhandled_input()`, `_start_invincibility()` — no changes.

---

## Technical Standards

Apply these rules across all files:

- **Static typing everywhere:** `var x: int = 0`, `func foo(bar: String) -> void:`
- **Unique name references:** Use `%NodeName` syntax for `@onready var` node references. Mark nodes with `unique_name_in_owner = true` in the `.tscn`.
- **Godot 4 signal syntax:** `signal my_signal(arg: Type)`
- **No new comments or documentation** unless they were already present in the file. Exception: the existing `# TODO (PLANT-07)` comment must be preserved.
- **Do NOT delete** any existing logic (HP system, signals, debug keys, camera, invincibility, etc.). Only replace animation-specific code.
- **Prefer minimal edits** — if a line doesn't need to change, don't touch it.
- **BlendSpace2D blend mode** must be `BLEND_MODE_DISCRETE` (no interpolation between directional animations — this is pixel art).

---

## File Checklist

| Action | File | Reason |
|--------|------|--------|
| **Modify** | `player/scenes/player.tscn` | Remove `AnimatedSprite2D` + all `AtlasTexture`/`SpriteFrames` sub_resources. Add `Sprite2D`, `AnimationPlayer`, `AnimationTree` nodes. |
| **Create** | `player/scripts/player_animation_builder.gd` | Static utility: `build()` creates all AnimationPlayer animations from sprite sheet data; `build_tree()` creates AnimationTree state machine with BlendSpace2D per state. |
| **Modify** | `player/scripts/player_controller.gd` | Replace `AnimatedSprite2D` ref with `Sprite2D` + `AnimationPlayer` + `AnimationTree` refs. Replace `_play_animation()` with `_travel()` + `_update_blend_position()`. Update `_ready()`, `_die()`, `_respawn()`. |

---

## Acceptance Criteria

Run the project and confirm all of the following:

### Animation System

1. **Player renders.** The player sprite appears correctly using the new Sprite2D + AnimationPlayer + AnimationTree system. No visual difference from the old AnimatedSprite2D approach.
2. **Idle animation plays.** When standing still, the idle animation loops in the correct direction (down by default on scene load).
3. **Walk animation plays.** When moving, the walk animation loops. Changing direction smoothly switches to the correct directional variant (no flicker, no delay).
4. **Direction changes.** Moving in all 4 cardinal directions and diagonals correctly selects the appropriate directional animation (dominant axis determines direction).
5. **Idle ↔ Walk transitions.** Stopping movement transitions from walk to idle. Starting movement transitions from idle to walk. No animation glitches at transitions.
6. **No AnimatedSprite2D remnants.** The `player.tscn` file no longer contains `AnimatedSprite2D`, `SpriteFrames`, or `AtlasTexture` sub_resources.

### Existing Behavior Preserved

7. **Damage flash works.** Press F3 — player sprite flashes red briefly, HP decreases. Same visual as before.
8. **Death works.** When HP reaches 0, the death animation plays in the correct direction. Player becomes ghostly (low alpha), stops moving.
9. **Respawn works.** After 5 s, player teleports near Core, HP resets, idle animation plays, sprite restores.
10. **Invincibility blink works.** After respawn, sprite blinks for 3 s. During blinking, F3 does not reduce HP.
11. **Camera unchanged.** Camera zoom, limits, and smooth follow behave identically.
12. **HUD unchanged.** Player HP bar and Core HP bar update correctly.
13. **Game Over unchanged.** Core destruction still triggers game over screen.
14. **Debug keys work.** F1/F2 (Core damage/heal) and F3/F4 (Player damage/heal) all function.

### Future-Readiness

15. **Run animations exist.** The `run_down/left/right/up` animations exist in the AnimationPlayer and the `run` state exists in the AnimationTree state machine (not triggered yet, but available).
16. **Hurt animations exist.** The `hurt_down/left/right/up` animations exist and the `hurt` state exists in the AnimationTree (auto-transitions to idle when finished). Available for future use.
17. **Extensible.** Adding sword animations in the future only requires adding new entries to `PlayerAnimationBuilder.ANIM_DEFS` and new states/transitions to `build_tree()`.
