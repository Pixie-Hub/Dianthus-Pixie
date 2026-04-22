# Dianthus Pixie — Per-Person Task Breakdown

**Sprint:** 2-Week Vertical Slice  
**Last Updated:** 2026-04-19  
**Source:** `PROMPT_CORE_08.md`, `PROMPT_CROSSBREEDING.md`

> Status legend: ✅ Done · 🔧 In Progress · ⬜ Not Started

---

## Person A — Lead Programmer

**Role:** Architecture, combat, FSM, systems, code review, pairing  
**Total estimated days:** ~8.5d (of 10 working days)

### Week 1

| Day | Task | Est | Status | Notes |
|-----|------|-----|--------|-------|
| 1 | Pair B onboarding (2h) | 0.25d | ✅ | Explain Godot concepts: scenes, signals, `@export`, `@onready`, `$NodePath` |
| 1–2 | **CORE-05:** Thorn Sword Attack | 2d | ✅ | Mouse click → 90° arc hitbox → damage enemies. Placeholder white-arc VFX. Player starts with sword. Files: `player_controller.gd`, `thorn_sword_data.tres` |
| 3 | **CORE-08:** Player Death + Respawn | 0.5d | ✅ | HP ≤ 0 → 5s timer → respawn at Core. 3s invincibility blink. -25% energy (stub until energy system). Files: `player_controller.gd` |
| 3 | **CORE-09:** Night Survived Screen | 0.5d | ✅ | `wave_cleared` → pause → show rewards (3–5 Petal Shard + 1 Verdant Sap) → Continue → skip to morning. Files: `night_survived_screen.gd/.tscn`, `game_manager.gd` |
| 3 | **CORE-10:** HUD Template for C | — | ✅ | Unified `hud.gd/.tscn` with Player HP (red, top-left) + Core HP (green, top-center). Signal wiring + damage shake tween. C polishes from here. Files: `ui/hud/hud.gd/.tscn` |
| 4 | Pair C for HUD signal wiring (1h) | 0.1d | ⬜ | Walk C through `GameManager.player_hp_changed` / `core_hp_changed` signals |
| 4 | Code review B's Meadow Edge + pickup work | 0.25d | ⬜ | Review CORE-01 and CORE-02 PRs |
| 5 | **Integration test:** full Week 1 loop | 1d | ⬜ | Walk → fight → die/respawn → survive night → result screen → HUD → pause. Fix blockers. |

### Week 2

| Day | Task | Est | Status | Notes |
|-----|------|-----|--------|-------|
| 6 | **Bougainvillea plant effect** | 0.5d | ✅ | Area2D deals 5 DMG/tick to enemies in radius (24px). Magenta-pink placeholder. Files: `plants/entities/bougainvillea.gd/.tscn` |
| 6 | **Rafflesia plant effect** | 0.5d | ✅ | Area2D slows enemies 0.6× in radius (40px). Deep red-brown placeholder. Files: `plants/entities/rafflesia.gd/.tscn` |
| 6 | **PLANT-02: Melati** | 0.25d | ✅ | Support — energy regen +3/sec to player in 32px radius. Files: `plants/entities/melati.gd/.tscn` |
| 6 | **PLANT-03: Wijaya Kusuma** | 0.5d | ✅ | Offensive — night auto-attack projectile 8 DMG, 48px range. Files: `plants/entities/wijaya_kusuma.gd/.tscn` |
| 6 | **PLANT-04: Beringin** | 0.5d | ✅ | Defensive — spawns root wall (HP:60, 20s, cooldown 25s) blocking enemies. Files: `plants/entities/beringin.gd/.tscn` |
| 6 | **PLANT-05: Kecombrang** | 0.25d | ✅ | Support — attack speed +20% to player in 28px radius. Files: `plants/entities/kecombrang.gd/.tscn` |
| 6 | **PLANT-06b: Kunyit** | 0.25d | ✅ | Hybrid — melee damage +3 to player in 24px radius. Files: `plants/entities/kunyit.gd/.tscn` |
| 7 | **Simple Difficulty scaling** | 0.5d | ⬜ | Per day: enemies +10% HP, +1 spawn count. Linear multiplier in `wave_spawner.gd`. Data-driven via export vars. |
| 7 | Code review B's plant placement + crafting | 0.25d | ⬜ | Review CORE-01 polish, plant placement, bench crafting |
| 8 | **Integration test:** full demo with plants + crafting | 1d | ⬜ | Explore → collect → craft → place plants → fight → survive → next day harder. End-to-end. |
| 9 | **FEATURE FREEZE.** Bug-fix only. | 1d | ⬜ | Zero new features. Only critical/high bugs. |
| 10 | Final bug-fix. Build export. | 1d | ⬜ | Export build, final sanity check. |

