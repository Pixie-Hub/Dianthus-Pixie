# PROMPT — Cross-Breeding System

**Task IDs:** PLANT-02 (Cross-Breeding UI), PLANT-12 (partial — 4 starter combos)
**GDD:** §7.2, §7.4, §17 | **Priority:** Critical
**Deps:** PLANT-01 ✅ (Breeding Bench), PLANT-06 ✅ (Crafting System), CORE-02/UI-02 ✅, SAVE-01/02 ✅, PLANT-07 ✅ (Energy)

---

## Goal

Build: BreedingManager autoload (combo registry + discovery tracking), CrossBreedingScreen UI (two input slots → one output slot), 4 starter hybrid plant entities with effects, integration with the existing BreedingBench (E key now opens a **tab-based** bench UI with Crafting and Breeding tabs), save/load, and debug keys.

**NOT building:** MINI-01 (Plant Experimentation minigame) — quality is always "Biasa" for now, with a `TODO: MINI-01` stub. The remaining 20 combos (PLANT-12 full) are also deferred — only the 4 GDD-defined combos are implemented here.

---

## 1. Design Decisions (resolving GDD §7.2 ambiguities)

**Input slots accept item_id strings** (plant extract items), not live PlantBase instances. The player consumes inventory items to attempt a breed. This keeps the flow consistent with the crafting system and avoids needing placed plants.

**Required input items for the 4 starter combos:**

| combo_id | input_a | input_b | result_plant | result_scene |
|----------|---------|---------|-------------|--------------|
| `bunga_api` | `bougainvillea_extract` | `kecombrang_extract` | Bunga Api | `plants/entities/bunga_api.tscn` |
| `bunga_bayang` | `rafflesia_extract` | `shadow_resin` | Bunga Bayang | `plants/entities/bunga_bayang.tscn` |
| `melati_emas` | `verdant_sap` | `dianthus_pollen` | Melati Emas | `plants/entities/melati_emas.tscn` |
| `baja_kuning` | `kunyit_extract` | `shadow_resin` | Baja Kuning | `plants/entities/baja_kuning.tscn` |

> **Note:** GDD §7.2 lists "Melati + Dianthus Pollen" and "Kunyit + Shadow Resin" as parent plants. Since Melati/Kunyit plants are not yet implemented (PLANT-02/05), we use `verdant_sap` as the Melati proxy and `kunyit_extract` directly. The combo inputs can be updated when those plants are added.

**Combo order does not matter:** `(A, B)` == `(B, A)`.

**Quality tiers (GDD §7.2):**
- **Biasa** (default) — effect at 100% strength. Always produced until MINI-01 minigame is built.
- **Superior** — effect at 125%. `TODO: MINI-01`
- **Masterwork** — effect at 150%. `TODO: MINI-01`

