# PROMPT — Inventory System (CORE-02 + UI-02)

**Task IDs:** CORE-02 (Resource Pickup System), UI-02 (Inventory Screen 30-Slot Grid)  
**GDD Sections:** §6.1, §6.2, §6.3, §11.2  
**Priority:** Critical  
**Dependencies:** FOUND-01..06 (Done), CORE-03 (Done), CORE-09 (Done), SAVE-01/02 (Done)

---

## Goal

Implement the **full inventory system** for Dianthus Pixie: a data-driven inventory manager, world resource pickups, a 30-slot grid inventory UI, and all the wiring needed so the existing save system, night-reward screen, and future crafting systems can read/write inventory correctly.

---

## Scope — What to Build

### Part 1 — Inventory Data Layer (`InventoryManager` autoload)

Create a new autoload `InventoryManager` at `inventory/scripts/inventory_manager.gd` that **replaces** the current raw `GameManager.player_data["inventory"]` dictionary with a proper slot-based system.

**Requirements (GDD §6.2):**

- **30 slots** (expandable to 60 via future Garden Storage upgrade — use a `var max_slots: int = 30`)
- **Stack limits** per rarity:
  - Common → 99 per slot
  - Uncommon → 20 per slot
  - Rare → 5 per slot
- Resources **do not expire** (GDD §6.2)
- On death, **resources are NOT lost** — only energy is deducted (GDD §5.1 / §6.3)

**Data structures:**

```gdscript
# inventory/data/item_database.gd  (class_name ItemDatabase, extends Resource)
# A static registry of all known resource types.

enum Rarity { COMMON, UNCOMMON, RARE }

const ITEMS: Dictionary = {
    "petal_shard":    { "display_name": "Petal Shard",    "rarity": Rarity.COMMON,   "max_stack": 99, "description": "Common flower petal used for basic crafting." },
    "verdant_sap":    { "display_name": "Verdant Sap",    "rarity": Rarity.COMMON,   "max_stack": 99, "description": "Sticky sap extracted from trees and shrubs." },
    "moonspore":      { "display_name": "Moonspore",      "rarity": Rarity.UNCOMMON, "max_stack": 20, "description": "Nocturnal spore that appears only at night." },
    "shadow_resin":   { "display_name": "Shadow Resin",   "rarity": Rarity.UNCOMMON, "max_stack": 20, "description": "Dark residue dropped by elite enemies." },
    "aether_bloom":   { "display_name": "Aether Bloom",   "rarity": Rarity.RARE,     "max_stack": 5,  "description": "Precious bloom found in hidden chests and quest rewards." },
    "dianthus_pollen":{ "display_name": "Dianthus Pollen", "rarity": Rarity.RARE,    "max_stack": 5,  "description": "Sacred pollen harvested from the Dianthus Core once per day." },
}

static func get_item(item_id: String) -> Dictionary:
    return ITEMS.get(item_id, {})

static func get_max_stack(item_id: String) -> int:
    return ITEMS.get(item_id, {}).get("max_stack", 99)

static func get_rarity(item_id: String) -> Rarity:
    return ITEMS.get(item_id, {}).get("rarity", Rarity.COMMON)
```

```gdscript
# inventory/scripts/inventory_manager.gd  (autoload: InventoryManager)
extends Node

signal inventory_changed                     # emitted on ANY add/remove/swap
signal item_added(item_id: String, amount: int)  # emitted per successful add
signal item_removed(item_id: String, amount: int)
signal inventory_full                         # emitted when add fails due to no space

var max_slots: int = 30

# Slots array — each element is { "item_id": String, "count": int } or empty {}
var slots: Array[Dictionary] = []

func _ready() -> void:
    _init_slots()

func _init_slots() -> void:
    slots.clear()
    for i in range(max_slots):
        slots.append({})

# --- Public API ---

func add_item(item_id: String, amount: int = 1) -> int:
    # Returns the number of items that could NOT be added (overflow).
    # 1. Try stacking into existing slots that already hold this item.
    # 2. Then fill empty slots.
    # Respect max_stack from ItemDatabase.
    ...

func remove_item(item_id: String, amount: int = 1) -> bool:
    # Returns true if the full amount was removed.
    ...

func has_item(item_id: String, amount: int = 1) -> bool:
    # Check if total count across all slots >= amount.
    ...

func get_total_count(item_id: String) -> int:
    ...

func get_slot(index: int) -> Dictionary:
    ...

func swap_slots(a: int, b: int) -> void:
    ...

func clear_all() -> void:
    ...

# --- Serialization (for SaveManager) ---

func serialize() -> Array:
    # Returns array of {"item_id": ..., "count": ...} or {} for empty slots.
    return slots.duplicate(true)

func deserialize(data: Array) -> void:
    # Restores slots from saved array.
    ...
```

