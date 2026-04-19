# PROMPT — Crafting System

**Task IDs:** PLANT-06, Person B "Bench Crafting"
**GDD:** §7.3, §7.1, §11.2, §14, §9.2 | **Priority:** Critical
**Deps:** CORE-02/UI-02 (Done), CORE-05 (Done), SAVE-01/02 (Done)

## Goal

Build: Breeding Bench entity, crafting UI (E key), recipe database (8 recipes), material deduction via InventoryManager, weapon ownership via CraftingManager autoload, WeaponData .tres for all 8 weapons, save/load integration.

## Part 1 — New Items in ItemDatabase

Add to `inventory/data/item_database.gd` ITEMS dict:

- `bougainvillea_extract` — UNCOMMON, 20, "Thorny extract from Bougainvillea petals."
- `rafflesia_extract` — UNCOMMON, 20, "Pungent extract from Rafflesia bloom."
- `beringin_root` — UNCOMMON, 20, "Sturdy root harvested from Beringin tree."
- `kecombrang_extract` — RARE, 5, "Fiery essence of the Kecombrang flower."
- `kunyit_extract` — RARE, 5, "Golden extract from Kunyit rhizome."

Plants that produce these are deferred (PLANT-02..06). Grant via debug key.

## Part 2 — Recipe Database

**New file:** `crafting/data/recipe_database.gd` — `class_name RecipeDatabase`

8 recipes from GDD §7.3. Each: display_name, materials Dict, result_type "weapon", result_id, upgrade_of ("" if base), description.

| recipe_id | materials | upgrade_of |
|-----------|-----------|------------|
| thorn_sword | 3 petal_shard + 2 verdant_sap | — |
| spore_bomb | 2 moonspore + 1 rafflesia_extract | — |
| vine_whip | 4 verdant_sap + 1 bougainvillea_extract | — |
| petal_shield | 5 petal_shard + 2 beringin_root | — |
| blazeblade | 1 kecombrang_extract | thorn_sword |
| void_grenade | 1 shadow_resin | spore_bomb |
| crystal_lash | 1 kunyit_extract | vine_whip |
| iron_bloom_shield | 1 shadow_resin | petal_shield |

Static funcs: get_recipe, get_all_recipe_ids, get_materials, get_display_name, is_upgrade, get_upgrade_base.

## Part 3 — CraftingManager Autoload

**New file:** `crafting/scripts/crafting_manager.gd` extends Node
**Autoload:** `CraftingManager="*res://crafting/scripts/crafting_manager.gd"` after InventoryManager in project.godot.

**Signals:** `weapon_crafted(weapon_id: String)`, `craft_failed(reason: String)`

**State:** `var owned_weapons: Dictionary = {"thorn_sword": true}` — player starts with Thorn Sword (GDD §14).

**API:**

- `can_craft(recipe_id) -> bool` — recipe exists + materials in inventory + (if upgrade) owns base weapon + result not already owned
- `craft(recipe_id) -> bool` — deducts materials via InventoryManager.remove_item(), if upgrade erases base from owned_weapons, adds result, emits weapon_crafted
- `owns_weapon(weapon_id) -> bool`
- `get_owned_weapon_ids() -> Array`
- `get_weapon_data(weapon_id) -> WeaponData` — loads .tres from WEAPON_DATA_PATHS dict

**WEAPON_DATA_PATHS constant:**

- thorn_sword -> res://combat/weapons/thorn_sword/thorn_sword_data.tres
- spore_bomb -> res://combat/weapons/spore_bomb/spore_bomb_data.tres
- vine_whip -> res://combat/weapons/vine_whip/vine_whip_data.tres
- petal_shield -> res://combat/weapons/petal_shield/petal_shield_data.tres
- blazeblade -> res://combat/weapons/thorn_sword/blazeblade_data.tres
- void_grenade -> res://combat/weapons/spore_bomb/void_grenade_data.tres
- crystal_lash -> res://combat/weapons/vine_whip/crystal_lash_data.tres
- iron_bloom_shield -> res://combat/weapons/petal_shield/iron_bloom_shield_data.tres

