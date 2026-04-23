# PROMPT — PLANT-08: Loadout System (2 Weapons + 1 Skill Slot)

**Task ID:** PLANT-08  
**Category:** Player  
**Priority:** High  
**Effort:** M (1–3 days)  
**Dependencies:** CORE-05 (Thorn Sword — done), PLANT-06 (Crafting — done), PLANT-07 (Energy System — done)  
**GDD Reference:** §9.2 — "Pemain bisa equip 2 senjata aktif secara bersamaan (hotbar slot 1 & 2); Satu slot skill aktif; Loadout hanya bisa diganti di Preparation Phase (sore hari) atau di Garden Base; Saat malam berlangsung, loadout dikunci"  
**GDD Reference:** §11.1 — "Hotbar Senjata — pojok kanan bawah, 2 slot senjata + 1 slot skill aktif"  
**GDD Reference:** §13.3 — "Skill aktif tanaman: 20-50 energi tergantung tanaman; Skill karakter khusus: 30 energi per aktivasi"

---

## Goal

Replace the single-weapon system with a full loadout: **2 weapon slots** (hotbar 1 & 2) plus **1 active skill slot**. The player swaps weapons via hotkeys and activates the skill slot with a dedicated key. Loadout changes are **locked during Night phase** — swapping is only allowed during DAY (Exploration/Preparation). A **HUD hotbar** in the bottom-right displays the three slots.

---

## Scope

### In Scope
1. **Loadout data structure** on the player — 2 weapon slots + 1 active skill slot
2. **Weapon swap input** — keys `1` and `2` to select weapon slot; only the selected slot is used for `attack` action
3. **Active skill input** — key `Q` to fire the active skill (costs energy via `try_spend_energy`)
4. **Loadout lock** — during Night phase (`DayNightCycle.is_night()`), weapon/skill swap is blocked; a brief HUD feedback message ("Loadout locked!") appears
5. **Loadout Screen** — a dedicated UI (key `L`) to assign owned weapons to the 2 weapon slots and select an active skill from placed plants
6. **HUD Hotbar** — 3 visual slots (bottom-right) showing currently equipped weapon names/icons with selection highlight; the skill slot shows energy cost
7. **Save/load integration** — persist loadout in save file (schema version bump to **7**)
8. **Signal forwarding** — `GameManager.loadout_changed` signal for HUD/UI refresh

### Out of Scope
- Actual Spore Bomb / Vine Whip / Petal Shield weapon **behaviors** (PLANT-09, PLANT-10, PLANT-11 — leave `TODO` stubs)
- Complex active skill effects beyond a generic energy-spending placeholder
- Weapon drag-and-drop in the loadout screen (simple click-to-assign is sufficient)
- UI-01 full HUD overhaul (we add the hotbar panel, but minimap/wave counter stay out)

---

## Existing Architecture Reference

### Current Weapon System — `player/scripts/player_controller.gd`

- Single `_current_weapon: WeaponData` variable set in `_ready()` to `thorn_sword`
- `_on_weapon_crafted(weapon_id)` auto-equips the last crafted weapon
- `_start_attack()` / `_end_attack()` use `_current_weapon.damage`, `_current_weapon.cooldown`
- `try_spend_energy(amount) -> bool` exists with a `TODO (PLANT-08)` stub at line 365

### WeaponData Resource — `combat/weapons/weapon_data.gd`

```gdscript
class_name WeaponData
extends Resource

@export var weapon_id: String = ""
@export var weapon_name: String = ""
@export var damage: int = 0
@export var cooldown: float = 0.5
@export var attack_range: float = 24.0
@export var arc_degrees: float = 90.0
```

### CraftingManager — `crafting/scripts/crafting_manager.gd`

- `owned_weapons: Dictionary` — keys are weapon_id strings, values are `true`
- `get_owned_weapon_ids() -> Array` — returns list of owned weapon IDs
- `get_weapon_data(weapon_id) -> WeaponData` — loads from `WEAPON_DATA_PATHS`
- `weapon_crafted(weapon_id)` signal — emitted on successful craft
- 8 weapons total: `thorn_sword`, `spore_bomb`, `vine_whip`, `petal_shield` (base) + `blazeblade`, `void_grenade`, `crystal_lash`, `iron_bloom_shield` (upgrades)

### DayNightCycle — `core/day_night/day_night_cycle.gd`

- `is_night() -> bool` / `is_day() -> bool`
- `phase_changed(phase: String)` signal
- Only two phases: `DAY` and `NIGHT`

### Save Schema

- Current version: **6**
- `state["player"]["equipped_weapon"]` stores a single weapon_id string
- Must be expanded to store full loadout (2 weapon IDs + 1 skill ID)