### Nice-to-Have (only if MUST + SHOULD are done and bug-free)

| Task | Est | Status | Notes |
|------|-----|--------|-------|
| Voidrunner enemy (reuse FSM, skip Scout, rush Core) | 1d | ⬜ | New enemy type with simplified FSM |
| Energy bar + gain (+3/hit, +10/kill) | 0.5d | ✅ | Replace the CORE-08 energy stub with real system |

### Key Files A Owns

- `player/scripts/player_controller.gd`
- `enemies/enemy_base.gd`, `enemies/fsm/`
- `enemies/spawner/wave_spawner.gd`
- `shared/autoloads/game_manager.gd`
- `core/day_night/day_night_cycle.gd`
- `combat/weapons/`
- `ui/screens/night_survived_screen.gd/.tscn`
- `ui/hud/hud.gd/.tscn` (template)
- `plants/entities/` (all 11 plants: Bougainvillea, Rafflesia, Melati, Wijaya Kusuma, Beringin, Kecombrang, Kunyit + 4 hybrids)

---

## Person B — Programmer (Unity Background)

**Role:** Level decoration, resource pickup, plant placement, bench crafting  
**Total estimated days:** ~9d (of 10 working days, first 2 are onboarding)  
**Limitation:** Never used Godot — needs 2–3 day onboarding

### Onboarding (Days 1–2)

Complete in order. A pairs for ~2h on Day 1.

| # | Exercise | Unity Equivalent | Status |
|---|----------|-----------------|--------|
| 1 | New scene + Sprite2D + script that prints in `_ready()` | GameObject + MonoBehaviour.Start() | ⬜ |
| 2 | CharacterBody2D + `move_and_slide()` in `_physics_process()` | Rigidbody2D + FixedUpdate | ⬜ |
| 3 | Button emits signal → Label updates text | UnityEvent → UI.Text | ⬜ |
| 4 | Area2D coin disappears on `body_entered`, increments counter | Collider2D.OnTriggerEnter2D | ⬜ |
| 5 | Read `player_controller.gd`, `shadowling.gd`, `wave_spawner.gd` | — | ⬜ |

**Key GDScript vs C#:** `var` not typed by default, `func` not method, `@export` = `[SerializeField]`, `@onready` = Awake, `$NodePath` = transform.Find, signals = events.

### Week 1

| Day | Task | Est | Status | Notes |
|-----|------|-----|--------|-------|
| 1 | Onboarding exercises 1–3 | 1d | ⬜ | A pairs for 2h |
| 2 | Onboarding exercises 4–5. Read codebase. | 1d | ⬜ | Focus on understanding signals and scene tree |
| 3–4 | **CORE-01:** Meadow Edge Polish | 2d | ⬜ | Decorate `meadow_edge.tscn` using Sprout Lands tileset. Place Petal Shard (×5) and Verdant Sap (×3) pickup nodes. Polish collisions and walkable area. |
| 4–5 | **CORE-02:** Resource Pickup System | 1d | ✅ | `InventoryManager.add_item()` on body_entered. Floating popup. "Inventory Full!" guard. Files: `inventory/pickups/resource_pickup.gd/.tscn`, `inventory/data/item_database.gd`, `inventory/scripts/inventory_manager.gd` |

### Week 2