**Serialization:** `serialize() -> Dictionary` returns owned_weapons.duplicate(). `deserialize(data)` restores, always ensuring thorn_sword default.

## Part 4 — WeaponData Resources

**Modify** `combat/weapons/weapon_data.gd` — add `@export var weapon_id: String = ""`.

**Update** `thorn_sword_data.tres` — add `weapon_id = "thorn_sword"`.

**Create 7 new .tres files** with placeholder stats (actual combat behavior is TODO: PLANT-09/10/11):

| weapon_id | file | damage | cooldown | range | arc |
|-----------|------|--------|----------|-------|-----|
| spore_bomb | spore_bomb/spore_bomb_data.tres | 20 | 2.0 | 80.0 | 360.0 |
| vine_whip | vine_whip/vine_whip_data.tres | 12 | 0.7 | 40.0 | 45.0 |
| petal_shield | petal_shield/petal_shield_data.tres | 5 | 0.3 | 16.0 | 180.0 |
| blazeblade | thorn_sword/blazeblade_data.tres | 20 | 0.4 | 24.0 | 90.0 |
| void_grenade | spore_bomb/void_grenade_data.tres | 30 | 2.5 | 96.0 | 360.0 |
| crystal_lash | vine_whip/crystal_lash_data.tres | 18 | 0.6 | 48.0 | 45.0 |
| iron_bloom_shield | petal_shield/iron_bloom_shield_data.tres | 8 | 0.3 | 16.0 | 180.0 |

Each .tres follows existing pattern:
```
[gd_resource type="Resource" script_class="WeaponData" load_steps=2 format=3]
[ext_resource type="Script" path="res://combat/weapons/weapon_data.gd" id="1_wdata"]
[resource]
script = ExtResource("1_wdata")
weapon_id = "spore_bomb"
weapon_name = "Spore Bomb"
damage = 20
cooldown = 2.0
attack_range = 80.0
arc_degrees = 360.0
```

## Part 5 — Breeding Bench Entity

**New files:** `crafting/bench/breeding_bench.gd`, `crafting/bench/breeding_bench.tscn`

**Scene tree:**
```
BreedingBench (StaticBody2D)
  +-- Sprite2D (placeholder brown 32x16 ColorRect)
  +-- CollisionShape2D (RectangleShape2D 32x16)
  +-- InteractionZone (Area2D, collision_layer=0, collision_mask=4 player)
  |     +-- CollisionShape2D (CircleShape2D radius 20)
  +-- PromptLabel (Label "Press E", font_size 8, visible=false, position above bench)
```

**Behaviour:**
1. collision_layer = CollisionLayers.INTERACTABLE (1), collision_mask = 0
2. InteractionZone detects player proximity (mask = PLAYER layer 3)
3. Player enters zone -> show "Press E" label. Player exits -> hide label.
4. On `interact` action pressed (E key) while player in range:
   - If `DayNightCycle.is_night()` -> print warning, return
   - Else -> find CraftingScreen in scene tree via `find_child("CraftingScreen")`, call `screen.open()`
5. **Add `interact` input action** to project.godot — Key E (physical_keycode 69)

**Place bench in meadow_edge.tscn** near the Dianthus Core (garden area), e.g. position (64, -32) relative to core.

## Part 6 — Crafting UI Screen

**New files:** `ui/screens/crafting_screen.gd`, `ui/screens/crafting_screen.tscn`

Follows same pattern as inventory_screen.gd/.tscn (CanvasLayer, layer 91, PROCESS_MODE_ALWAYS).

**Layout (640x360 viewport):**
```
CraftingScreen (CanvasLayer layer=91)
  +-- Overlay (ColorRect black alpha 0.6, full screen)
  +-- Panel (centered ~320x280)
      +-- MarginContainer (margins 8)
          +-- VBoxContainer
              +-- TitleLabel ("CRAFTING")
              +-- RecipeList (VBoxContainer, scrollable)
              +-- DescriptionLabel (bottom, wraps, shows selected recipe info)
              +-- CraftButton (Button "CRAFT", disabled when can't craft)
```

