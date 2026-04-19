# PROMPT — Plant Grid Placement & Effect Radius Visualization

**Task IDs:** PLANT-03 (Plant Grid Placement System), PLANT-04 (Plant Effect Radius Visualization)
**GDD:** §7.4, §7.1, §10.2 | **Priority:** Critical / High
**Deps:** PLANT-01 ✅ (PlantBase + 2 starter plants), PLANT-CB ✅ (4 hybrid entities + seeds), CORE-02/UI-02 ✅ (Inventory), SAVE-01/02 ✅

---

## Goal

Build: PlantPlacementManager (Node2D in scene) that enables grid-based plant placement during DAY phase, a compact plant palette HUD for seed selection, ghost preview with grid snapping, effect radius circle overlay during placement mode, validation (garden bounds, max 8 plants, tile occupancy), seed consumption from inventory, and debug keys.

**NOT building:** WORLD-05 (garden expansion to 20×16), PLANT-05 (remaining base plants), MINI-01 (breeding minigame), plant removal/uprooting UI. Leave `TODO: <TASK-ID>` stubs for deferred work.

---

## 1. Design Decisions (resolving GDD §7.4 ambiguities)

**Phase restriction:** GDD says "Preparation Phase" (Afternoon). The current `DayNightCycle` only has `DAY` and `NIGHT` — no separate Afternoon sub-phase. **Plant placement is allowed during DAY only** (`DayNightCycle.is_day()`). When a proper sub-phase system is added, restrict to Afternoon. Leave `TODO: CORE-09` comment.

**Grid size:** 16×16 px per tile (matches `TILE_SIZE = 16` in `player_controller.gd` and GDD §7.4).

**Garden bounds:** GDD §10.2 says initial garden is 12×10 tiles. DianthusCore is at `(320, 240)` in meadow_edge. Garden is **centered on the core**, so:
- Origin (top-left): `(320 - 6*16, 240 - 5*16)` = `(224, 160)`
- Size: `12 * 16 = 192` wide, `10 * 16 = 160` tall
- Rect: `(224, 160)` to `(416, 320)`
- The core tile itself (tile containing 320,240 → grid cell 6,5 relative to garden origin) is **blocked** — cannot place plants on top of the core. `TODO: WORLD-05` for garden expansion.

**Max active plants:** 8 (GDD §7.4). Count all nodes in `"plants"` group that are not `is_destroyed`.

**Seed-based placement:** All plants are placed by consuming a seed item from inventory. This keeps flow consistent with the breeding system (which produces seeds).

**Base plant seeds:** Add `bougainvillea_seed` and `rafflesia_seed` to `ItemDatabase`. The player can obtain these from foraging (existing pickup system) or debug keys. The 4 hybrid seeds already exist.

**Placement input flow:**
1. Press **P** (`plant_mode_toggle` action) during DAY → enter placement mode. HUD shows plant palette.
2. Click a seed in the palette → select that plant type. Ghost preview + radius circle appear at cursor.
3. Mouse moves → ghost and radius follow, snapped to 16×16 grid.
4. **Left click** on a valid tile → plant is placed, seed consumed, exit selection (stay in placement mode for potential next plant).
5. **Right click** or **Escape** → cancel current selection. If no selection, exit placement mode entirely.
6. Press **P** again → exit placement mode.
7. Entering NIGHT phase → force-exit placement mode.

**Ghost preview:** A semi-transparent ColorRect (or modulated Sprite2D placeholder) at the cursor grid position. Green tint if placement is valid, red tint if invalid (occupied, out of bounds, at capacity).

**Tile occupancy:** Tracked via `Dictionary` mapping `Vector2i` grid coords → plant reference. Updated on place/destroy. Derived from existing plants on scene load.

---

## 2. New Seed Items in ItemDatabase

**Modify** `inventory/data/item_database.gd` — add 2 base plant seeds:

