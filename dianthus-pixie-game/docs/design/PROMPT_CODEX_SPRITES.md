# PROMPT — CODEX-SPRITE: Plant Sprites in Codex Detail Panel

**Task ID:** CODEX-SPRITE  
**Category:** UI/HUD  
**Priority:** Low  
**Dependencies:** UI-04 (Plant Codex Screen — done)

---

## Goal

Add each plant's sprite image to the codex detail panel (bottom-right area). Discovered plants show their full-color sprite; undiscovered plants show a **black silhouette** (all-black shader/modulate).

---

## Scope

### In Scope
1. Add a `"sprite_path"` key to every entry in `PlantRegistry.PLANTS` mapping plant_id → sprite PNG path
2. In `codex_screen.gd` `_update_detail()`, create a `TextureRect` displaying the plant sprite anchored to the **bottom-right** of the detail panel
3. If the plant is **undiscovered**, apply a black silhouette effect (modulate `Color(0, 0, 0, 1)`) so only the shape is visible
4. If the plant is **discovered**, show the sprite at full color (modulate `Color(1, 1, 1, 1)`)

### Out of Scope
- Animated plant previews
- Sprite scaling / zoom controls
- Tooltip on sprite hover

---

## Existing Files & Architecture

### Plant Sprite Assets — `plants/sprites/`

All 11 plant sprites exist as PNGs with transparent backgrounds:

| plant_id | Sprite File |
|----------|------------|
| bougainvillea | `res://plants/sprites/Bougainvillea.png` |
| rafflesia | `res://plants/sprites/Rafflesia.png` |
| melati | `res://plants/sprites/Melati.png` |
| wijaya_kusuma | `res://plants/sprites/Wijaya Kusuma.png` |
| beringin | `res://plants/sprites/Beringin.png` |
| kecombrang | `res://plants/sprites/Kecombrang.png` |
| kunyit | `res://plants/sprites/Kunyit.png` |
| bunga_api | `res://plants/sprites/Bunga Api.png` |
| bunga_bayang | `res://plants/sprites/Bunga Bayang.png` |
| melati_emas | `res://plants/sprites/Melati Emas.png` |
| baja_kuning | `res://plants/sprites/Baja Kuning.png` |

### Codex Detail Panel — `ui/codex/codex_screen.gd`

`_update_detail(plant_id)` (line 140) rebuilds `_detail_panel` (a VBoxContainer, `%DetailPanel`) each time a plant row is selected. Children are cleared then re-added: name label, role label, separator, effect label, radius label, combo recipe (hybrids).

The detail panel sits on the **right** side of an HBoxContainer, with `size_flags_horizontal = SIZE_EXPAND_FILL` and `size_flags_vertical = SIZE_EXPAND_FILL`.

### PlantRegistry — `ui/codex/plant_registry.gd`

Static `PLANTS` dict with 11 entries. Each entry has keys: `display_name`, `role`, `effect`, `radius`, `color`, `seed_id`, `is_hybrid`, `unlock_hint`, and optionally `combo_id`. **No `sprite_path` key yet.**

---

## Implementation Plan

### 1. Add `sprite_path` to PlantRegistry — `ui/codex/plant_registry.gd`

Add a `"sprite_path"` key to each of the 11 entries in `PLANTS`:

```gdscript
"bougainvillea": {
    ...existing keys...,
    "sprite_path": "res://plants/sprites/Bougainvillea.png",
},
```

Repeat for all 11 plants using the file paths in the table above.

Also add a static helper:

```gdscript
static func get_sprite_path(plant_id: String) -> String:
    return str(PLANTS.get(plant_id, {}).get("sprite_path", ""))
```

### 2. Show Sprite in Detail Panel — `ui/codex/codex_screen.gd`

In `_update_detail(plant_id)`, after all existing labels are added, append a **TextureRect** for the plant sprite:

```gdscript
# --- Plant Sprite (bottom-right of detail panel) ---
var sprite_path: String = PlantRegistry.get_sprite_path(plant_id)
if sprite_path != "":
    # Spacer pushes sprite to bottom
    var spacer: Control = Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _detail_panel.add_child(spacer)

    # Container to right-align the sprite
    var sprite_container: HBoxContainer = HBoxContainer.new()
    sprite_container.alignment = BoxContainer.ALIGNMENT_END

    var sprite_rect: TextureRect = TextureRect.new()
    sprite_rect.texture = load(sprite_path)
    sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    sprite_rect.custom_minimum_size = Vector2(48, 48)
    sprite_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

    if discovered:
        sprite_rect.modulate = Color(1, 1, 1, 1)
    else:
        sprite_rect.modulate = Color(0, 0, 0, 1)

    sprite_container.add_child(sprite_rect)
    _detail_panel.add_child(sprite_container)
```

Key points:
- A `Control` spacer with `SIZE_EXPAND_FILL` pushes the sprite to the bottom of the VBoxContainer
- An `HBoxContainer` with `ALIGNMENT_END` right-aligns the sprite
- `TEXTURE_FILTER_NEAREST` preserves pixel art crispness
- `custom_minimum_size = Vector2(48, 48)` gives the sprite a readable display size
- **Undiscovered**: `modulate = Color(0, 0, 0, 1)` turns the sprite fully black (silhouette — only the alpha shape is visible against the dark panel)
- **Discovered**: `modulate = Color(1, 1, 1, 1)` shows full color

### 3. Also show sprite for undiscovered "select a plant" state — `_clear_detail()`

No change needed. The sprite only appears when a plant row is selected (via `_update_detail`). The default "Select a plant." placeholder stays as-is.

---

## Files to Modify

| File | Change |
|------|--------|
| `ui/codex/plant_registry.gd` | Add `"sprite_path"` key to all 11 PLANTS entries; add `get_sprite_path()` static method |
| `ui/codex/codex_screen.gd` | In `_update_detail()`, add TextureRect with sprite (bottom-right, black if undiscovered) |

---

## Acceptance Criteria

1. Selecting a **discovered** plant in the codex shows its full-color sprite in the bottom-right of the detail panel.
2. Selecting an **undiscovered** plant shows a **black silhouette** (same sprite shape, fully black) in the bottom-right.
3. Sprites render with nearest-neighbor filtering (no blurring).
4. Sprite does not overlap or clip existing text labels — it sits below all text, pushed to the bottom-right via spacer + right-aligned container.
5. No visual change to the default "Select a plant." state (no sprite shown).