**Failure states (GDD §7.2):**
- **Unknown combo** (two items that don't form a valid recipe): consume items, produce nothing. Print message "Combination failed — no known result."
- **Known combo, score < 30%**: resource lost, no output. `TODO: MINI-01` — currently impossible since minigame always returns 100%.
- **Known combo, score 30–69%**: produce Wilted Plant (50% effect). `TODO: MINI-01`
- **Known combo, score ≥ 70%**: produce Biasa/Superior/Masterwork based on score. Currently always Biasa.

For now, all known combos **always succeed** and produce Biasa quality. Unknown combos consume resources and produce nothing.

**Discovery tracking:** `BreedingManager.discovered_combos: Dictionary` — keys are `combo_id`, values are `true`. A combo is "discovered" the first time it is successfully bred. The CrossBreedingScreen shows "?" for undiscovered combos and the result name for discovered ones.

---

## 2. New Items in ItemDatabase

No new *input* items needed — all already exist in `item_database.gd`.

Add **4 new plant seed/cutting items** that the breeding system produces (the player gets these in inventory, then can place them via plant placement — `TODO: PLANT-03`):

```
"bunga_api_seed":     { "display_name": "Bunga Api Seed",     "rarity": Rarity.RARE,     "max_stack": 5, "description": "Hybrid seed: Bougainvillea × Kecombrang. Thorns + fire AoE." },
"bunga_bayang_seed":  { "display_name": "Bunga Bayang Seed",  "rarity": Rarity.RARE,     "max_stack": 5, "description": "Hybrid seed: Rafflesia × Shadow Resin. Slow + night auto-attack." },
"melati_emas_seed":   { "display_name": "Melati Emas Seed",   "rarity": Rarity.RARE,     "max_stack": 5, "description": "Hybrid seed: Melati × Dianthus Pollen. HP + Energy regen." },
"baja_kuning_seed":   { "display_name": "Baja Kuning Seed",   "rarity": Rarity.RARE,     "max_stack": 5, "description": "Hybrid seed: Kunyit × Shadow Resin. Armor + counter-attack." },
```

---

## 3. BreedingManager Autoload

**New file:** `crafting/breeding/breeding_manager.gd` — extends Node
**Autoload:** `BreedingManager="*res://crafting/breeding/breeding_manager.gd"` added to project.godot after CraftingManager.

### Signals

```gdscript
signal breed_succeeded(combo_id: String, result_item_id: String)
signal breed_failed(reason: String)
signal combo_discovered(combo_id: String)
```

### Constants

```gdscript
const COMBOS: Dictionary = {
    "bunga_api": {
        "input_a": "bougainvillea_extract",
        "input_b": "kecombrang_extract",
        "result_item": "bunga_api_seed",
        "result_plant_scene": "res://plants/entities/bunga_api.tscn",
        "display_name": "Bunga Api",
        "description": "Fire Flower — thorns + fire AoE (7 DMG/tick + 3 burn DMG over 2s).",
    },
    "bunga_bayang": {
        "input_a": "rafflesia_extract",
        "input_b": "shadow_resin",
        "result_item": "bunga_bayang_seed",
        "result_plant_scene": "res://plants/entities/bunga_bayang.tscn",
        "display_name": "Bunga Bayang",
        "description": "Shadow Bloom — slow + night auto-attack zone (4 DMG, 0.7× slow).",
    },
    "melati_emas": {
        "input_a": "verdant_sap",
        "input_b": "dianthus_pollen",
        "result_item": "melati_emas_seed",
        "result_plant_scene": "res://plants/entities/melati_emas.tscn",
        "display_name": "Melati Emas",
        "description": "Golden Jasmine — regen HP (+2/s) and energy (+4/s) in radius.",
    },
    "baja_kuning": {
        "input_a": "kunyit_extract",
        "input_b": "shadow_resin",
        "result_item": "baja_kuning_seed",
        "result_plant_scene": "res://plants/entities/baja_kuning.tscn",
        "display_name": "Baja Kuning",
        "description": "Yellow Iron — armor buff (+30% DR) + counter-attack (25% reflect).",
    },
}
```

### State

```gdscript
var discovered_combos: Dictionary = {}   # { combo_id: true }
```

### API

- `find_combo(item_a: String, item_b: String) -> String` — returns combo_id if the pair matches any COMBOS entry (order-independent), or `""` if no match.
- `can_breed(item_a: String, item_b: String) -> bool` — both items present in inventory (≥1 each) AND items are not the same slot. If item_a == item_b, need ≥2 of that item.
- `breed(item_a: String, item_b: String) -> bool`:
  1. Validate `can_breed`. If not → emit `breed_failed`, return false.
  2. Consume 1× item_a and 1× item_b from inventory.
  3. Call `find_combo(item_a, item_b)`.
  4. If combo found: add result_item to inventory (1×), emit `breed_succeeded`, mark discovered. Return true.
  5. If no combo: emit `breed_failed("Unknown combination — resources lost.")`. Return true (resources still consumed per GDD §7.2 unknown combo rules).
- `is_discovered(combo_id: String) -> bool`
- `get_combo(combo_id: String) -> Dictionary`
- `get_all_combo_ids() -> Array`
- `get_display_name(combo_id: String) -> String` — returns "???" if not discovered, else the real name.
- `serialize() -> Dictionary` — returns `{ "discovered": discovered_combos.duplicate() }`
- `deserialize(data: Dictionary) -> void` — restores discovered_combos from `data.get("discovered", {})`.

---

## 4. Hybrid Plant Entities

Create 4 new plant scripts + scenes in `plants/entities/`. All extend `PlantBase`.

### 4.1 Bunga Api (Fire Flower)

**Files:** `plants/entities/bunga_api.gd`, `plants/entities/bunga_api.tscn`
**Class:** `BungaApi extends PlantBase`
**Group:** `"bunga_apis"`
**Stats:** max_hp=35, effect_radius=28.0
**Color:** `Color(1.0, 0.4, 0.1, 1)` (fiery orange)
**Effect:** Combines Bougainvillea thorn damage with fire burn.
- Deals 7 DMG/tick (1.0s interval) to enemies in radius — like Bougainvillea.
- Additionally applies a 2s burn: 3 DMG/s for 2 ticks (total 6 burn DMG). Burn is tracked via a simple timer per enemy (Dictionary `_burn_timers: Dictionary = {}`). If enemy already burning, refresh timer.
- Implementation: on tick damage, also start/refresh burn. `_process(delta)` decrements burn timers and applies burn damage every 1.0s.

### 4.2 Bunga Bayang (Shadow Bloom)

**Files:** `plants/entities/bunga_bayang.gd`, `plants/entities/bunga_bayang.tscn`
**Class:** `BungaBayang extends PlantBase`
**Group:** `"bunga_bayangs"`
**Stats:** max_hp=40, effect_radius=36.0
**Color:** `Color(0.3, 0.1, 0.4, 1)` (deep purple)
**Effect:** Combines Rafflesia slow with night-only projectile attacks.
- Slows enemies in radius by 0.7× (similar to Rafflesia but weaker — 0.7 vs 0.6).
- At night (`DayNightCycle.is_night()`): fires a dark projectile at nearest enemy every 2.0s dealing 4 DMG. Projectile is a simple `Area2D` that moves toward the target and `queue_free()`s on hit or after 1.5s.
- During day: only slow effect, no projectile.

### 4.3 Melati Emas (Golden Jasmine)

**Files:** `plants/entities/melati_emas.gd`, `plants/entities/melati_emas.tscn`
**Class:** `MelatiEmas extends PlantBase`
**Group:** `"melati_emases"`
**Stats:** max_hp=25, effect_radius=32.0
**Color:** `Color(1.0, 0.85, 0.3, 1)` (golden yellow)
**Effect:** Ultimate support plant — regen HP and energy to nearby player.
- If player is within `effect_radius`: +2 HP/sec and +4 energy/sec.
- Uses accumulator pattern (like `_update_core_energy_regen` in player_controller.gd).
- Calls `GameManager.player.heal()` for HP and `GameManager.player.add_energy()` for energy.

### 4.4 Baja Kuning (Yellow Iron)

**Files:** `plants/entities/baja_kuning.gd`, `plants/entities/baja_kuning.tscn`
**Class:** `BajaKuning extends PlantBase`
**Group:** `"baja_kunings"`
**Stats:** max_hp=50, effect_radius=28.0
**Color:** `Color(0.85, 0.7, 0.15, 1)` (turmeric gold)
**Effect:** Grants nearby player an armor buff and counter-attack.
- While player is within radius: `player.damage_reduction = 0.3` (30% DR). When player leaves radius: reset to 0.0.
- **New var on player_controller.gd:** `var damage_reduction: float = 0.0` — applied in `take_damage()`: `amount = int(float(amount) * (1.0 - damage_reduction))`.
- Counter-attack: when player takes damage while in Baja Kuning radius, reflect 25% of *original* (pre-reduction) damage back to the attacker. This requires the `take_damage()` caller to pass a `source` reference. For now, add `TODO: PLANT-12` for the reflect mechanic — just implement the DR buff.

### Scene Template (.tscn pattern)

Each plant scene follows the existing Bougainvillea pattern:

```
PlantName (StaticBody2D, script=plant_script.gd)
  +-- Sprite2D (unique_name_in_owner=true, placeholder ColorRect texture or self_modulate)
  +-- CollisionShape2D (CircleShape2D radius=8)
  +-- EffectArea (Area2D, collision_layer=0, collision_mask=4|8 for player+enemy)
        +-- CollisionShape2D (CircleShape2D radius=effect_radius)
```

For **Melati Emas** and **Baja Kuning**, the EffectArea collision_mask should include layer 3 (player) instead of layer 4 (enemy):
- Bunga Api: mask = enemy (layer 4) → bit 4
- Bunga Bayang: mask = enemy (layer 4) → bit 4
- Melati Emas: mask = player (layer 3) → bit 3
- Baja Kuning: mask = player (layer 3) → bit 3

---

## 5. CrossBreedingScreen UI

**New files:** `ui/screens/cross_breeding_screen.gd`, `ui/screens/cross_breeding_screen.tscn`

Follows same CanvasLayer pattern as `crafting_screen.gd` (layer=92, PROCESS_MODE_ALWAYS).

### Layout (640×360 viewport)

```
CrossBreedingScreen (CanvasLayer layer=92)
  +-- Overlay (ColorRect black alpha 0.6, full screen)
  +-- Panel (centered ~320×260)
      +-- MarginContainer (margins 8)
          +-- VBoxContainer
              +-- TitleLabel ("CROSS-BREEDING", font_size 10)
              +-- HBoxContainer (slots area)
              |   +-- SlotA (PanelContainer 48×48, border, droppable)
              |   |   +-- SlotALabel (Label, centered, font_size 8)
              |   +-- PlusLabel (Label "+", font_size 12)
              |   +-- SlotB (PanelContainer 48×48, border, droppable)
              |   |   +-- SlotBLabel (Label, centered, font_size 8)
              |   +-- ArrowLabel (Label "→", font_size 12)
              |   +-- OutputSlot (PanelContainer 48×48, gold border)
              |       +-- OutputLabel (Label "?", centered, font_size 8)
              +-- Separator (HSeparator)
              +-- ComboListTitle (Label "Known Combinations:", font_size 8)
              +-- ScrollContainer (vertical, custom_minimum_size 0×80)
              |   +-- ComboList (VBoxContainer, unique_name)
              +-- HBoxContainer (buttons)
                  +-- BreedButton (Button "BREED", disabled by default)
                  +-- ClearButton (Button "CLEAR")
```

### Slot Interaction

Clicking **SlotA** or **SlotB** opens a simple **item picker** sub-panel: a GridContainer listing all inventory items that have count > 0. Clicking an item assigns it to that slot. Only one of each item per slot (unless using 2× of the same item for an unknown combo attempt).

When both slots are filled:
1. Call `BreedingManager.find_combo(slot_a_item, slot_b_item)`.
2. If combo found AND `BreedingManager.is_discovered(combo_id)`: show result name in OutputSlot.
3. If combo found AND NOT discovered: show "?" in OutputSlot (player hasn't tried it yet).
4. If no combo found: show "?" in OutputSlot.
5. Enable BreedButton if `BreedingManager.can_breed(slot_a_item, slot_b_item)`.

### Known Combinations List

Below the slots, show all 4 combos:
- Discovered: `"Bougainvillea Extract + Kecombrang Extract → Bunga Api"` (white text)
- Undiscovered: `"??? + ??? → ???"` (grey text)

### Breed Button Behavior

1. Call `BreedingManager.breed(slot_a_item, slot_b_item)`.
2. If success: flash "Success!" on button, show result item name briefly in OutputSlot, then clear slots.
3. If fail: flash "Failed!" in red, clear slots.
4. Refresh combo list (in case a new combo was discovered).

### Open / Close

- `open()` / `close()` methods — same pattern as CraftingScreen.
- Close with Escape or ClearButton long-hold.
- While open: `get_tree().paused = true`.

---

## 6. BreedingBench Tab Integration

**Modify** `crafting/bench/breeding_bench.gd`:

Currently, pressing E near bench opens CraftingScreen. Change this to open a **tab-based BenchScreen** — or simpler: cycle between screens. For simplicity:

**Approach:** The BreedingBench now opens the CrossBreedingScreen instead of CraftingScreen. The CraftingScreen remains accessible via the C debug key and is also reachable from a tab/button inside CrossBreedingScreen.

**Revised bench behavior:**
1. Press E near bench (day only) → opens CrossBreedingScreen.
2. CrossBreedingScreen has a "Switch to Crafting" button (Label link) at bottom. Clicking it calls `CrossBreedingScreen.close()` then `CraftingScreen.open()`.
3. CraftingScreen gets a matching "Switch to Breeding" button that does the reverse.

**Modify** `breeding_bench.gd` line 24-26: change `find_child("CraftingScreen"...)` → `find_child("CrossBreedingScreen"...)`.

**Modify** `ui/screens/crafting_screen.gd`: Add a "Switch to Breeding" Label/Button at the bottom of the VBoxContainer. On click: `close()`, then find CrossBreedingScreen and call `open()`.

---

## 7. Save/Load Integration

**Modify** `save/scripts/save_manager.gd`:

**Bump `SCHEMA_VERSION` to 5.**

### _gather_state()

After the crafting block, add:
```gdscript
# Breeding
state["breeding"] = BreedingManager.serialize()
```

### _apply_state()

After crafting restore (step 5.6), add:
```gdscript
# 5.7 Breeding.
BreedingManager.deserialize(state.get("breeding", {}))
```

### _migrate()

Add v4→v5 block:
```gdscript
if version < 5:
    print("[SaveManager] Migrating save from v%d to v5." % version)
    if not data.has("breeding"):
        data["breeding"] = {"discovered": {}}
    data["schema_version"] = 5
```

### PLANT_TYPE_TO_SCENE

Add new entries for hybrid plants:
```gdscript
"bunga_api": "res://plants/entities/bunga_api.tscn",
"bunga_bayang": "res://plants/entities/bunga_bayang.tscn",
"melati_emas": "res://plants/entities/melati_emas.tscn",
"baja_kuning": "res://plants/entities/baja_kuning.tscn",
```

---

## 8. Player Controller Changes

**Modify** `player/scripts/player_controller.gd`:

### New var

```gdscript
var damage_reduction: float = 0.0
```

### Modify take_damage()

Apply damage reduction before HP deduction:
```gdscript
func take_damage(amount: int) -> void:
    if is_dead or is_invincible:
        return
    var reduced: int = int(float(amount) * (1.0 - damage_reduction))
    reduced = max(reduced, 1)  # always deal at least 1 damage
    current_hp = max(current_hp - reduced, 0)
    hp_changed.emit(current_hp, MAX_HP)
    # ... rest unchanged
```

### Debug Keys

Add to the debug key block in `_unhandled_input()`:

| Key | Action |
|-----|--------|
| B | Toggle CrossBreedingScreen directly (debug bypass bench proximity) |
| Shift+Insert (update existing) | Also add 1× dianthus_pollen (needed for melati_emas combo) |

Add `breeding_toggle` input action to project.godot — Key B (physical_keycode=66).

Update the existing Shift+Insert block to also include:
```gdscript
InventoryManager.add_item("dianthus_pollen", 1)
```

### F10 Debug Plant Cycle Update

Extend the `_debug_place_plant()` cycle to include 4 new hybrid plants (indices 2–5), then clear at index 6:

```
0: Bougainvillea
1: Rafflesia
2: Bunga Api
3: Bunga Bayang
4: Melati Emas
5: Baja Kuning
6: Clear all plants
```

Modulo becomes `% 7`.

---

## 9. project.godot Changes

1. Add autoload: `BreedingManager="*res://crafting/breeding/breeding_manager.gd"` after CraftingManager.
2. Add input action: `breeding_toggle` — Key B (physical_keycode 66).

---

## 10. Meadow Edge Scene Changes

**Modify** `world/zones/meadow_edge/meadow_edge.tscn`:

1. Add ext_resource for `cross_breeding_screen.tscn`.
2. Instance `CrossBreedingScreen` node (sibling of CraftingScreen).

---

## Existing Code — Files to READ Before Implementing

| File | Why |
|------|-----|
| `crafting/breeding/` | Empty dir — breeding_manager.gd goes here |
| `crafting/bench/breeding_bench.gd` | Modify to open CrossBreedingScreen |
| `crafting/scripts/crafting_manager.gd` | Reference pattern for manager autoload |
| `crafting/data/recipe_database.gd` | Reference pattern for static data registry |
| `inventory/data/item_database.gd` | Add 4 hybrid seed items |
| `inventory/scripts/inventory_manager.gd` | add_item/remove_item/has_item/get_total_count API |
| `plants/entities/plant_base.gd` | Base class for new plant entities |
| `plants/entities/bougainvillea.gd` | Pattern reference for offensive plant |
| `plants/entities/rafflesia.gd` | Pattern reference for slow plant |
| `ui/screens/crafting_screen.gd` | Add "Switch to Breeding" button; reference for UI pattern |
| `ui/screens/crafting_screen.tscn` | Reference for CanvasLayer UI scene |
| `save/scripts/save_manager.gd` | Schema v5, serialize/deserialize breeding |
| `player/scripts/player_controller.gd` | damage_reduction var, take_damage change, debug keys |
| `shared/autoloads/game_manager.gd` | Signals, player ref |
| `core/day_night/day_night_cycle.gd` | is_night() check for Bunga Bayang |
| `project.godot` | Autoload + input action |
| `world/zones/meadow_edge/meadow_edge.tscn` | Instance CrossBreedingScreen |

## Files to CREATE

| File | Description |
|------|-------------|
| `crafting/breeding/breeding_manager.gd` | Autoload — combo registry, discovery tracking, breed logic |
| `ui/screens/cross_breeding_screen.gd` | Cross-breeding UI script |
| `ui/screens/cross_breeding_screen.tscn` | Cross-breeding UI scene (CanvasLayer) |
| `plants/entities/bunga_api.gd` | Bunga Api hybrid plant script |
| `plants/entities/bunga_api.tscn` | Bunga Api hybrid plant scene |
| `plants/entities/bunga_bayang.gd` | Bunga Bayang hybrid plant script |
| `plants/entities/bunga_bayang.tscn` | Bunga Bayang hybrid plant scene |
| `plants/entities/melati_emas.gd` | Melati Emas hybrid plant script |
| `plants/entities/melati_emas.tscn` | Melati Emas hybrid plant scene |
| `plants/entities/baja_kuning.gd` | Baja Kuning hybrid plant script |
| `plants/entities/baja_kuning.tscn` | Baja Kuning hybrid plant scene |

## Files to MODIFY

| File | Change |
|------|--------|
| `inventory/data/item_database.gd` | Add 4 hybrid seed items |
| `crafting/bench/breeding_bench.gd` | Open CrossBreedingScreen instead of CraftingScreen |
| `ui/screens/crafting_screen.gd` | Add "Switch to Breeding" button |
| `save/scripts/save_manager.gd` | Schema v5: breeding serialize/deserialize + PLANT_TYPE_TO_SCENE entries |
| `player/scripts/player_controller.gd` | damage_reduction var, take_damage DR, debug keys (B, F10 cycle, Shift+Insert) |
| `project.godot` | BreedingManager autoload + breeding_toggle input action |
| `world/zones/meadow_edge/meadow_edge.tscn` | Instance CrossBreedingScreen |
| `docs/design/PERSON_TASKS.md` | Mark PLANT-02 done, add debug keys B/F10 update |

---

## Constraints

1. **No new addons** — pure GDScript, no plugins.
2. **Pixel-art friendly** — UI sizes multiples of 8, font_size 8 for body labels.
3. **640×360 viewport** — breeding panel must fit.
4. **Save compat** — `_migrate()` handles v4 saves missing "breeding" key.
5. **No minigame** — quality is always Biasa (100%). Leave `TODO: MINI-01` stubs where minigame score would plug in.
6. **No full 24 combos** — only 4 GDD-defined combos. Leave `TODO: PLANT-12` for the remaining 20.
7. **No plant placement system** — hybrid seeds go to inventory. Placement is `TODO: PLANT-03`. For testing, extend F10 debug cycle to place hybrids directly.
8. **Bunga Bayang projectile** — keep simple. No separate projectile scene file needed; create Area2D programmatically in `_fire_projectile()`, move it in `_process()`, free on hit or timeout. `TODO: PLANT-09` for shared projectile system.
9. **Baja Kuning counter-attack** — only implement DR buff. Counter-reflect is `TODO: PLANT-12` (needs `source` param on take_damage).
10. Leave `TODO: <TASK-ID>` stubs for deferred work:
    - `TODO: MINI-01` — minigame score determines quality tier
    - `TODO: PLANT-03` — plant placement from inventory seeds
    - `TODO: PLANT-12` — remaining 20 combos + counter-reflect mechanic
    - `TODO: PLANT-02` — Melati base plant (melati_emas uses verdant_sap proxy)
    - `TODO: PLANT-05` — Kecombrang/Kunyit base plants

---

## Acceptance Criteria

- [ ] BreedingManager autoload: find_combo/can_breed/breed/is_discovered all functional
- [ ] ItemDatabase has 4 new hybrid seed items
- [ ] 4 hybrid plant entities exist with correct stats and effects:
  - Bunga Api: thorn + burn damage in radius
  - Bunga Bayang: slow + night projectile
  - Melati Emas: HP + energy regen to player
  - Baja Kuning: damage reduction buff to player
- [ ] CrossBreedingScreen UI: two input slots, output preview, known combo list
- [ ] Clicking slot opens item picker showing inventory items
- [ ] Valid combo with both slots filled → BreedButton enabled
- [ ] Breeding consumes inputs, adds result seed to inventory
- [ ] Unknown combo consumes inputs, produces nothing, shows failure message
- [ ] Discovery tracking: first successful breed marks combo as discovered
- [ ] Known combos show result name; undiscovered show "???"
- [ ] BreedingBench (E key) opens CrossBreedingScreen instead of CraftingScreen
- [ ] "Switch to Crafting" / "Switch to Breeding" buttons work bidirectionally
- [ ] Save/Load round-trip: discovered combos persist correctly
- [ ] Old v4 saves load with migration (empty breeding discovery)
- [ ] player damage_reduction applied in take_damage (Baja Kuning effect)
- [ ] F10 debug cycle includes 4 hybrid plants + clear
- [ ] B key opens CrossBreedingScreen directly (debug)
- [ ] Shift+Insert also grants 1× dianthus_pollen
- [ ] No errors in Godot console on startup, breeding, save, load

---

## Testing Checklist

```
1.  Launch game. Press B — CrossBreedingScreen opens with empty slots.
2.  Shift+Insert to add test materials (including dianthus_pollen).
3.  Click SlotA → item picker shows inventory items. Select bougainvillea_extract.
4.  Click SlotB → select kecombrang_extract.
5.  Output shows "?" (undiscovered). BreedButton enabled.
6.  Click BREED → items consumed, "bunga_api_seed" appears in inventory.
7.  Combo list updates: "Bougainvillea Extract + Kecombrang Extract → Bunga Api" now visible.
8.  Repeat breed with same inputs → output now shows "Bunga Api" (discovered).
9.  Try unknown combo (e.g., petal_shard + moonspore) → resources consumed, "Failed" message.
10. Press Escape to close. Walk to bench, press E → CrossBreedingScreen opens.
11. Click "Switch to Crafting" → CraftingScreen opens. Click "Switch to Breeding" → back.
12. F10 cycles: Bougainvillea → Rafflesia → Bunga Api → Bunga Bayang → Melati Emas → Baja Kuning → Clear.
13. Place Bunga Api (F10) near enemies → thorn + burn damage visible.
14. Place Bunga Bayang → slow effect visible. Skip to night (F7) → projectile fires at enemies.
15. Place Melati Emas → stand near it → HP and energy slowly increase.
16. Place Baja Kuning → stand near it → take damage from enemy → damage reduced by 30%.
17. F11 to save. F12 to load. Discovered combos persist.
18. Delete save (Shift+F11). F12 → fails gracefully. New game → combos reset to undiscovered.
19. Press I → inventory shows hybrid seeds with RARE gold color.
20. No console errors throughout.
```