```gdscript
"bougainvillea_seed": { "display_name": "Bougainvillea Seed", "rarity": Rarity.COMMON, "max_stack": 99, "description": "Thorny plant seed. Deals damage to nearby enemies.", "icon": "res://assets/aseprite/icons/Bougainvillea Seed.png" },
"rafflesia_seed":     { "display_name": "Rafflesia Seed",     "rarity": Rarity.UNCOMMON, "max_stack": 20, "description": "Pungent bloom seed. Slows enemies in radius.", "icon": "res://assets/aseprite/icons/Rafflesia Seed.png" },
```

The 4 hybrid seeds (`bunga_api_seed`, `bunga_bayang_seed`, `melati_emas_seed`, `baja_kuning_seed`) already exist.

---

## 3. PlantPlacementManager

**New file:** `plants/placement/plant_placement_manager.gd` — extends Node2D

This node is instanced in the scene (meadow_edge.tscn). It handles input, rendering (ghost + radius + garden bounds), and placement logic. It uses `_draw()` for all visual overlays and `_unhandled_input()` for input.

### Constants

```gdscript
const GRID_SIZE: int = 16
const MAX_ACTIVE_PLANTS: int = 8
const DEFAULT_GARDEN_SIZE: Vector2i = Vector2i(12, 10)  # tiles

const SEED_TO_SCENE: Dictionary = {
    "bougainvillea_seed": "res://plants/entities/bougainvillea.tscn",
    "rafflesia_seed": "res://plants/entities/rafflesia.tscn",
    "bunga_api_seed": "res://plants/entities/bunga_api.tscn",
    "bunga_bayang_seed": "res://plants/entities/bunga_bayang.tscn",
    "melati_emas_seed": "res://plants/entities/melati_emas.tscn",
    "baja_kuning_seed": "res://plants/entities/baja_kuning.tscn",
}

# Radius colors per seed, semi-transparent. Derived from each plant's modulate color.
const SEED_RADIUS_COLORS: Dictionary = {
    "bougainvillea_seed": Color(0.85, 0.15, 0.45, 0.25),
    "rafflesia_seed": Color(0.65, 0.12, 0.15, 0.25),
    "bunga_api_seed": Color(1.0, 0.4, 0.1, 0.25),
    "bunga_bayang_seed": Color(0.3, 0.1, 0.4, 0.25),
    "melati_emas_seed": Color(1.0, 0.85, 0.3, 0.25),
    "baja_kuning_seed": Color(0.85, 0.7, 0.15, 0.25),
}

# Effect radius per seed, matching the plant's effect_radius value.
const SEED_EFFECT_RADIUS: Dictionary = {
    "bougainvillea_seed": 24.0,
    "rafflesia_seed": 40.0,
    "bunga_api_seed": 28.0,
    "bunga_bayang_seed": 36.0,
    "melati_emas_seed": 32.0,
    "baja_kuning_seed": 28.0,
}
```

### Signals

```gdscript
signal placement_mode_changed(active: bool)
signal plant_placed(seed_id: String, grid_pos: Vector2i)
signal placement_failed(reason: String)
```

### State

```gdscript
var is_placement_mode: bool = false
var selected_seed_id: String = ""
var _ghost_grid_pos: Vector2i = Vector2i.ZERO  # current hovered grid cell (garden-relative)
var _garden_origin: Vector2 = Vector2.ZERO     # world position of garden top-left
var _garden_size: Vector2i = DEFAULT_GARDEN_SIZE
var _occupied_tiles: Dictionary = {}            # Vector2i → PlantBase ref
var _core_tile: Vector2i = Vector2i(-1, -1)    # blocked tile under DianthusCore
var _palette_ui: Control = null                 # reference to PlantPaletteUI child
```

### Lifecycle

```gdscript
func _ready() -> void:
    # Derive garden origin from DianthusCore position.
    _update_garden_origin()
    # Build occupied tile map from existing plants.
    _rebuild_occupied_tiles()
    # Listen for phase changes to force-exit placement mode at night.
    DayNightCycle.phase_changed.connect(_on_phase_changed)
    # Create palette UI child (CanvasLayer for screen-space rendering).
    _create_palette_ui()
    # Start hidden.
    set_process(false)
```

### Core Methods

