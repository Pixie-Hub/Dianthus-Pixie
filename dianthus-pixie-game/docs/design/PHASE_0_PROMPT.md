# Phase 0 — Foundation: Complete Implementation Prompt

## Context

| Key | Value |
|-----|-------|
| **Project** | Dianthus Pixie — 2D survival crafting action game |
| **Engine** | Godot 4.6 (Forward Plus) |
| **Viewport** | 640×360, stretch mode `canvas_items`, integer scale |
| **Art** | 2D Pixel Art — 32×32 tiles, 64×64 character sprite frames |
| **Repo root** | `c:\Users\Indra\Programming\GIGA\Dianthus Pixie\dianthus-pixie-game` |

---

## Current State — What Already Exists

> **Do NOT recreate these from scratch.** Only modify or extend as needed.

### 1. Project Scaffold (FOUND-01 — partially done)

- `project.godot` configured: name, main scene, viewport, stretch, physics layers, autoloads.
- `.gitignore`, `.editorconfig`, and full folder structure are in place.
- Three autoloads already registered: `GameManager`, `DayNightCycle`, `SceneTransition`.

### 2. `GameManager` — `shared/autoloads/game_manager.gd`

- `GameState` enum: `EXPLORATION`, `PREPARATION`, `DEFENSE`, `GAME_OVER`, `TRANSITIONING`.
- `set_state()` method and `game_state_changed` signal.

### 3. `DayNightCycle` — `core/day_night/day_night_cycle.gd`

- `Phase` enum: `MORNING`, `AFTERNOON`, `NIGHT`.
- Phase durations: 120 s / 60 s / 90 s.
- Phase tint colors defined as constants.
- `phase_changed` signal emitted on each phase advance.
- `register_canvas_modulate()` for per-zone color tinting.
- Tween-based smooth tint transitions (3 s).
- Day counter increments each night cycle.
- Utility methods: `get_phase_name()`, `get_time_remaining()`, `get_phase_progress()`, `is_night()`.

### 4. `SceneTransition` — `core/transitions/scene_transition.gd`

- `CanvasLayer` (layer 128) with a `ColorRect` overlay.
- `transition_to(target_scene: String)` fades out → changes scene → fades in (0.5 s each).
- Blocked during `DEFENSE` state (night) — returns early if night.
- Non-interruptible via `_busy` flag.

### 5. Player Scene — `player/scenes/player.tscn`

- `CharacterBody2D` on collision layer 3 (player), mask layer 2 (blocked).
- `AnimatedSprite2D` with `SpriteFrames` containing 8 pre-configured animations:
  - `idle_down`, `idle_up`, `idle_left`, `idle_right`
  - `walk_down`, `walk_up`, `walk_left`, `walk_right`
  - All frames from 64×64 atlas textures (Unarmed_Idle and Unarmed_Walk spritesheets).
- `CollisionShape2D` — `CapsuleShape2D` (radius 5, height 22).
- `Camera2D` with `position_smoothing_enabled = true`.
- Script attached: `player/scripts/player_controller.gd` — **currently EMPTY (0 bytes).**

### 6. Meadow Edge Zone — `world/zones/meadow_edge/`

- **`meadow_edge.tscn`:** `Node2D` with:
  - `CanvasModulate` (morning color tint).
  - `TileMapLayer` with inline `TileSet` — two `TileSetAtlasSource` entries (Grass terrain 0, Hills terrain 1) from the Sprout Lands pack. **Tiles are 16×16 px native.**
  - Player instanced at position `(160, 120)`.
  - `DebugOverlay` CanvasLayer containing `PhaseLabel`, `DayLabel`, `TimerLabel`.
- **`meadow_edge.gd`:** Registers `CanvasModulate`, connects `phase_changed`, updates debug labels, calls `_player.set_camera_limits()` — **but `player_controller.gd` is empty, so `set_camera_limits()` does not exist yet.**
  - `ZONE_WIDTH = 40`, `ZONE_HEIGHT = 30`, `TILE_SIZE = 16`.

### 7. Sprite Assets — `player/sprites/PNG/`

| Category | Available Directions |
|----------|----------------------|
| `Unarmed_Idle` | down, up, left, right |
| `Unarmed_Walk` | down, up, left, right |
| `Unarmed_Run` | down, up, left, right |
| `Unarmed_Hurt` | down, up, left, right |
| `Unarmed_Death` | down, up, left, right |
| `Sword_Idle` | down, up, left, right |
| `Sword_Walk` | down, up, left, right |
| `Sword_Run` | down, up, left, right |
| `Sword_Attack` | down, up, left, right |
| `Sword_Walk_Attack` | down, up, left, right |
| `Sword_Run_Attack` | down, up, left, right |
| `Sword_Hurt` | down, up, left, right |
| `Sword_Death` | down, up, left, right |