**Autoload registration:** Add `InventoryManager="*res://inventory/scripts/inventory_manager.gd"` to `project.godot` `[autoload]` section, **after** `SaveManager`.

---

### Part 2 — Item Database Resource

Create `inventory/data/item_database.gd` with the static `ITEMS` dictionary above.

This is a pure-data file with static functions — no extends Resource needed, just a script with `class_name ItemDatabase`.

---

### Part 3 — Resource Pickup Nodes (CORE-02)

Create a reusable pickup scene and script:

**Files:**
- `inventory/pickups/resource_pickup.gd`
- `inventory/pickups/resource_pickup.tscn`

**Behaviour:**
1. `Area2D` root node with `CollisionShape2D` (small circle, radius ~8px) + `Sprite2D` (placeholder colored square per item — use the item's rarity to pick a color: Common=white, Uncommon=blue, Rare=gold)
2. `@export var item_id: String = "petal_shard"`
3. `@export var amount: int = 1`
4. On `body_entered` with the player (collision layer 3 = player):
   - Call `InventoryManager.add_item(item_id, amount)`
   - If overflow > 0, show "Inventory Full!" and do NOT destroy the pickup
   - If success, play a floating "+N Item Name" popup label (tween `position:y` -20px, `modulate:a` → 0 over 0.8s, then `queue_free()`)
   - `queue_free()` the pickup node
5. Add to group `"pickups"` for potential later use
6. Collision setup: pickup detects layer 3 (player), pickup itself lives on layer 1 (interactable)

**Place sample pickups in `meadow_edge.tscn`:**
- 5× Petal Shard pickups scattered in walkable areas
- 3× Verdant Sap pickups near trees/garden edge

---

### Part 4 — Inventory Screen UI (UI-02)

**Files:**
- `ui/screens/inventory_screen.gd`
- `ui/screens/inventory_screen.tscn`

**Requirements (GDD §6.2 / §11.2):**
- **30-slot grid** (6 columns × 5 rows) — each slot is a `PanelContainer` (40×40px) inside a `GridContainer`
- Each slot shows: item color/icon placeholder + stack count label (bottom-right)
- Empty slots show a dark/transparent background
- Open/close with **I** key (`inventory_toggle` input action)
- Wrap in a `CanvasLayer` (layer 90) so it renders above gameplay
- Dark semi-transparent background overlay (`ColorRect`, black alpha 0.6)
- Title label: "INVENTORY" at the top
- **process_mode = PROCESS_MODE_ALWAYS** so it works even if game is paused

**Slot display rules:**
- Slot has item → show rarity-colored panel + count label
- Slot empty → show grey panel, no label
- Tooltip/hover: display item `display_name` + `description` (simple Label that follows mouse or appears on hover — keep it simple)

**Refresh logic:**
- Connect to `InventoryManager.inventory_changed` → call `_refresh()`
- On `_toggle()` visible → also `_refresh()`

**Input action to add in `project.godot`:**
```
inventory_toggle → Key: I (physical_keycode 73)
```

**Instance the scene in `meadow_edge.tscn`** alongside existing HUD/PauseMenu/etc.

---

### Part 5 — Integration & Wiring

#### 5a. GameManager migration

`GameManager.player_data["inventory"]` currently stores a flat `{}` dict. After this task:
- **Keep** `player_data["inventory"]` as a **mirror/legacy bridge** — OR remove it entirely and point all callers to `InventoryManager`.
- Recommended: remove the `"inventory": {}` key from `player_data` and have everything go through `InventoryManager` directly.

#### 5b. SaveManager integration

Modify `save/scripts/save_manager.gd`:

- **`_gather_state()`** — replace:
  ```gdscript
  state["inventory"] = GameManager.player_data.get("inventory", {}).duplicate()
  ```
  with:
  ```gdscript
  state["inventory"] = InventoryManager.serialize()
  ```

- **`_apply_state()`** — replace:
  ```gdscript
  GameManager.player_data["inventory"] = state.get("inventory", {}).duplicate()
  ```
  with:
  ```gdscript
  InventoryManager.deserialize(state.get("inventory", []))
  ```

- **`_migrate()`** — add v1→v2 migration: if old inventory is a flat Dictionary (`{ "petal_shard": 5 }`), convert it into the new slots Array format. Bump `SCHEMA_VERSION` to `2`.

#### 5c. Night Survived Rewards

Modify `ui/screens/night_survived_screen.gd`:
- In `_generate_rewards_text()`, **actually add** items to inventory:
  ```gdscript
  InventoryManager.add_item("petal_shard", common_count)
  InventoryManager.add_item("verdant_sap", 1)
  ```
- Remove the `# TODO (CORE-02)` comment.

#### 5d. Resolve the TODO in SaveManager

In `_apply_state()` step 5, the comment says:
```
# TODO (QUEST-01): Emit inventory_changed signal here when pickup UI exists.
```
Now that InventoryManager exists, the `deserialize()` function should emit `inventory_changed` at the end. Update/remove this TODO.

---

### Part 6 — Debug Key

Add a debug key for testing:

| Key | Action |
|-----|--------|
| **F13** (or **Shift+I**) | Add 5 Petal Shard + 2 Verdant Sap + 1 Moonspore to inventory (test) |

Add this in `player_controller.gd` alongside existing F1–F12 debug keys.

---

## Existing Code Context

### Files you MUST read before implementing:

| File | Why |
|------|-----|
| `shared/autoloads/game_manager.gd` | Current `player_data["inventory"]` dict — will be migrated |
| `save/scripts/save_manager.gd` | Lines 172-173 (gather), 258-260 (apply), 313-327 (migrate) — need changes |
| `ui/screens/night_survived_screen.gd` | Line 29 TODO — needs actual inventory calls |
| `project.godot` | Autoload list, input actions — need additions |
| `world/zones/meadow_edge/meadow_edge.tscn` | Scene tree — need to instance InventoryScreen + pickup nodes |
| `world/zones/meadow_edge/meadow_edge.gd` | Zone script — may need minor changes |
| `ui/hud/hud.gd` | Reference for signal pattern + CanvasLayer structure |
| `player/scripts/player_controller.gd` | Debug key block — add new debug key |

### Files you will CREATE:

| File | Description |
|------|-------------|
| `inventory/data/item_database.gd` | Static item registry (class_name ItemDatabase) |
| `inventory/scripts/inventory_manager.gd` | Autoload — slot-based inventory logic |
| `inventory/pickups/resource_pickup.gd` | Reusable pickup script |
| `inventory/pickups/resource_pickup.tscn` | Pickup scene (Area2D + Sprite2D + CollisionShape2D) |
| `ui/screens/inventory_screen.gd` | Inventory UI script |
| `ui/screens/inventory_screen.tscn` | Inventory UI scene (CanvasLayer + GridContainer) |

### Files you will MODIFY:

| File | Change |
|------|--------|
| `project.godot` | Add InventoryManager autoload + `inventory_toggle` input action |
| `save/scripts/save_manager.gd` | Serialize/deserialize via InventoryManager; schema v1→v2 migration |
| `shared/autoloads/game_manager.gd` | Remove or deprecate `player_data["inventory"]` |
| `ui/screens/night_survived_screen.gd` | Actually add reward items to inventory |
| `world/zones/meadow_edge/meadow_edge.tscn` | Instance InventoryScreen + sample pickup nodes |
| `player/scripts/player_controller.gd` | Add inventory debug key |
| `docs/design/PERSON_TASKS.md` | Mark CORE-02 and UI-02 as done, update file lists |

---

## Constraints

1. **No new dependencies** — pure GDScript, no addons
2. **Pixel-art friendly** — all UI sizes should be multiples of 8, font_size 8 for slot counts
3. **640×360 viewport** — inventory grid must fit within this resolution
4. **Save compatibility** — the `_migrate()` function must handle loading old v1 saves that have `inventory` as a flat Dictionary and converting them to the new slot Array format
5. **Do NOT touch** any plant, enemy, combat, or day-night code unless necessary for wiring
6. Leave `TODO: <TASK-ID>` stubs for explicitly deferred work (e.g., `TODO: PLANT-06` for crafting deduction, `TODO: WORLD-06` for storage expansion, `TODO: MINI-03` for harvest QTE)

---

## Acceptance Criteria

- [ ] `InventoryManager` autoload works: `add_item()`, `remove_item()`, `has_item()`, `get_total_count()`, `serialize()`, `deserialize()`
- [ ] Stack limits enforced: Common 99, Uncommon 20, Rare 5
- [ ] 30-slot cap enforced: adding items past capacity emits `inventory_full` and returns overflow
- [ ] Pickup nodes in Meadow Edge: walk over them → item added → floating popup → node removed
- [ ] Inventory Full: walk over pickup when inventory is full → pickup stays, "Inventory Full!" shown
- [ ] Press I → 30-slot grid UI opens/closes; shows current items with count
- [ ] Night survived screen actually adds Petal Shard + Verdant Sap to inventory
- [ ] Save/Load round-trip: save game → load game → inventory contents are identical
- [ ] Old v1 saves load correctly (migration converts flat dict → slot array)
- [ ] Debug key adds test items to inventory
- [ ] No errors in Godot console on startup, pickup, open/close inventory, save, load