- **`toggle_placement_mode() -> void`**
  - If `is_placement_mode`: call `exit_placement_mode()`.
  - Else: check `DayNightCycle.is_day()`. If night → emit `placement_failed("Cannot place plants at night.")`, return. Else set `is_placement_mode = true`, show palette, emit signal.

- **`exit_placement_mode() -> void`**
  - `is_placement_mode = false`, `selected_seed_id = ""`, hide palette, `queue_redraw()`, emit signal.

- **`select_seed(seed_id: String) -> void`**
  - Validate seed_id is in `SEED_TO_SCENE` and player has it in inventory. Set `selected_seed_id`.

- **`_snap_to_grid(world_pos: Vector2) -> Vector2i`**
  - Convert world position to garden-relative grid coordinates.
  - `var local: Vector2 = world_pos - _garden_origin`
  - `return Vector2i(int(local.x) / GRID_SIZE, int(local.y) / GRID_SIZE)`

- **`_grid_to_world(grid_pos: Vector2i) -> Vector2`**
  - `return _garden_origin + Vector2(grid_pos.x * GRID_SIZE + GRID_SIZE / 2, grid_pos.y * GRID_SIZE + GRID_SIZE / 2)`
  - Returns center of tile (plants are centered on their tile).

- **`_is_within_garden(grid_pos: Vector2i) -> bool`**
  - `return grid_pos.x >= 0 and grid_pos.x < _garden_size.x and grid_pos.y >= 0 and grid_pos.y < _garden_size.y`

- **`_is_tile_occupied(grid_pos: Vector2i) -> bool`**
  - Check `_occupied_tiles.has(grid_pos)` or `grid_pos == _core_tile`.

- **`_get_active_plant_count() -> int`**
  - `return get_tree().get_nodes_in_group("plants").filter(func(p): return p is PlantBase and not p.is_destroyed).size()`

- **`_can_place() -> bool`**
  - All of: `selected_seed_id != ""`, `DayNightCycle.is_day()`, `_is_within_garden(_ghost_grid_pos)`, `!_is_tile_occupied(_ghost_grid_pos)`, `_get_active_plant_count() < MAX_ACTIVE_PLANTS`, `InventoryManager.has_item(selected_seed_id)`.

- **`_place_plant() -> void`**
  1. Guard: `if !_can_place(): return`
  2. Load scene from `SEED_TO_SCENE[selected_seed_id]`.
  3. Instantiate, set `global_position = _grid_to_world(_ghost_grid_pos)`.
  4. Add to `get_tree().current_scene`.
  5. Register in `_occupied_tiles[_ghost_grid_pos] = plant`.
  6. Connect `plant.plant_destroyed` → `_on_plant_destroyed` (to clear tile).
  7. `InventoryManager.remove_item(selected_seed_id, 1)`.
  8. Emit `plant_placed`.
  9. If `!InventoryManager.has_item(selected_seed_id)`: clear `selected_seed_id` (ran out of that seed).
  10. Refresh palette UI.
  11. `queue_redraw()`.

- **`_on_plant_destroyed(plant: PlantBase) -> void`**
  - Find and remove the plant from `_occupied_tiles`. `queue_redraw()`.

- **`_on_phase_changed(_phase: String) -> void`**
  - If `DayNightCycle.is_night()` and `is_placement_mode`: call `exit_placement_mode()`.

- **`_update_garden_origin() -> void`**
  - If `GameManager.dianthus_core` is valid: center garden on core.
  - `var core_pos: Vector2 = GameManager.dianthus_core.global_position`
  - `_garden_origin = core_pos - Vector2(_garden_size.x * GRID_SIZE / 2, _garden_size.y * GRID_SIZE / 2)`
  - Calculate `_core_tile` = `_snap_to_grid(core_pos)`.
  - Fallback if core not available: `_garden_origin = Vector2(224, 160)` (hardcoded default for meadow_edge).

- **`_rebuild_occupied_tiles() -> void`**
  - Clear `_occupied_tiles`.
  - For each plant in `"plants"` group that is `PlantBase` and not `is_destroyed`:
    - `_occupied_tiles[_snap_to_grid(plant.global_position)] = plant`
    - Connect `plant.plant_destroyed` → `_on_plant_destroyed` if not already connected.