| Day | Task | Est | Status | Notes |
|-----|------|-----|--------|-------|
| 6–7 | **PLANT-03/04: Plant Grid Placement + Effect Radius** | 2d | ✅ | P key → placement mode (DAY only). Seed palette HUD. Ghost preview + 16×16 grid snap. Effect radius viz. Max 8 plants. 12×10 garden centered on Core. Files: `plants/placement/plant_placement_manager.gd/.tscn`, `plants/placement/plant_palette_ui.gd` |
| 7 | **Bench Crafting / PLANT-06** | 1d | ✅ | BreedingBench (StaticBody2D). Press E near it (day only) → CraftingScreen UI. 8 recipes, material deduction, weapon ownership. Files: `crafting/` |
| 8 | **Cross-Breeding System / PLANT-CB** | 2d | ✅ | `BreedingManager` autoload, 4 hybrid plant entities, `CrossBreedingScreen` UI, bench opens breeding screen, save/load v5. Files: `crafting/breeding/breeding_manager.gd`, `plants/entities/bunga_api.*`, `plants/entities/bunga_bayang.*`, `plants/entities/melati_emas.*`, `plants/entities/baja_kuning.*`, `ui/screens/cross_breeding_screen.*` |
| 8 | Plant placement polish. Fix A's review feedback. | 1d | ⬜ | |
| 9 | Bug-fix. | 1d | ⬜ | Feature freeze. |
| 10 | Bug-fix. Polish. | 1d | ⬜ | |

### CORE-01 Details — Step by step

1. Open `world/zones/meadow_edge/meadow_edge.tscn` in Godot editor
2. Use `Sprout Lands` tileset (`world/tilesets/Sprout Lands - Sprites - Basic pack/`) to decorate the zone — add grass variety, flowers, trees, rocks
3. Create `Area2D` pickup nodes for resources:
   - **Petal Shard** ×5 — scattered around walkable areas
   - **Verdant Sap** ×3 — near trees or garden edge
4. Each pickup node: `Sprite2D` + `CollisionShape2D` + `Area2D`
5. Tag pickups with metadata or group: `add_to_group("pickups")`
6. Ensure collisions are clean — player can walk the entire zone without clipping

### CORE-02 Details — Step by step

1. Create `inventory/scripts/resource_pickup.gd`
2. On `body_entered` (player collision layer):
   ```gdscript
   func _on_body_entered(body: Node2D) -> void:
       if body == GameManager.player:
           var inv: Dictionary = GameManager.player_data["inventory"]
           inv[resource_name] = inv.get(resource_name, 0) + amount
           _show_popup("+%d %s" % [amount, resource_name])
           queue_free()
   ```
3. Popup: temporary Label that floats up and fades (tween `position:y` and `modulate:a`)
4. Test: walk over Petal Shard → check `GameManager.player_data.inventory` in debugger

### Key Files B Owns

- `world/zones/meadow_edge/meadow_edge.tscn` (decoration)
- `inventory/scripts/resource_pickup.gd` (new)
- `plants/placement/` (new)
- `crafting/bench/` (new)

---

## Person C — Figma + Beginner Dev

**Role:** UI/UX mockups, basic UI implementation with A's guidance  
**Total estimated days:** ~9d (of 10 working days)  
**Limitation:** No game engine experience — needs pairing with A

### Week 1

| Day | Task | Est | Status | Notes |
|-----|------|-----|--------|-------|
| 1 | **Figma mockups:** HUD layout, Pause Menu | 1d | ⬜ | Export to `docs/design/mockups/` |
| 2 | **Figma mockups:** Night Survived screen, Main Menu | 1d | ⬜ | Export to `docs/design/mockups/` |
| 3 | **CORE-10:** Start HUD implementation | 1d | ⬜ | A gives `ui/hud/hud.tscn` template at end of day. C studies it, tweaks layout/colors. |
| 4 | **CORE-10:** Connect HP bars to signals | 1d | ⬜ | A pairs 1h to explain signal wiring. C connects bars, tests with F1–F4 debug keys. |
| 5 | **UI-05:** Pause Menu + CORE-10 polish | 1d | ⬜ | Build pause menu from template below. Polish HUD bar sizes/colors. |

