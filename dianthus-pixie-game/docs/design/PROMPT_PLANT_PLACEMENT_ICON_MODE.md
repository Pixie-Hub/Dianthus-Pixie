# PROMPT - PLANT-03/04: Plant Placement Icon Mode Redesign

**Task ID:** PLANT-03 / PLANT-04 polish  
**Category:** Plant & Crafting / UI/HUD  
**Priority:** Medium  
**Dependencies:** PLANT-03, PLANT-04, PLANT-05, UI-04  
**Current status:** Existing placement mode works, but the palette communicates plant choice only through a color swatch.

---

## Goal

Redesign the plant placement palette so each selectable seed slot shows the actual plant icon/sprite instead of only a color swatch. The player should immediately understand which plant they are about to place before clicking on the garden grid.

Keep the existing placement behavior intact: `P` opens placement mode during day, the player selects a seed and exact quality tier, left-click places the selected plant, right-click cancels selection or exits, the ghost/radius preview still updates, and inventory consumes the exact selected quality tier.

---

## Scope

### In Scope

1. Replace the current seed `ColorRect` swatch in the placement palette with a plant visual.
2. Use existing plant sprite/icon data rather than creating new art.
3. Preserve quality-aware slots: Common, Superior, and Masterwork stacks of the same seed remain separate selectable slots.
4. Preserve count and quality visibility on each slot.
5. Improve the selected-slot state so the chosen plant + quality is obvious at a glance.
6. Keep the effect-radius color logic for the world preview; only the palette slot visual should stop relying on the swatch as the primary identifier.
7. Follow scene-first UI rules where practical by moving static palette/slot structure into `.tscn` resources instead of expanding programmatic UI construction.

### Out of Scope

- New plant art generation.
- Changing placement rules, grid size, garden expansion rules, plant cap, day/night restrictions, or input bindings.
- Changing inventory stacking or quality-tier save data.
- Redesigning the Codex, Cross-Breeding screen, or plant gameplay effects.
- Implementing plant removal/uprooting. Leave the existing `TODO: UI-09` stub untouched unless directly required.

---

## Existing Architecture Reference

### Placement Manager

- `plants/placement/plant_placement_manager.gd`
  - Owns placement mode, selected seed id, selected seed quality, grid snapping, ghost/radius drawing, inventory consumption, Codex discovery, and plant instancing.
  - Creates the palette with:

```gdscript
var palette: Node = preload("res://plants/placement/plant_palette_ui.gd").new()
```

  - Important existing state to preserve:
    - `selected_seed_id: String`
    - `selected_seed_quality: int`
    - `SEED_TO_SCENE`
    - `SEED_RADIUS_COLORS`
    - `SEED_EFFECT_RADIUS`
    - `plant_placed(seed_id, grid_pos)`

### Current Palette

- `plants/placement/plant_palette_ui.gd`
  - Extends `CanvasLayer`.
  - Builds layout and slot nodes dynamically in `_build_layout()` and `_add_seed_slot()`.
  - Currently shows the plant using:

```gdscript
var color_rect: ColorRect = ColorRect.new()
color_rect.custom_minimum_size = Vector2(16, 12)
color_rect.color = seed_color
```

  - Keeps critical behavior:
    - `setup(manager)`
    - `refresh()`
    - `show_palette()`
    - `hide_palette()`
    - Slot click calls `_manager.select_seed(seed_id, quality)`.

### Existing Icon / Sprite Data

Prefer these existing sources, in this order:

1. `ui/codex/plant_registry.gd`
   - `PlantRegistry.get_sprite_path(plant_id)` returns paths such as:
     - `res://plants/sprites/Bougainvillea.png`
     - `res://plants/sprites/Rafflesia.png`
     - `res://plants/sprites/Melati.png`
     - `res://plants/sprites/Wijaya Kusuma.png`
     - `res://plants/sprites/Beringin.png`
     - `res://plants/sprites/Kecombrang.png`
     - `res://plants/sprites/Kunyit.png`
     - hybrid sprites under `res://plants/sprites/`