### Input

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("plant_mode_toggle"):
        toggle_placement_mode()
        get_viewport().set_input_as_handled()
        return

    if not is_placement_mode:
        return

    if event is InputEventMouseMotion:
        _ghost_grid_pos = _snap_to_grid(get_global_mouse_position())
        queue_redraw()

    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if selected_seed_id != "" and _can_place():
                _place_plant()
                get_viewport().set_input_as_handled()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            if selected_seed_id != "":
                selected_seed_id = ""
                queue_redraw()
            else:
                exit_placement_mode()
            get_viewport().set_input_as_handled()

    elif event.is_action_pressed("ui_cancel"):  # Escape
        if selected_seed_id != "":
            selected_seed_id = ""
            queue_redraw()
        else:
            exit_placement_mode()
        get_viewport().set_input_as_handled()
```

### Drawing (PLANT-04 — Radius Visualization)

```gdscript
func _draw() -> void:
    if not is_placement_mode:
        return

    # 1. Garden bounds outline (dashed white rectangle).
    var garden_rect: Rect2 = Rect2(
        _garden_origin - global_position,
        Vector2(_garden_size.x * GRID_SIZE, _garden_size.y * GRID_SIZE)
    )
    draw_rect(garden_rect, Color(1, 1, 1, 0.3), false, 1.0)

    # 2. Grid lines (subtle).
    for x in range(_garden_size.x + 1):
        var from_pt: Vector2 = garden_rect.position + Vector2(x * GRID_SIZE, 0)
        var to_pt: Vector2 = from_pt + Vector2(0, garden_rect.size.y)
        draw_line(from_pt, to_pt, Color(1, 1, 1, 0.08), 1.0)
    for y in range(_garden_size.y + 1):
        var from_pt: Vector2 = garden_rect.position + Vector2(0, y * GRID_SIZE)
        var to_pt: Vector2 = from_pt + Vector2(garden_rect.size.x, 0)
        draw_line(from_pt, to_pt, Color(1, 1, 1, 0.08), 1.0)

    # 3. Occupied tiles — small red squares.
    for tile: Vector2i in _occupied_tiles:
        var tile_world: Vector2 = _grid_to_world(tile) - global_position
        draw_rect(
            Rect2(tile_world - Vector2(GRID_SIZE / 2, GRID_SIZE / 2), Vector2(GRID_SIZE, GRID_SIZE)),
            Color(1, 0.3, 0.3, 0.15), true
        )

    # 4. Core tile — blocked indicator.
    if _core_tile != Vector2i(-1, -1):
        var core_world: Vector2 = _grid_to_world(_core_tile) - global_position
        draw_rect(
            Rect2(core_world - Vector2(GRID_SIZE / 2, GRID_SIZE / 2), Vector2(GRID_SIZE, GRID_SIZE)),
            Color(1, 0.8, 0.9, 0.2), true
        )

    # 5. Existing plant radius circles (dim).
    for tile: Vector2i in _occupied_tiles:
        var plant: PlantBase = _occupied_tiles[tile]
        if is_instance_valid(plant) and not plant.is_destroyed:
            var center: Vector2 = plant.global_position - global_position
            draw_circle(center, plant.effect_radius, Color(0.6, 0.8, 1.0, 0.1))
            draw_arc(center, plant.effect_radius, 0, TAU, 64, Color(0.6, 0.8, 1.0, 0.2), 1.0)

    # 6. Ghost preview + radius (only if seed selected).
    if selected_seed_id == "":
        return

    var ghost_world: Vector2 = _grid_to_world(_ghost_grid_pos) - global_position
    var can_place: bool = _can_place()
    var ghost_color: Color = Color(0.3, 1.0, 0.3, 0.5) if can_place else Color(1.0, 0.3, 0.3, 0.5)

    # Ghost tile highlight.
    draw_rect(
        Rect2(ghost_world - Vector2(GRID_SIZE / 2, GRID_SIZE / 2), Vector2(GRID_SIZE, GRID_SIZE)),
        ghost_color, true
    )

    # Effect radius circle.
    var radius: float = SEED_EFFECT_RADIUS.get(selected_seed_id, 24.0)
    var radius_color: Color = SEED_RADIUS_COLORS.get(selected_seed_id, Color(0.5, 0.5, 1.0, 0.25))
    if not can_place:
        radius_color = Color(1.0, 0.2, 0.2, 0.15)
    draw_circle(ghost_world, radius, radius_color)
    draw_arc(ghost_world, radius, 0, TAU, 64, Color(radius_color, 0.6), 1.0)