### Week 2

| Day | Task | Est | Status | Notes |
|-----|------|-----|--------|-------|
| 6 | **Main Menu screen** | 1d | ⬜ | Title + "Start Game" + "Quit" buttons. Files: `ui/menus/main_menu.gd/.tscn` |
| 7 | **UI-02: Inventory Screen** (pair with A 1h) | 1d | ✅ | Press I → 30-slot grid (6×5, 40×40 slots). Rarity-colored panels, stack count, tooltip on hover. Files: `ui/screens/inventory_screen.gd/.tscn` |
| 8 | Inventory screen finish. | 1d | ✅ | Polish, test with collected items |
| 9 | Bug-fix + QA testing. | 1d | ⬜ | Feature freeze. Test all screens. |
| 10 | QA testing. Final check. | 1d | ⬜ | Full playthrough, report bugs. |

### Nice-to-Have

| Task | Est | Status | Notes |
|------|-----|--------|-------|
| Day counter on HUD | 0.5d | ⬜ | Add "Day X" label to `hud.tscn` |
| 1 exploration + 1 night music track | 0.5d | ⬜ | Source royalty-free tracks, add to `audio/music/` |

### UI-05: Pause Menu — Step by step

1. Create `ui/menus/pause_menu.tscn` — root: **CanvasLayer**
2. Add **ColorRect** child (Color: black, alpha 0.5) — anchors full-screen
3. Add **CenterContainer** → **VBoxContainer** with 2 buttons:
   - **Resume** button
   - **Main Menu** button
4. Set root CanvasLayer `process_mode` = `PROCESS_MODE_ALWAYS`
5. Create script `ui/menus/pause_menu.gd`:
   ```gdscript
   extends CanvasLayer

   func _ready() -> void:
       visible = false

   func _unhandled_input(event: InputEvent) -> void:
       if event.is_action_pressed("ui_cancel"):
           _toggle_pause()

   func _toggle_pause() -> void:
       visible = !visible
       get_tree().paused = visible

   func _on_resume() -> void:
       _toggle_pause()

   func _on_main_menu() -> void:
       get_tree().paused = false
       visible = false
       get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")
   ```
6. Connect button `pressed` signals to `_on_resume` and `_on_main_menu`
7. Add PauseMenu instance to `meadow_edge.tscn`

### Main Menu — Step by step

1. Create `ui/menus/main_menu.tscn` — root: **Control** (full rect)
2. Add **CenterContainer** → **VBoxContainer**:
   - **Label**: "Dianthus Pixie" (title, large font)
   - **Button**: "Start Game"
   - **Button**: "Quit"
3. Create script `ui/menus/main_menu.gd`:
   ```gdscript
   extends Control

   func _on_start_game() -> void:
       get_tree().change_scene_to_file("res://world/zones/meadow_edge/meadow_edge.tscn")

   func _on_quit() -> void:
       get_tree().quit()
   ```
4. Connect button signals
5. Update `project.godot` → `run/main_scene` to `res://ui/menus/main_menu.tscn`

### Inventory List — Step by step

1. Create `ui/screens/inventory_screen.tscn` — root: **CanvasLayer** (layer 90)
2. Add dark ColorRect background + **ScrollContainer** → **VBoxContainer**
3. Create script `ui/screens/inventory_screen.gd`:
   ```gdscript
   extends CanvasLayer

   @onready var _list: VBoxContainer = %ItemList

   func _ready() -> void:
       visible = false

   func _unhandled_input(event: InputEvent) -> void:
       if event.is_action_pressed("inventory_toggle"):
           _toggle()

   func _toggle() -> void:
       visible = !visible
       if visible:
           _refresh()

   func _refresh() -> void:
       for child in _list.get_children():
           child.queue_free()
       var inv: Dictionary = GameManager.player_data["inventory"]
       for item_name: String in inv:
           var label: Label = Label.new()
           label.text = "%s  x%d" % [item_name, inv[item_name]]
           _list.add_child(label)
   ```