2. `inventory/data/item_database.gd`
   - `ItemDatabase.get_icon_path(seed_id)` returns existing seed icon paths under `res://assets/aseprite/icons/`.

Preferred visual source for this redesign: plant sprite from `PlantRegistry`, because the player is choosing the plant that will appear in the world, not just the inventory seed item. Fall back to `ItemDatabase.get_icon_path(seed_id)` if a plant sprite path is missing.

---

## UX Requirements

### Palette Slot

Each available seed-quality slot should show:

- A plant sprite/icon centered in the slot.
- A compact quality marker using the existing `ItemDatabase.get_quality_marker(quality)`.
- The stack count, e.g. `x3`.
- A selected border when `seed_id == selected_seed_id` and `quality == selected_seed_quality`.
- Tooltip text with `ItemDatabase.get_display_name_with_quality(seed_id, quality)` and `ItemDatabase.get_quality_description(seed_id, quality)`.

Recommended slot size: 36x38 or 40x40 px. Keep the full palette narrow enough for the 640x360 base viewport and allow horizontal scrolling when many seed tiers are available.

### Visual Styling

Match the established wood-panel UI style:

- Panel background: warm dark brown.
- Border: muted gold.
- Slot background: very dark brown.
- Selected slot border: brighter gold.
- Quality color: use `ItemDatabase.get_quality_color(quality)`.
- No default gray Godot controls.

Use `TextureRect` with:

```gdscript
stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
expand_mode = TextureRect.EXPAND_IGNORE_SIZE
texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
```

The icon must be readable at small size. If direct plant sprites are too visually busy, use a 24x24 or 28x28 display area inside the slot rather than shrinking the full slot.

### Selected Plant Feedback

When a plant is selected, the palette should make the active choice obvious without relying only on the world ghost:

- Highlight selected slot border.
- Keep the quality marker visible.
- Optionally add a tiny selected indicator label or gold corner accent, but do not add large explanatory text.

The world placement preview can keep the existing colored tile highlight and effect-radius overlay because that color still communicates valid/invalid placement and radius type.

---

## Implementation Plan

### 1. Add a Seed-to-Plant Helper

Add a small helper in `plant_palette_ui.gd` or a new local helper script:

```gdscript
func _seed_to_plant_id(seed_id: String) -> String:
    return seed_id.trim_suffix("_seed")
```

Use it to resolve `PlantRegistry.get_sprite_path(plant_id)`.

### 2. Resolve the Slot Texture

Add a local method that prefers plant sprites and falls back to seed icons:

```gdscript
func _get_seed_texture(seed_id: String) -> Texture2D:
    var plant_id := _seed_to_plant_id(seed_id)
    var sprite_path := PlantRegistry.get_sprite_path(plant_id)
    if not sprite_path.is_empty():
        var sprite := load(sprite_path) as Texture2D
        if sprite != null:
            return sprite

    var icon_path := ItemDatabase.get_icon_path(seed_id)
    if not icon_path.is_empty():
        return load(icon_path) as Texture2D
    return null
```

If `PlantRegistry` is unavailable in the current branch, leave a local mapping or a `TODO: UI-04` fallback comment and use `ItemDatabase.get_icon_path(seed_id)` only.

### 3. Move Static Slot Layout into a Scene

Create a scene-authored slot resource:

| File | Purpose |
|------|---------|
| `plants/placement/plant_palette_slot.tscn` | Reusable slot UI with styled PanelContainer, TextureRect, quality label, count label |
| `plants/placement/plant_palette_slot.gd` | Binds seed id, quality, count, selected state, and click signal |

Suggested node shape:

```text
PlantPaletteSlot (PanelContainer)
  MarginContainer
    VBoxContainer
      TextureRect (%PlantIcon)
      HBoxContainer
        Label (%QualityLabel)
        Label (%CountLabel)
```

Static styling belongs in the `.tscn` as `StyleBoxFlat` sub-resources. Runtime script should only set texture, labels, tooltip, selected border, and emit the click signal.