### HUD — `ui/hud/hud.gd` + `ui/hud/hud.tscn`

- CanvasLayer (layer=10)
- Player HP (top-left), Core HP (top-center), Energy (below player HP)
- **No hotbar exists yet** — the bottom-right corner is unused

### Existing UI Layer Assignments

| Layer | Screen |
|-------|--------|
| 10 | HUD |
| 80 | PlantPaletteUI |
| 90 | InventoryScreen |
| 91 | CraftingScreen |
| 92 | CrossBreedingScreen |
| 93 | CodexScreen |

Use **layer 94** for the Loadout Screen.

### Input Actions (project.godot)

Currently used keys: W/A/S/D (move), Space/LMB (attack), I (inventory), E (interact), C (crafting), B (breeding), P (plant mode), J (codex), F1–F12/Insert (debug).

Available for this task:
- `1` (physical_keycode=49) — select weapon slot 1
- `2` (physical_keycode=50) — select weapon slot 2
- `Q` (physical_keycode=81) — activate skill
- `L` (physical_keycode=76) — open/close loadout screen

---

## Implementation Plan

### 1. Extend Player Controller — `player/scripts/player_controller.gd`

Replace the single-weapon model with a loadout:

```gdscript
# --- Loadout ---
const WEAPON_SLOT_COUNT: int = 2
var weapon_slots: Array[String] = ["thorn_sword", ""]  # weapon_id per slot
var active_skill_id: String = ""  # plant_id whose skill is bound
var selected_weapon_slot: int = 0  # 0 or 1
var _current_weapon: WeaponData = null  # derived from weapon_slots[selected_weapon_slot]
```

**Key changes:**
- `_ready()` — load `_current_weapon` from `weapon_slots[0]` via CraftingManager.get_weapon_data()
- `_unhandled_input()` — handle new actions:
  - `hotbar_weapon_1` → `select_weapon_slot(0)` (if DAY, or always for selecting — only equip/assign is locked)
  - `hotbar_weapon_2` → `select_weapon_slot(1)`
  - `activate_skill` → `_activate_skill()`
  - `loadout_toggle` → open/close LoadoutScreen
- `select_weapon_slot(index: int)` — set `selected_weapon_slot`, update `_current_weapon` from `weapon_slots[index]`, emit signal
- `_activate_skill()` — if `active_skill_id.is_empty()`: print warning; otherwise call `try_spend_energy(skill_cost)` and fire a placeholder effect; `TODO (PLANT-09/10/11)` for real skill effects
- `equip_weapon(slot: int, weapon_id: String)` — public API; blocked if `DayNightCycle.is_night()` (print "Loadout locked!" + emit signal for HUD feedback); updates `weapon_slots[slot]` and refreshes `_current_weapon` if `slot == selected_weapon_slot`
- `set_active_skill(skill_id: String)` — public API; same night-lock behavior; sets `active_skill_id`
- `_on_weapon_crafted(weapon_id)` — auto-equip into first empty slot (or slot 0 if full); skip if night

**Loadout signal:**

```gdscript
signal loadout_changed(weapon_slots: Array, skill_id: String, selected_slot: int)
```

Emit in `select_weapon_slot`, `equip_weapon`, `set_active_skill`.

### 2. Forward Signal via GameManager — `shared/autoloads/game_manager.gd`

Add signal forwarding so HUD can listen:

```gdscript
signal loadout_changed(weapon_slots: Array, skill_id: String, selected_slot: int)
```

In `register_player()`, connect the player's `loadout_changed` signal to `GameManager.loadout_changed`.

### 3. Loadout Screen — `ui/screens/loadout_screen.gd` + `loadout_screen.tscn`

**Layout (640x360 viewport):**

```
CanvasLayer (layer=94, PROCESS_MODE_ALWAYS)
+-- Overlay (ColorRect, dark semi-transparent)
+-- Panel (centered, ~300x220)
    +-- MarginContainer
        +-- VBoxContainer
            +-- TitleLabel — "LOADOUT"
            +-- HSeparator
            +-- WeaponSection (VBoxContainer)
            |   +-- Label "WEAPONS"
            |   +-- HBoxContainer
            |       +-- Slot1Panel (PanelContainer, %Slot1)
            |       |   +-- VBox: Label "1" + WeaponLabel
            |       +-- Slot2Panel (PanelContainer, %Slot2)
            |           +-- VBox: Label "2" + WeaponLabel
            +-- HSeparator
            +-- SkillSection (VBoxContainer)
            |   +-- Label "ACTIVE SKILL"
            |   +-- SkillPanel (PanelContainer, %SkillSlot)
            |       +-- HBox: SkillLabel + CostLabel
            +-- HSeparator
            +-- OwnedWeaponsSection (VBoxContainer)
            |   +-- Label "OWNED WEAPONS"
            |   +-- OwnedList (VBoxContainer, %OwnedList)
            |       +-- Per weapon: PanelContainer row (clickable)
            +-- HSeparator
            +-- CloseHint — "Press L to close"
```