4. Add `inventory_toggle` input action (key: I) in `project.godot`
5. Add InventoryScreen instance to `meadow_edge.tscn`

### Key Files C Owns

- `docs/design/mockups/` (Figma exports)
- `ui/hud/hud.tscn` (polish — layout, colors, sizing)
- `ui/menus/pause_menu.gd/.tscn` (new)
- `ui/menus/main_menu.gd/.tscn` (new)
- `ui/screens/inventory_screen.gd/.tscn` (new)

---

## Dependencies Graph

```
FOUND-01..06 (Done)
├── CORE-03 Dianthus Core HP (Done)
│   ├── CORE-04 Game Over (Done)
│   ├── CORE-08 Player Death + Respawn (Done) [A]
│   └── CORE-10 Basic HUD (Done — template) [C polishes]
├── CORE-05 Thorn Sword (Done) [A]
├── CORE-06 Shadowling FSM (Done)
│   └── CORE-07 Wave Spawner (Done)
│       └── CORE-09 Night Survived Screen (Done) [A]
├── CORE-01 Meadow Edge Polish [B]
│   └── CORE-02 Resource Pickup [B]
│       └── Bench Crafting [B]
├── Plant Placement [B] ← needs CORE-02 items
│   ├── Thornvine Effect [A]
│   └── Gloomshroom Effect [A]
├── Simple Difficulty [A] ← modifies wave_spawner
├── UI-05 Pause Menu [C]
├── Main Menu [C]
└── Inventory List [C+A]
```

---

## Quick Reference — Debug Keys

| Key | Action | Added by |
|-----|--------|----------|
| F1 | Core -20 HP | CORE-03 |
| F2 | Core +20 HP | CORE-03 |
| F3 | Player -25 HP | CORE-08 |
| Shift+F3 | Energy set to 50 | PLANT-07 |
| F4 | Player +25 HP | CORE-08 |
| Shift+F4 | Energy filled to max | PLANT-07 |
| F5 | Spawn Shadowling at mouse | CORE-06 |
| F6 | Kill all enemies | CORE-06 |
| F7 | Skip current phase | FOUND-05 |
| F8 | Force-start wave | CORE-07 |
| F9 | Force-clear wave | CORE-07 |
| F10 | Place plant cycle at mouse (no grid): Bougainvillea → Rafflesia → Melati → Wijaya Kusuma → Beringin → Kecombrang → Kunyit → Bunga Api → Bunga Bayang → Melati Emas → Baja Kuning → Clear | PLANT-02..06b |
| F11 | Manual save (`SaveManager.save_to_slot(true)`) | SAVE-01/02 |
| Shift+F11 | Delete save file (test New Game overwrite) | SAVE-02 |
| F12 | Load save (`SaveManager.load_from_slot()`) | SAVE-02 |
| Insert | Add 5 Petal Shard + 2 Verdant Sap + 1 Moonspore (inventory test) | CORE-02/UI-02 |
| Shift+Insert | Add all crafting + breeding + plant seed test materials (extracts ×1 each + 5 Petal Shard + 5 Verdant Sap + 3 Moonspore + 2 Shadow Resin + 1 Dianthus Pollen + 3 Bougainvillea Seed + 2 Rafflesia/Melati Seed + 1 of each remaining base + hybrid seed) | PLANT-02..06b |
| I | Toggle 30-slot Inventory screen | UI-02 |
| E | Interact with BreedingBench (opens CrossBreeding UI) | PLANT-06 / PLANT-CB |
| C | Toggle CraftingScreen directly (debug bypass bench proximity) | PLANT-06 |
| B | Toggle CrossBreedingScreen directly (debug bypass bench proximity) | PLANT-CB |
| P | Toggle plant placement mode (DAY only; shows seed palette HUD) | PLANT-03 |
| J | Toggle Plant Codex screen (pauses game) | UI-04 |
| Shift+J | Discover all 11 plants in codex (debug unlock) | UI-04 |