```

**Note on `_draw()`:** All positions are relative to the Node2D's own `global_position`. Since PlantPlacementManager is a Node2D at (0,0) in the scene, `global_position` is `Vector2.ZERO`, so `- global_position` is typically a no-op. However, it's good practice for correctness if the node is ever repositioned.

---

## 4. Plant Palette UI

**New file:** `plants/placement/plant_palette_ui.gd` — extends CanvasLayer

A compact CanvasLayer (layer=80, below inventory at 90) that shows a horizontal bar of available seeds at the bottom of the screen. Created and managed by `PlantPlacementManager`.

### Layout (640×360 viewport)

```
PlantPaletteUI (CanvasLayer layer=80, visible=false)
  +-- PalettePanel (PanelContainer, anchored bottom-center)
      +-- MarginContainer (margins 4)
          +-- VBoxContainer
              +-- TitleLabel ("PLANT", font_size 6, horizontal_alignment=CENTER)
              +-- HBoxContainer (gap 4)
                  +-- [SeedSlot × N] (PanelContainer 32×32 each)
                      +-- VBoxContainer
                          +-- ColorRect (16×16, plant color preview)
                          +-- CountLabel (font_size 6, centered)
              +-- HintLabel ("[P] Close  [RMB] Cancel", font_size 6, dim color)