**Behavior:**
- **L** key toggles open/close; pauses game tree on open
- On open, builds owned weapons list from `CraftingManager.get_owned_weapon_ids()`
- Each owned weapon row is clickable → shows "Assign to Slot 1 / Slot 2" sub-buttons (or a simple two-button prompt)
- Clicking "Assign to Slot X" calls `GameManager.player.equip_weapon(slot, weapon_id)`
- If night: all assign buttons are disabled; a red "LOCKED (Night)" label shown
- Current slot assignments highlighted with gold border
- **Skill slot:** For this task, display `active_skill_id` if set. Skill assignment is a placeholder — the player can select from a hardcoded set of skill names or leave it empty. Full skill catalog depends on PLANT-09/10/11.
- Connects to `GameManager.loadout_changed` to refresh display

**Night-lock visual feedback:**
- On `DayNightCycle.phase_changed`, if entering NIGHT, disable all assignment controls + show a "Loadout Locked" overlay text on the panel. On DAY, re-enable.

### 4. Active Skill System (Placeholder)

For now, define a minimal skill data structure. The skill slot uses energy from the PLANT-07 system.

```gdscript
# In player_controller.gd
const SKILL_ENERGY_COST: int = 30  # GDD §13.3: "Skill karakter khusus: 30 energi per aktivasi"

func _activate_skill() -> void:
    if active_skill_id.is_empty():
        print("[Player] No active skill equipped.")
        return
    if not try_spend_energy(SKILL_ENERGY_COST):
        print("[Player] Not enough energy for skill. Need %d, have %d." % [SKILL_ENERGY_COST, current_energy])
        return
    print("[Player] Activated skill: %s (-%d energy)" % [active_skill_id, SKILL_ENERGY_COST])
    # TODO (PLANT-09): Spore Bomb skill behavior.
    # TODO (PLANT-10): Vine Whip skill behavior.
    # TODO (PLANT-11): Petal Shield skill behavior.
```

### 5. HUD Hotbar — `ui/hud/hud.gd` + `ui/hud/hud.tscn`

Add a hotbar panel to the **bottom-right** of the HUD:

```
HotbarContainer (MarginContainer, bottom-right anchored)
+-- HBoxContainer
    +-- WeaponSlot1 (PanelContainer, 32x32)
    |   +-- VBox: KeyLabel "1" + NameLabel
    +-- WeaponSlot2 (PanelContainer, 32x32)
    |   +-- VBox: KeyLabel "2" + NameLabel
    +-- SkillSlot (PanelContainer, 32x32)
        +-- VBox: KeyLabel "Q" + NameLabel + CostLabel
```

**Style:**
- Dark background `StyleBoxFlat` (Color(0.1, 0.1, 0.1, 0.8)), rounded corners
- Selected weapon slot: gold border (Color(0.9, 0.75, 0.2, 1))
- Unselected: dark grey border
- Empty slot: dim text "[Empty]"
- Skill slot: teal border matching energy color (Color(0.2, 0.7, 0.9, 1))
- Font size 6 (matching existing HUD labels)

**Connections:**
- `GameManager.loadout_changed` → `_on_loadout_changed()` → update slot labels + highlight
- `DayNightCycle.phase_changed` → toggle a small lock icon / red tint on slots when night

### 6. Input Actions — `project.godot`

Add 4 new input actions:

| Action | Key | Physical Keycode |
|--------|-----|-----------------|
| `hotbar_weapon_1` | 1 | 49 |
| `hotbar_weapon_2` | 2 | 50 |
| `activate_skill` | Q | 81 |
| `loadout_toggle` | L | 76 |

### 7. Save/Load — `save_manager.gd`

**Bump** `SCHEMA_VERSION` to **7**.

**`_gather_state()`:** Replace the single `equipped_weapon` with a loadout dict:

```gdscript
# Replace: state["player"]["equipped_weapon"] = equipped_id
# With:
var loadout: Dictionary = {
    "weapon_slots": ["thorn_sword", ""],
    "active_skill": "",
    "selected_slot": 0,
}
if is_instance_valid(GameManager.player):
    loadout["weapon_slots"] = GameManager.player.weapon_slots.duplicate()
    loadout["active_skill"] = GameManager.player.active_skill_id
    loadout["selected_slot"] = GameManager.player.selected_weapon_slot
state["player"]["loadout"] = loadout
```

