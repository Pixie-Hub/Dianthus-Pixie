# PROMPT — UI-04: Plant Codex Screen

**Task ID:** UI-04  
**Category:** UI/HUD  
**Priority:** Medium  
**Dependencies:** PLANT-05 (all base plants), PLANT-CB (cross-breeding system)  
**GDD Reference:** §11.2 — "Plant Codex — dibuka melalui Quest; menampilkan semua tanaman yang sudah ditemukan beserta kombinasi yang sudah dicoba"

---

## Goal

Implement a Plant Codex screen that catalogues all plants in the game. Entries unlock when the player discovers a plant (places it, breeds it, or picks up its seed for the first time). Undiscovered plants and combos show as "???" with locked styling.

---

## Scope

### In Scope
1. **PlantRegistry** static data class — single source of truth for all plant metadata
2. **CodexManager autoload** — tracks which plants have been discovered
3. **Plant Codex UI screen** — scrollable list of all plants (base + hybrid) with detail panel
4. **Cross-Breeding Combo section** — shows known breeding combos; undiscovered = "?"
5. **Input action** — `codex_toggle` bound to **J** key opens/closes the codex
6. **Discovery signals** — `plant_discovered(plant_id)` signal when a new plant is first seen
7. **Save/load integration** — persist discovered plants in save file (schema version bump)

### Out of Scope
- Quest integration (leave `TODO: QUEST-04` stub in CodexManager)
- Plant lore/flavor text beyond current data
- Animated plant previews
- PLANT-12 remaining 20 combos (codex displays whatever combos exist in BreedingManager.COMBOS)

---

## Existing Architecture Reference

### Plant Catalogue (11 total)

**7 Base Plants:**

| Plant ID | Display Name | Role | Effect | Radius | Modulate Color |
|----------|-------------|------|--------|--------|----------------|
| bougainvillea | Bougainvillea | Offensive | 5 DMG/tick to enemies | 24px | Color(0.85, 0.15, 0.45, 1) |
| rafflesia | Rafflesia | Defensive | 0.6x slow to enemies | 40px | Color(0.65, 0.12, 0.15, 1) |
| melati | Melati | Support | +3 energy/sec to player | 32px | Color(0.9, 0.95, 1.0, 1) |
| wijaya_kusuma | Wijaya Kusuma | Offensive | Night auto-attack 8 DMG projectile | 48px | Color(0.94, 0.91, 1.0, 1) |
| beringin | Beringin | Defensive | Root wall (HP:60, 20s duration) | 32px | Color(0.24, 0.48, 0.13, 1) |
| kecombrang | Kecombrang | Support | +20% attack speed to player | 28px | Color(1.0, 0.22, 0.38, 1) |
| kunyit | Kunyit | Hybrid | +3 melee damage to player | 24px | Color(0.83, 0.72, 0.13, 1) |

**4 Hybrid Plants (from BreedingManager.COMBOS):**

| Plant ID | Display Name | Inputs | Effect |
|----------|-------------|--------|--------|
| bunga_api | Bunga Api | Bougainvillea Extract + Kecombrang Extract | 7 DMG/tick + 3 burn DMG over 2s |
| bunga_bayang | Bunga Bayang | Rafflesia Extract + Shadow Resin | 0.7x slow + night auto-attack 4 DMG |
| melati_emas | Melati Emas | Verdant Sap + Dianthus Pollen | HP +2/s + energy +4/s regen |
| baja_kuning | Baja Kuning | Kunyit Extract + Shadow Resin | +30% DR + counter-attack 25% reflect |

### Existing UI Patterns
- **CanvasLayer** with layer number (inventory=90, crafting=91, cross_breeding=92). Use **layer 93** for codex.
- `process_mode = Node.PROCESS_MODE_ALWAYS` so it works while paused.
- Toggle via `_unhandled_input` listening for the action, then `get_viewport().set_input_as_handled()`.
- Pauses game tree on open: `get_tree().paused = visible`.
- Overlay: dark ColorRect + centered Panel.
- Signal-driven refresh from data managers.
- See `inventory_screen.gd`, `crafting_screen.gd`, `cross_breeding_screen.gd` for patterns.