**Recipe list items:** Each recipe row is an HBoxContainer:
- Label: recipe display_name (bold if craftable, grey if not)
- Label: material cost summary (e.g. "3x Petal Shard, 2x Verdant Sap")
- If upgrade: show "[Upgrade]" tag
- If already owned: show "[Owned]" tag, greyed out
- Selected recipe highlighted with accent color border

**Behaviour:**
1. `open()` / `close()` methods — open builds recipe list, close hides
2. Clicking a recipe row selects it, shows description + material details below
3. Materials player has enough of shown in green, insufficient in red
4. "CRAFT" button enabled only when `CraftingManager.can_craft(selected_recipe_id)` is true
5. On craft button press: call `CraftingManager.craft(selected_recipe_id)`, play brief "crafted!" feedback (label flash), refresh list
6. Close with Escape key or clicking outside panel
7. While open, game input is suppressed (get_tree().paused or input guard)

**Connect to `CraftingManager.weapon_crafted`** -> refresh list.
**Connect to `InventoryManager.inventory_changed`** -> refresh material availability display.

## Part 7 — Save/Load Integration

**Modify** `save/scripts/save_manager.gd`:

1. **`_gather_state()`** — add: `state["crafting"] = CraftingManager.serialize()`
2. **`_apply_state()`** — add after inventory restore: `CraftingManager.deserialize(state.get("crafting", {}))`
3. **`_migrate()`** — add v2->v3: if "crafting" key missing, add `{"thorn_sword": true}` default. Bump SCHEMA_VERSION to 3.
4. Also save equipped weapon id: `state["player"]["equipped_weapon"] = player._current_weapon.weapon_id if player._current_weapon else "thorn_sword"`
5. On load, restore equipped weapon via `CraftingManager.get_weapon_data()`.

## Part 8 — Player Weapon Switching

**Modify** `player/scripts/player_controller.gd`:

After crafting a weapon, the player should be able to equip it. For the vertical slice:

1. On `CraftingManager.weapon_crafted` signal: auto-equip the newly crafted weapon by loading its WeaponData from CraftingManager.get_weapon_data() and assigning to `_current_weapon`.
2. The existing attack system in player_controller.gd already uses `_current_weapon.damage` and `_current_weapon.cooldown` — new weapons will work automatically for basic melee. TODO: PLANT-09/10/11 for unique weapon behaviors (projectile, pull, block).
3. Currently `_ready()` hardcodes loading thorn_sword_data.tres. Change this to: `_current_weapon = CraftingManager.get_weapon_data("thorn_sword")` so it uses the registry.

## Part 9 — Debug Keys

Add to `player_controller.gd` debug key block:

| Key | Action |
|-----|--------|
| Shift+F13 | Add 1 of each crafting extract (bougainvillea_extract, rafflesia_extract, beringin_root, kecombrang_extract, kunyit_extract) + 5 petal_shard + 5 verdant_sap + 3 moonspore + 2 shadow_resin — enough to test all base weapon recipes |
| C | Toggle crafting screen directly (bypass bench proximity, for testing) |

Add `crafting_toggle` input action to project.godot — Key C (physical_keycode 67). Guard behind a `#DEBUG` comment.

---

## Existing Code — Files to READ Before Implementing

| File | Why |
|------|-----|
| `inventory/data/item_database.gd` | Add new extract items here |
| `inventory/scripts/inventory_manager.gd` | Used for has_item/remove_item/add_item |
| `combat/weapons/weapon_data.gd` | Add weapon_id field |
| `combat/weapons/thorn_sword/thorn_sword_data.tres` | Template for new .tres files |
| `save/scripts/save_manager.gd` | Save integration — schema v2->v3 |
| `player/scripts/player_controller.gd` | Weapon equip, debug keys, attack system |
| `shared/autoloads/game_manager.gd` | Signals, player ref |
| `core/day_night/day_night_cycle.gd` | is_night() check for bench |
| `shared/collision_layers.gd` | Layer constants |
| `ui/screens/inventory_screen.gd` | Pattern reference for crafting UI |
| `project.godot` | Autoloads, input actions |

## Files to CREATE