**`_apply_state()`:** After restoring crafting data, restore loadout:

```gdscript
var loadout: Dictionary = state.get("player", {}).get("loadout", {})
if is_instance_valid(GameManager.player):
    var slots: Array = loadout.get("weapon_slots", ["thorn_sword", ""])
    GameManager.player.weapon_slots = [str(slots[0]) if slots.size() > 0 else "thorn_sword",
                                        str(slots[1]) if slots.size() > 1 else ""]
    GameManager.player.active_skill_id = str(loadout.get("active_skill", ""))
    GameManager.player.selected_weapon_slot = int(loadout.get("selected_slot", 0))
    var wid: String = GameManager.player.weapon_slots[GameManager.player.selected_weapon_slot]
    if not wid.is_empty():
        GameManager.player._current_weapon = CraftingManager.get_weapon_data(wid)
    GameManager.player.loadout_changed.emit(
        GameManager.player.weapon_slots,
        GameManager.player.active_skill_id,
        GameManager.player.selected_weapon_slot)
```

**`_migrate()`:** v6 → v7: Convert old single `equipped_weapon` to loadout dict:

```gdscript
if version < 7:
    print("[SaveManager] Migrating save from v%d to v7." % version)
    var pd: Dictionary = data.get("player", {})
    var old_weapon: String = pd.get("equipped_weapon", "thorn_sword")
    pd["loadout"] = {
        "weapon_slots": [old_weapon, ""],
        "active_skill": "",
        "selected_slot": 0,
    }
    pd.erase("equipped_weapon")
    data["player"] = pd
    data["schema_version"] = 7
```

### 8. Scene Instancing — `meadow_edge.tscn`

- Add LoadoutScreen instance as sibling to other UI screens.

### 9. Debug Keys — `player_controller.gd`

| Key | Action |
|-----|--------|
| Shift+L | Give all weapons (set all owned_weapons to true in CraftingManager) |

---

## Files to Create

| File | Purpose |
|------|---------|
| `ui/screens/loadout_screen.gd` | Loadout assignment UI logic |
| `ui/screens/loadout_screen.tscn` | Loadout assignment UI scene |

## Files to Modify

| File | Change |
|------|--------|
| `player/scripts/player_controller.gd` | Replace single weapon with 2-slot loadout + skill slot; add input handling for 1/2/Q/L; emit `loadout_changed` signal; placeholder `_activate_skill()`; debug Shift+L |
| `shared/autoloads/game_manager.gd` | Add `loadout_changed` signal; forward from player in `register_player()` |
| `ui/hud/hud.gd` | Add hotbar section connecting to `loadout_changed` signal |
| `ui/hud/hud.tscn` | Add HotbarContainer (bottom-right) with 3 slot panels |
| `save/scripts/save_manager.gd` | SCHEMA_VERSION=7; replace equipped_weapon with loadout dict in gather/apply; v6→v7 migration |
| `project.godot` | Add 4 input actions: hotbar_weapon_1, hotbar_weapon_2, activate_skill, loadout_toggle |
| `world/zones/meadow_edge/meadow_edge.tscn` | Instance LoadoutScreen |
| `docs/design/PERSON_TASKS.md` | Add 1/2/Q/L/Shift+L to debug key table |
| `docs/design/TASK_BREAKDOWN.md` | Update PLANT-08 status to Done |

---

## Acceptance Criteria

1. Player starts with Thorn Sword in weapon slot 1 and slot 2 empty.
2. Pressing `1` selects weapon slot 1; pressing `2` selects weapon slot 2. The attack action uses the selected slot's weapon.
3. If the selected slot is empty, the attack action does nothing (with a console warning).
4. Pressing `Q` activates the active skill, spending 30 energy. If no skill is equipped or insufficient energy, a feedback message prints and nothing happens.
5. Pressing `L` opens the Loadout Screen. Owned weapons are listed. Clicking a weapon allows assigning it to slot 1 or slot 2.
6. **Night lock:** During Night phase, all loadout assignment controls are disabled. Attempting to swap via the screen or via code shows "Loadout locked!" feedback. Weapon slot **selection** (1/2 keys) is still allowed at night — only reassignment is blocked.
7. HUD hotbar (bottom-right) shows 3 slots with weapon/skill names. The selected weapon slot has a gold highlight border. Empty slots show "[Empty]".
8. Crafting a new weapon auto-equips it into the first empty slot (or replaces slot 1 if both full). Auto-equip is blocked at night.
9. Loadout persists across save/load (schema v7). Old v6 saves migrate: `equipped_weapon` → `loadout.weapon_slots[0]`.
10. `GameManager.loadout_changed` signal fires on every loadout change, allowing HUD and other systems to react.