### Key Data Sources
- `save_manager.gd` -> `PLANT_TYPE_TO_SCENE` — all 11 plant IDs
- `plant_placement_manager.gd` -> `SEED_TO_SCENE`, `SEED_EFFECT_RADIUS`, `SEED_RADIUS_COLORS`
- `breeding_manager.gd` -> `COMBOS` dict (4 combos), `discovered_combos`, `is_discovered()`
- `item_database.gd` -> seed item entries with descriptions and icon paths

### Save Schema
- Current version: **5**
- Bump to **6** for codex data
- Migration v5->v6: add `codex: { discovered_plants: {} }` with empty dict

---

## Implementation Plan

### 1. Plant Data Registry — `ui/codex/plant_registry.gd`

Static data class (like ItemDatabase / RecipeDatabase pattern — `class_name PlantRegistry`, no extends).

```gdscript
const PLANTS: Dictionary = {
    "bougainvillea": {
        "display_name": "Bougainvillea",
        "role": "Offensive",
        "effect": "Thorns deal 5 DMG/tick to enemies in radius.",
        "radius": 24.0,
        "color": Color(0.85, 0.15, 0.45, 1),
        "seed_id": "bougainvillea_seed",
        "is_hybrid": false,
        "unlock_hint": "Available from start.",
    },
    # ... all 11 plants, hybrids include combo_id key
    "bunga_api": {
        "display_name": "Bunga Api",
        "role": "Hybrid — Offensive",
        "effect": "Fire thorns deal 7 DMG/tick + 3 burn DMG over 2s.",
        "radius": 28.0,
        "color": Color(1.0, 0.4, 0.1, 1),
        "seed_id": "bunga_api_seed",
        "is_hybrid": true,
        "combo_id": "bunga_api",
        "unlock_hint": "Cross-breed Bougainvillea Extract + Kecombrang Extract.",
    },
}
```

Static API: `get_plant(id)`, `get_all_plant_ids()`, `get_display_name(id)`, `get_base_plant_ids()`, `get_hybrid_plant_ids()`.

### 2. CodexManager Autoload — `ui/codex/codex_manager.gd`

- `extends Node`, registered as autoload `CodexManager` in project.godot (after BreedingManager).
- `var discovered_plants: Dictionary = {}` — keys = plant_id, values = true.
- `signal plant_discovered(plant_id: String)`
- Public API:
  - `discover_plant(plant_id: String)` — adds to dict, emits signal if first time
  - `is_plant_discovered(plant_id: String) -> bool`
  - `get_discovered_count() -> int`
  - `get_total_count() -> int` (from PlantRegistry)
  - `serialize() -> Dictionary`
  - `deserialize(data: Dictionary)`
- Auto-discovery hooks (connect in `_ready()`):
  - `BreedingManager.breed_succeeded` -> discover the hybrid plant via combo_id
  - `InventoryManager.item_added` -> if item_id ends with `_seed`, map to plant_id and discover
- Bougainvillea discovered by default (available from start per GDD).
- `TODO: QUEST-04` — emit discovery quest triggers.

### 3. Codex Screen — `ui/codex/codex_screen.gd` + `codex_screen.tscn`

**Layout (640x360 viewport):**

```
CanvasLayer (layer=93, PROCESS_MODE_ALWAYS)
+-- Overlay (ColorRect, dark semi-transparent)
+-- Panel (centered, ~400x280)
    +-- MarginContainer
        +-- VBoxContainer
            +-- TitleLabel — "PLANT CODEX  (X / 11 discovered)"
            +-- HBoxContainer
            |   +-- LEFT: ScrollContainer -> PlantList (VBoxContainer, %PlantList)
            |   |   +-- Per plant: PanelContainer row
            |   |       +-- HBoxContainer
            |   |           +-- ColorRect swatch (plant color or grey)
            |   |           +-- Label (name or "???")
            |   +-- RIGHT: DetailPanel (VBoxContainer, %DetailPanel)
            |       +-- PlantNameLabel
            |       +-- RoleLabel
            |       +-- EffectLabel (autowrap)
            |       +-- RadiusLabel — "Effect Radius: Xpx"
            |       +-- HintLabel — unlock hint or combo recipe
            +-- CloseHint — "Press J to close"
```