```

### Behavior

- Built dynamically in `refresh()`. Iterates `SEED_TO_SCENE` keys, checks `InventoryManager.get_total_count(seed_id)`.
- Only shows seeds the player owns (count > 0).
- Each slot shows a colored square (matching `SEED_RADIUS_COLORS` but at full alpha) and count number.
- Clicking a slot calls `PlantPlacementManager.select_seed(seed_id)`.
- Selected slot gets a bright border highlight (e.g., gold `Color(1, 0.85, 0.3)`).
- Connects `InventoryManager.inventory_changed` → `refresh()`.
- `show_palette()` / `hide_palette()` toggle visibility.

### Seed Display Name

Use `ItemDatabase.get_display_name(seed_id)` for tooltip hover text on each slot (optional — can use a simple Label that appears on hover). For now, just show the colored square and count.

---

## 5. project.godot Changes

Add input action:

```
plant_mode_toggle — Key P (physical_keycode=80)
```

**No new autoload needed.** PlantPlacementManager is a scene-level Node2D, not an autoload.

---

## 6. Save/Load Integration

**No schema bump required.** The existing save system (`SCHEMA_VERSION = 5`) already handles:
- Saving plants: `_gather_state()` iterates `"plants"` group, saves type + position + HP.
- Loading plants: `_apply_state()` instantiates plants from `PLANT_TYPE_TO_SCENE`, restores position + HP.

The PlantPlacementManager needs to **rebuild its `_occupied_tiles`** after load:
- In `_ready()`, call `_rebuild_occupied_tiles()` (which reads from the `"plants"` group).
- Also connect `SaveManager.load_completed` → `_on_load_completed` which calls `_rebuild_occupied_tiles()` and `_update_garden_origin()`.

---

## 7. Player Controller Changes

**Modify** `player/scripts/player_controller.gd`:

### Debug Keys

Add/update in `_unhandled_input()`:

| Key | Action |
|-----|--------|
| Shift+P (or F14) | Add 3× bougainvillea_seed + 2× rafflesia_seed + 1× of each hybrid seed to inventory |

Update the existing `Shift+Insert` block to also include:
```gdscript
InventoryManager.add_item("bougainvillea_seed", 3)
InventoryManager.add_item("rafflesia_seed", 2)
```

**Remove or keep F10 debug cycle** — F10 still useful for direct placement without seeds (bypass inventory). Keep it but add a print note that P key is the proper placement mode.

---

## 8. Meadow Edge Scene Changes

**Modify** `world/zones/meadow_edge/meadow_edge.tscn`:

1. Add ext_resource for `plant_placement_manager.gd` (or a `.tscn` if we make one).
2. Instance `PlantPlacementManager` as a child of MeadowEdge (Node2D at position 0,0).
   - Can be a raw Node2D with the script attached, or create a minimal .tscn.

**Approach:** Create a `.tscn` file for cleanliness:

**New file:** `plants/placement/plant_placement_manager.tscn`
```
PlantPlacementManager (Node2D, script=plant_placement_manager.gd)
```

Then instance it in meadow_edge.tscn.

---

## Existing Code — Files to READ Before Implementing

| File | Why |
|------|-----|
| `plants/entities/plant_base.gd` | Base class — `effect_radius`, `is_destroyed`, `plant_destroyed` signal, `"plants"` group |
| `plants/entities/bougainvillea.gd` | Reference: effect_radius=24.0, modulate color |
| `plants/entities/rafflesia.gd` | Reference: effect_radius=40.0 |
| `plants/entities/bunga_api.gd` | Reference: effect_radius=28.0 |
| `plants/entities/bunga_bayang.gd` | Reference: effect_radius=36.0 |
| `plants/entities/melati_emas.gd` | Reference: effect_radius=32.0 |
| `plants/entities/baja_kuning.gd` | Reference: effect_radius=28.0 |
| `inventory/data/item_database.gd` | Add base plant seeds; 4 hybrid seeds already exist |
| `inventory/scripts/inventory_manager.gd` | `has_item/remove_item/get_total_count/inventory_changed` |
| `core/day_night/day_night_cycle.gd` | `is_day()/is_night()/phase_changed` signal |
| `core/dianthus_core/dianthus_core.gd` | Core reference for garden center |
| `shared/autoloads/game_manager.gd` | `dianthus_core` ref, `player` ref |
| `save/scripts/save_manager.gd` | `PLANT_TYPE_TO_SCENE`, garden save/load, `load_completed` signal |
| `player/scripts/player_controller.gd` | `TILE_SIZE=16`, debug keys, F10 cycle |
| `shared/collision_layers.gd` | Layer constants |
| `project.godot` | Input actions, autoloads |
| `world/zones/meadow_edge/meadow_edge.tscn` | Scene layout — Core at (320,240), Player at (160,120) |

## Files to CREATE

| File | Description |
|------|-------------|
| `plants/placement/plant_placement_manager.gd` | Node2D — placement logic, grid snap, validation, input, _draw() overlays |
| `plants/placement/plant_placement_manager.tscn` | Minimal scene wrapping the script |
| `plants/placement/plant_palette_ui.gd` | CanvasLayer — seed selection HUD bar |

## Files to MODIFY

| File | Change |
|------|--------|
| `inventory/data/item_database.gd` | Add `bougainvillea_seed` and `rafflesia_seed` items |
| `player/scripts/player_controller.gd` | Debug key: Shift+Insert adds base plant seeds; print note on F10 about P key |
| `project.godot` | Add `plant_mode_toggle` input action (P key) |
| `world/zones/meadow_edge/meadow_edge.tscn` | Instance PlantPlacementManager |
| `docs/design/PERSON_TASKS.md` | Mark PLANT-03 and PLANT-04 done; add P and Shift+Insert update to debug key table |

---

## Constraints

1. **No new autoloads** — PlantPlacementManager is a scene-level Node2D, not a singleton.
2. **No new addons** — pure GDScript, no plugins.
3. **Pixel-art friendly** — grid is 16×16, UI sizes multiples of 8, font_size 6-8 for labels.
4. **640×360 viewport** — palette bar must fit at bottom without overlapping HUD (HUD is top-left).
5. **Save compat** — no schema bump needed. Existing v5 garden save/load handles placed plants. PlantPlacementManager rebuilds its state from live scene data.
6. **No garden expansion** — garden is fixed 12×10 tiles. `TODO: WORLD-05` for expansion logic.
7. **No plant uprooting** — plants can only be destroyed by enemies. `TODO: UI-09` for a remove/uproot UI.
8. **No plant upgrade/quality tiers** — all plants are Biasa quality. `TODO: MINI-01` for quality.
9. **Core tile blocked** — the tile containing DianthusCore cannot have a plant placed on it.
10. Leave `TODO: <TASK-ID>` stubs for deferred work:
    - `TODO: CORE-09` — restrict placement to Afternoon sub-phase when sub-phases exist
    - `TODO: WORLD-05` — garden expansion (20×16), adjustable `_garden_size`
    - `TODO: UI-09` — plant removal/uprooting mechanic
    - `TODO: PLANT-05` — add seeds for remaining base plants as they are implemented

---

## Acceptance Criteria

- [ ] Pressing P during DAY enters placement mode; pressing P at NIGHT shows error message
- [ ] Plant palette HUD appears at bottom, showing seeds the player owns with counts
- [ ] Clicking a seed in palette selects it; ghost preview + radius circle appear at cursor
- [ ] Ghost snaps to 16×16 grid, confined to garden bounds (12×10 tiles centered on core)
- [ ] Ghost is green on valid tiles, red on invalid (occupied, out of bounds, at max capacity)
- [ ] Left click on valid tile: plant instantiated at grid position, seed consumed from inventory
- [ ] Placed plant appears in `"plants"` group and is saved/loaded correctly via existing save system
- [ ] Max 8 plants enforced — placement blocked when limit reached (red ghost + message)
- [ ] Core tile blocked — cannot place on the DianthusCore's tile
- [ ] Tile occupancy tracked — cannot stack two plants on the same tile
- [ ] Plant destroyed by enemies → tile freed for future placement
- [ ] Effect radius circle drawn per selected seed (matching plant's `effect_radius` value)
- [ ] Existing placed plants show dim radius circles while in placement mode
- [ ] Garden bounds rectangle visible while in placement mode (white outline)
- [ ] Right click / Escape cancels selection; second right click / P exits placement mode
- [ ] Night phase auto-exits placement mode
- [ ] Palette refreshes when inventory changes (seed used up → slot disappears)
- [ ] Save/Load round-trip: placed plants persist, occupancy map rebuilt on load
- [ ] Debug key (Shift+Insert) grants test seeds
- [ ] F10 debug cycle still works independently
- [ ] No console errors on startup, placement, save, load

---

## Testing Checklist

```
1.  Launch game. Confirm it is DAY phase.
2.  Press P — placement mode activates. Palette bar appears at bottom (empty — no seeds yet).
3.  Shift+Insert — adds base plant seeds + hybrid seeds to inventory.
4.  Palette now shows available seeds with counts.
5.  Click "Bougainvillea Seed" in palette — ghost green square + radius circle follow cursor.
6.  Move cursor outside garden bounds — ghost turns red.
7.  Move cursor to a valid tile inside garden — ghost turns green.
8.  Left click — Bougainvillea planted at grid position. Seed count decremented in palette.
9.  Move cursor to the same tile — ghost is red (occupied).
10. Place 7 more plants (mix of types). All snap to grid correctly.
11. Try to place a 9th plant — ghost always red, "Max plants reached" indication.
12. Move cursor to DianthusCore tile (center of garden) — ghost is red.
13. Right click — cancel seed selection. Right click again — exit placement mode.
14. Radius circles disappear. Garden outline disappears.
15. Press P during NIGHT (skip with F7) — placement mode does not activate, warning printed.
16. Skip back to DAY (F7). Press P — works again.
17. F11 to save. F12 to load. Plants still in correct grid positions. Press P — occupied tiles shown correctly.
18. Kill a plant (enemy damage or F1 debug if applicable) — tile becomes available for new placement.
19. Press I — inventory shows remaining seeds with correct counts.
20. F10 debug still works — places plants at mouse pos without grid snap (legacy debug).
21. No console errors throughout.
```