### 8. Tileset Assets — `world/tilesets/Sprout Lands - Sprites - Basic pack/`

All tiles are **16×16 px native**: Grass, Hills, Tilled Dirt variants, Water, Fences, Doors, Wooden House.

---

## Tasks To Complete

Work in dependency order.

---

### FOUND-01 — Project Scaffold ✅ Verify Only

Confirm the project opens error-free in Godot 4.6 and all three autoloads load without console errors. No code changes expected unless something is broken.

---

### FOUND-02 — Tilemap & Tileset Setup

> **GDD §18:** 32×32 tiles. The Sprout Lands pack uses 16×16 px natively — use 16×16 as tile size throughout to avoid scaling artifacts.

**What to do:**

1. Create a standalone TileSet resource at `world/tilesets/meadow_tileset.tres` so it can be reused across zones.
   - Because TileSet `.tres` files with atlas sources are complex to hand-write, create this via a GDScript `EditorScript` or directly in the Godot editor, then commit the result.
2. Configure physics on the TileSet:
   - **Grass** (terrain 0) → physics layer 1 (walkable) — no collision body needed, player walks freely.
   - **Hills** (terrain 1) → physics layer 2 (blocked) — add physics collision polygons so the player cannot walk through.
3. Update `meadow_edge.tscn` to reference the external `meadow_tileset.tres` instead of the inline TileSet.
4. Confirm `TILE_SIZE = 16` stays consistent in `meadow_edge.gd` (it already is).
5. **Acceptance:** At least one ground tile and one hill tile render; player cannot walk into hill tiles.

---

### FOUND-03 — Player Controller (Move + Collide)

**Implement `player/scripts/player_controller.gd` from scratch.**

#### Movement

```gdscript
extends CharacterBody2D

const TILE_SIZE: int = 16
const SPEED: float = TILE_SIZE * 5.0  # 80 px/s = 5 tiles/sec
```

- Read 8-directional input using Godot input actions:
  - `move_up`, `move_down`, `move_left`, `move_right`
- Normalize the direction vector before multiplying by `SPEED` to prevent faster diagonal movement.
- Apply movement with `move_and_slide()`.

#### Input Actions to Add in `project.godot`

Add the following under an `[input]` section:

| Action | Keys |
|--------|------|
| `move_up` | W, Up Arrow |
| `move_down` | S, Down Arrow |
| `move_left` | A, Left Arrow |
| `move_right` | D, Right Arrow |

#### Animation State Machine

- Track `last_direction: Vector2` — updated whenever the player moves, defaults to `Vector2.DOWN`.
- **Moving:** play the matching `walk_{direction}` animation based on the dominant axis or last pressed direction.
- **Idle:** play the matching `idle_{direction}` animation using `last_direction`.
- Map direction to animation name:
  - `Vector2.UP` → `"_up"`, `Vector2.DOWN` → `"_down"`, `Vector2.LEFT` → `"_left"`, `Vector2.RIGHT` → `"_right"`
- Reference `AnimatedSprite2D` via unique name: `%AnimatedSprite2D`.

#### Camera Limits

Implement this public method (called by `meadow_edge.gd`):

```gdscript
func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
    %Camera2D.limit_left = left
    %Camera2D.limit_top = top
    %Camera2D.limit_right = right
    %Camera2D.limit_bottom = bottom
```

#### Acceptance Criteria

- Player moves at ~80 px/s in all 8 directions.
- Diagonal movement is normalized (not faster than cardinal).
- `CollisionShape2D` prevents wall penetration (Hills tiles).
- Idle and walk animations transition correctly, facing last moved direction on stop.

---

### FOUND-04 — Camera System

**Enhance the `Camera2D` already in `player.tscn`.**

- `position_smoothing_enabled` is already `true` — confirm `position_smoothing_speed` is set to a suitable value (5.0–8.0).
- The `set_camera_limits()` method in FOUND-03 handles clamping via `Camera2D.limit_*` properties.
- Verify there is no dead-zone bleed — the camera should not scroll past zone boundaries.
- Reference via unique name `%Camera2D` in the player controller.

**No new nodes required.** Only properties may need adjustment.

---