**Behavior:**
- J key toggles open/close (action: `codex_toggle`).
- Left list shows all plants from PlantRegistry.get_all_plant_ids().
  - Discovered: show name + colored swatch.
  - Undiscovered: show "???" + grey swatch.
- Clicking a discovered plant row populates detail panel on the right.
- Clicking an undiscovered plant shows "Not yet discovered" + unlock hint.
- Hybrid section separated by a "— HYBRIDS —" divider label in the list.
- For hybrids: show the recipe inputs if BreedingManager.is_discovered(combo_id) is true; otherwise show "??? + ??? = ???".
- Build list dynamically in `_build_plant_list()` (same pattern as crafting_screen `_build_recipe_list()`).
- Selected row highlighted with gold border.

**Connections:**
- `CodexManager.plant_discovered` -> refresh list.
- `BreedingManager.combo_discovered` -> refresh combo display.

### 4. Save/Load Integration — `save_manager.gd`

- Bump `SCHEMA_VERSION` to **6**.
- `_gather_state()` -> add `state["codex"] = CodexManager.serialize()`.
- `_apply_state()` -> call `CodexManager.deserialize(state.get("codex", {}))`.
- `_migrate()` -> v5->v6: `state["codex"] = { "discovered_plants": {} }`.

### 5. Input Action — `project.godot`

- Add `codex_toggle` action mapped to **J** key (physical_keycode=74).

### 6. Scene Instancing — `meadow_edge.tscn`

- Add CodexScreen instance as sibling to other UI screens (after CrossBreedingScreen).

### 7. Discovery Trigger Hooks

- `plant_placement_manager.gd` -> `_place_plant()`: after placing, call `CodexManager.discover_plant(plant_type)` where plant_type = selected_seed_id stripped of `_seed` suffix.
- `player_controller.gd` -> (optional) debug key Shift+J = discover all plants.

---

## Files to Create

| File | Purpose |
|------|---------|
| `ui/codex/plant_registry.gd` | Static plant data catalogue (class_name PlantRegistry) |
| `ui/codex/codex_manager.gd` | Autoload — tracks discovered plants, signals, serialize/deserialize |
| `ui/codex/codex_screen.gd` | Codex UI screen logic |
| `ui/codex/codex_screen.tscn` | Codex UI screen scene |

## Files to Modify

| File | Change |
|------|--------|
| `project.godot` | Add CodexManager autoload; add codex_toggle (J) input action |
| `save/scripts/save_manager.gd` | SCHEMA_VERSION=6; gather/apply codex; v5->v6 migration |
| `plants/placement/plant_placement_manager.gd` | Call CodexManager.discover_plant() on plant placement |
| `world/zones/meadow_edge/meadow_edge.tscn` | Instance CodexScreen |
| `player/scripts/player_controller.gd` | Add Shift+J debug key to discover all plants |
| `docs/design/PERSON_TASKS.md` | Mark UI-04 done; add J/Shift+J to debug key table |

---

## Acceptance Criteria

1. Pressing J opens the Plant Codex screen; pressing J again (or Escape) closes it.
2. All 7 base plants + 4 hybrids listed. Discovered plants show name + colored swatch + details. Undiscovered show "???" + grey.
3. Placing a plant via PlantPlacementManager auto-discovers it in the codex.
4. Breeding a hybrid auto-discovers the hybrid plant in the codex.
5. Picking up a seed for the first time auto-discovers the corresponding plant.
6. Hybrid entries show breeding recipe if the combo is discovered in BreedingManager.
7. Discovery state persists across save/load (schema v6).
8. Bougainvillea is discovered by default on new games.
9. Codex counter in title shows "X / 11 discovered".