| File | Description |
|------|-------------|
| `crafting/data/recipe_database.gd` | Static recipe registry (class_name RecipeDatabase) |
| `crafting/scripts/crafting_manager.gd` | Autoload — weapon ownership + craft logic |
| `crafting/bench/breeding_bench.gd` | Bench interaction script |
| `crafting/bench/breeding_bench.tscn` | Bench scene (StaticBody2D + Area2D) |
| `ui/screens/crafting_screen.gd` | Crafting UI script |
| `ui/screens/crafting_screen.tscn` | Crafting UI scene (CanvasLayer) |
| `combat/weapons/spore_bomb/spore_bomb_data.tres` | Weapon stats |
| `combat/weapons/vine_whip/vine_whip_data.tres` | Weapon stats |
| `combat/weapons/petal_shield/petal_shield_data.tres` | Weapon stats |
| `combat/weapons/thorn_sword/blazeblade_data.tres` | Upgrade stats |
| `combat/weapons/spore_bomb/void_grenade_data.tres` | Upgrade stats |
| `combat/weapons/vine_whip/crystal_lash_data.tres` | Upgrade stats |
| `combat/weapons/petal_shield/iron_bloom_shield_data.tres` | Upgrade stats |

## Files to MODIFY

| File | Change |
|------|--------|
| `inventory/data/item_database.gd` | Add 5 extract items to ITEMS dict |
| `combat/weapons/weapon_data.gd` | Add weapon_id export var |
| `combat/weapons/thorn_sword/thorn_sword_data.tres` | Add weapon_id = "thorn_sword" |
| `project.godot` | Add CraftingManager autoload + interact/crafting_toggle input actions |
| `save/scripts/save_manager.gd` | Schema v3: serialize/deserialize crafting + equipped weapon |
| `player/scripts/player_controller.gd` | Weapon equip from CraftingManager, debug keys, connect weapon_crafted |
| `world/zones/meadow_edge/meadow_edge.tscn` | Instance BreedingBench + CraftingScreen |
| `docs/design/PERSON_TASKS.md` | Mark PLANT-06/Bench Crafting done, update file lists + debug keys |

---

## Constraints

1. **No new addons** — pure GDScript, no plugins
2. **Pixel-art friendly** — UI sizes multiples of 8, font_size 8 for labels
3. **640x360 viewport** — crafting panel must fit
4. **Save compat** — _migrate() handles v2 saves missing "crafting" key
5. **GDD §7.3 instant crafting** — no crafting timer, recipes complete immediately
6. **Do NOT implement** actual weapon behaviors (projectile, pull, block) — those are PLANT-09/10/11. Only create the WeaponData .tres with stats.
7. **Do NOT implement** the Crafting Assembly minigame (MINI-02) — that's separate
8. Leave `TODO: <TASK-ID>` stubs for deferred work:
   - `TODO: PLANT-08` — loadout system (2 weapon + 1 skill slots)
   - `TODO: PLANT-09` — spore bomb projectile behavior
   - `TODO: PLANT-10` — vine whip pull mechanic
   - `TODO: PLANT-11` — petal shield block mechanic
   - `TODO: MINI-02` — crafting assembly minigame integration

---

## Acceptance Criteria

- [ ] RecipeDatabase has all 8 recipes, static funcs work
- [ ] CraftingManager autoload: can_craft/craft/owns_weapon all functional
- [ ] ItemDatabase has 5 new extract items
- [ ] 8 WeaponData .tres files exist with correct stats
- [ ] weapon_data.gd has weapon_id field; thorn_sword_data.tres updated
- [ ] Breeding Bench in meadow_edge: walk near it -> "Press E" appears -> press E -> crafting UI opens
- [ ] Bench blocked during night phase
- [ ] Crafting UI: lists all 8 recipes, shows materials with have/need colors
- [ ] Craft button works: deducts materials, grants weapon, updates owned status
- [ ] Upgrade recipes: require owning base weapon, consume it on upgrade
- [ ] Already-owned weapons shown as "[Owned]", not re-craftable
- [ ] Newly crafted weapon auto-equips on player
- [ ] Save/Load round-trip: owned weapons persist correctly
- [ ] Old v2 saves load with migration (default thorn_sword ownership)
- [ ] Debug key adds test materials; C key opens crafting UI directly
- [ ] No errors in Godot console on startup, bench interaction, craft, save, load