If the change needs to stay smaller, it is acceptable to keep `plant_palette_ui.gd` as the parent and instance only the slot scene dynamically.

### 4. Keep Palette Parent Behavior Stable

Update `plants/placement/plant_palette_ui.gd` to:

- Instance `plant_palette_slot.tscn` for each seed-quality stack.
- Connect slot selection to `_on_slot_clicked(seed_id, quality)`.
- Continue calling `_manager.select_seed(seed_id, quality)`.
- Continue refreshing after inventory changes and after placement.
- Continue using `_position_panel()` and existing layer/process mode behavior unless a scene-authored palette parent is also introduced.

Do not change `plant_placement_manager.gd` placement rules unless needed for texture lookup.

### 5. Optional Palette Parent Scene

If time allows, convert the entire palette parent into:

| File | Purpose |
|------|---------|
| `plants/placement/plant_palette_ui.tscn` | Scene-authored CanvasLayer palette panel, title, scroll container, hint label |
| `plants/placement/plant_palette_ui.gd` | Existing behavior bound to `%PlantSlotList`, `%PalettePanel`, `%PaletteScroll` |

Then update `_create_palette_ui()` in `plant_placement_manager.gd`:

```gdscript
var palette: Node = preload("res://plants/placement/plant_palette_ui.tscn").instantiate()
```

This is preferred for scene-first configuration, but keep the patch narrow if a full parent conversion creates unnecessary churn.

---

## Files to Create

| File | Purpose |
|------|---------|
| `plants/placement/plant_palette_slot.tscn` | Scene-authored selectable plant slot UI |
| `plants/placement/plant_palette_slot.gd` | Slot binding/click logic |

Optional:

| File | Purpose |
|------|---------|
| `plants/placement/plant_palette_ui.tscn` | Scene-authored palette parent |

---

## Files to Modify

| File | Change |
|------|--------|
| `plants/placement/plant_palette_ui.gd` | Replace swatch-based dynamic slots with icon-based slot instances |
| `plants/placement/plant_placement_manager.gd` | Only if converting palette parent to `.tscn`; preserve placement behavior |
| `docs/design/TASK_BREAKDOWN.md` | Only update if this prompt is implemented and docs need to record PLANT-03/04 polish |

Do not modify files under `addons/`.

---

## Acceptance Criteria

- Entering placement mode shows plant visuals/icons for every available seed stack.
- The palette no longer uses a color swatch as the primary plant identifier.
- Each slot still shows exact quality tier and stack count.
- Selecting a slot still places the exact selected seed quality.
- Selected slot state is visually clear.
- Existing world grid, ghost tile, radius preview, valid/invalid placement color, plant cap, day-only placement, inventory consumption, Codex discovery, and SFX behavior still work.
- The UI fits at 640x360 without text overlap.
- No default gray Godot UI styling appears in newly added scenes.

---

## Validation

Run the smallest checks available:

1. Static check:

```powershell
git diff --check
```

2. If Godot is available, run a headless startup/parser check:

```powershell
godot --headless --path . --quit
```

If `godot` is not on PATH, try `godot4`, then inspect `.godot/editor/project_metadata.cfg` for the editor binary path.

3. Manual gameplay check:
   - Add multiple seed types and quality tiers to inventory.
   - Press `P` during day.
   - Confirm each slot shows a recognizable plant visual.
   - Select a plant and verify the selected border changes.
   - Place it and verify the correct plant appears, the correct quality tier is consumed, and the palette refreshes.
   - Right-click and `P` still close/cancel as before.

---

## Notes for the Implementer

- This is a UI identification polish task, not a placement-system rewrite.
- Prefer existing `PlantRegistry` sprite paths over creating another seed-to-texture dictionary.
- Keep `ItemDatabase` as the source for quality markers, quality colors, display names, and tooltip text.
- Preserve typed GDScript and rebuild typed arrays explicitly if needed.
- Leave deferred work as explicit `TODO: <TASK-ID>` stubs.