### FOUND-05 — Day-Night Cycle Timer ✅ Verify & Confirm

Already fully implemented. Verify end-to-end:

- [ ] `phase_changed` signal fires for Morning → Afternoon → Night → Morning.
- [ ] `CanvasModulate` tint transitions smoothly over 3 s between each phase.
- [ ] Debug overlay in `meadow_edge.tscn` updates `PhaseLabel`, `DayLabel`, and `TimerLabel` in real time.
- [ ] `DayNightCycle.day_count` increments after each full Night → Morning cycle.

No code changes expected unless a bug is found.

---

### FOUND-06 — Scene Transition System — Enhance

Already implemented. One acceptance criterion is **not yet met:**

> *"Player position and inventory persist across zone transitions."*

**What to add:**

1. **In `shared/autoloads/game_manager.gd`:** Add a `player_data` dictionary to store cross-zone persistence data:

```gdscript
var player_data: Dictionary = {
    "position": Vector2.ZERO,
    "last_zone": "",
    "inventory": {},  # populated in Phase 1
}
```

2. **In `core/transitions/scene_transition.gd`:** Before `change_scene_to_file`, save the player's current position into `GameManager.player_data`:

```gdscript
# Save player position before unloading the scene
var player = get_tree().get_first_node_in_group("player")
if is_instance_valid(player):
    GameManager.player_data["position"] = player.global_position
    GameManager.player_data["last_zone"] = get_tree().current_scene.scene_file_path
```

3. **In each zone scene's `_ready()`:** After the player is ready, restore position if `GameManager.player_data["last_zone"]` is non-empty and differs from the current zone. For now, add this to `meadow_edge.gd`.

4. **Add the player to the `"player"` group** in `player.tscn` (set the `Groups` property on the root `CharacterBody2D` node).

> Inventory persistence implementation is deferred to Phase 1 (CORE-02). The dictionary key is stubbed here only.

---

## Technical Standards

Apply these rules across all files:

- **Static typing everywhere:** `var x: int = 0`, `func foo(bar: String) -> void:`
- **Unique name references:** Use `%NodeName` syntax for `@onready var` node references.
- **Godot 4 signal syntax:** `signal my_signal(arg: Type)`
- **No new comments or documentation** unless they were already present in the file.
- **No deletion** of existing sprite/animation data in `.tscn` files.
- **Prefer minimal edits** — do not rewrite files that already work correctly.

---

## File Checklist

| Action | File | Reason |
|--------|------|--------|
| **Verify** | `project.godot` | Confirm opens error-free |
| **Modify** | `project.godot` | Add `[input]` section with movement actions |
| **Create** | `world/tilesets/meadow_tileset.tres` | External reusable TileSet |
| **Modify** | `world/zones/meadow_edge/meadow_edge.tscn` | Reference external tileset, add Hills physics |
| **Implement** | `player/scripts/player_controller.gd` | Full player controller (currently 0 bytes) |
| **Modify** | `shared/autoloads/game_manager.gd` | Add `player_data` dictionary |
| **Modify** | `core/transitions/scene_transition.gd` | Save/restore player data on transition |
| **Modify** | `player/scenes/player.tscn` | Add player to `"player"` group |
| **Verify** | `core/day_night/day_night_cycle.gd` | No changes expected |
| **Verify** | `world/zones/meadow_edge/meadow_edge.gd` | Minor updates if camera/tile setup changes |

---

## Acceptance Criteria — Phase 0 Complete

Run the project and confirm all of the following:

1. **No errors.** Project opens in Godot 4.6 with zero console errors or warnings on startup.
2. **Tilemap renders.** Meadow Edge displays grass ground tiles and hill wall tiles correctly.
3. **Collision works.** Player cannot walk into or through hill tiles.
4. **Movement.** Player moves in 8 directions at ~80 px/s; diagonal speed is normalized.
5. **Animations.** Walk animations play while moving; idle animations play when stopped, facing last moved direction.
6. **Camera.** Smoothly follows the player; does not scroll past zone boundaries (0 to 640 px wide, 0 to 480 px tall).
7. **Day-Night cycle.** Phases advance Morning (120 s) → Afternoon (60 s) → Night (90 s) → Morning. Tint transitions smoothly. Debug labels update in real time.
8. **Scene transition.** Fade works without flicker; blocked at night; player position stored in `GameManager.player_data` before scene unloads.
9. **Task breakdown updated.** Mark FOUND-01 through FOUND-06 as `Done` in `docs/design/TASK_BREAKDOWN.md` upon completion.
