# PROMPT — Dianthus Pixie: Realistic 2-Week Vertical Slice

## Context

You are helping build **Dianthus Pixie**, a 2D survival crafting action game in **Godot 4.x**.
- Full GDD: `docs/design/Dianthus Pixie GDD.md`
- Full task breakdown: `docs/design/TASK_BREAKDOWN.md`
- Folder structure: `README.md`

### Team (3 people, 2 weeks total)

| ID | Role | Can Do | Limitations |
|----|------|--------|-------------|
| **A** (me) | Lead Programmer | Godot 4.x, FSM, combat, architecture | Also reviews all code |
| **B** | Programmer (Unity bg) | Strong dev, game patterns | Never used Godot — needs 2–3 day onboarding |
| **C** | Figma + Beginner Dev | UI/UX mockups, basic coding | No game engine exp — needs pairing |

### Already Implemented (DO NOT rebuild)

FOUND-01 through FOUND-06 (scaffold, tilemap, player controller, camera, day-night cycle, scene transitions), plus CORE-03 (Dianthus Core HP), CORE-04 (Game Over), CORE-06 (Shadowling FSM), CORE-07 (Wave Spawner).

**Key files:** `player/scripts/player_controller.gd`, `enemies/shadowling/`, `enemies/fsm/`, `enemies/enemy_base.gd`, `enemies/spawner/wave_spawner.gd`, `core/day_night/day_night_cycle.gd`, `core/dianthus_core/`, `ui/hud/core_hp_bar.*`, `ui/screens/game_over_screen.*`, `world/zones/meadow_edge/`, `shared/autoloads/game_manager.gd`, `combat/weapons/weapon_data.gd`.

---

## Goal: ONE Polished Vertical Slice

> Explore Meadow Edge → pick up resources → craft Thorn Sword at bench → place 1–2 plants → night falls → Shadowlings attack → fight → survive → "Night Survived" screen → next day harder → repeat 5 days

**College demo. Quality > quantity. A bug-free 5-day loop with 1 zone, 1 enemy, 1 weapon, 2 plants beats a broken 30-day game.**

---

## MUST HAVE — Week 1

| # | Task | Who | Days | What to build |
|---|------|-----|------|---------------|
| 1 | B Onboarding | A+B | 2d | A pairs B 2h on Day 1. B does 5 exercises: hello-scene, CharacterBody2D movement, signal→Label, Area2D coin pickup, read existing code. |
| 2 | CORE-01: Meadow Edge Polish | B | 2d | Decorate meadow_edge.tscn: place Petal Shard (×5) and Verdant Sap (×3) pickup nodes. Use Sprout Lands tileset. Polish collisions and walkable area. |
| 3 | CORE-02: Resource Pickup | B | 1d | Area2D on resources → on body_entered → add to player inventory dict → show "+1 Petal Shard" popup. No full inventory UI yet. |
| 4 | CORE-05: Thorn Sword Attack | A | 2d | Mouse click → 90° arc hitbox → damage enemies in arc. Placeholder white-arc VFX. Player starts with sword for now (crafting comes Week 2). |
| 5 | CORE-08: Player Death + Respawn | A | 0.5d | HP ≤ 0 → 5s timer → respawn at Core. 3s invincibility. -25% energy. |
| 6 | CORE-09: Night Survived Screen | A | 0.5d | wave_cleared signal → show result screen with rewards (3–5 Common + 1 Uncommon). Button advances to morning. |
| 7 | CORE-10: Basic HUD | C+A | 3d | Player HP bar (red, top-left) + Core HP bar (green, top-center). ProgressBar nodes. Signal wiring (A provides template, C implements). Shake tween on damage. |
| 8 | UI-05: Pause Menu | C | 2d | CanvasLayer → ColorRect (dim overlay) → VBoxContainer → Resume + Main Menu buttons. process_mode = ALWAYS. Toggles get_tree().paused. |
| 9 | Figma Mockups | C | 2d | HUD layout, Pause Menu, Night Survived, Main Menu. Export to docs/design/mockups/. |

**Week 1 Milestone:** Player can walk Meadow Edge, pick up items, fight Shadowlings at night with Thorn Sword, die/respawn, survive night, see result screen, see HUD, pause game.

---

## SHOULD HAVE — Week 2

| # | Task | Who | Days | What to build |
|---|------|-----|------|---------------|
| 10 | Simple Plant Placement | B | 2d | AFTERNOON phase only. Select Thornvine or Gloomshroom. Click 32×32 grid to place. Max 4 plants. No radius viz. |
| 11 | Thornvine Effect | A | 0.5d | Area2D deals 5 DMG/sec to enemies passing through. Simple thorn sprite. |
| 12 | Gloomshroom Effect | A | 0.5d | Area2D slows enemies 40% in radius. Simple mushroom sprite. |
| 13 | Simple Difficulty | A | 0.5d | Per day: enemies +10% HP, +1 spawn count. Linear multiplier in wave_spawner. |
| 14 | Bench Crafting | B | 1d | StaticBody2D bench in garden. Press E near it → if has 3 Petal Shard + 2 Verdant Sap → grant Thorn Sword. Popup confirm. |
| 15 | Main Menu | C | 1d | Title screen: logo + "Start Game" + "Quit". Loads meadow_edge scene. |
| 16 | Inventory List | C+A | 2d | Press I → overlay list of items (icon + name + count). Not full 30-slot grid. |
| 17 | Bug Fixing + Polish | ALL | 2d | **Last 2 days are bug-fix only. Feature freeze Day 9.** |

**Week 2 Milestone:** Full demo loop — explore, collect, craft sword, place plants, fight night, survive, next day harder. Menu → gameplay → pause → game over all connected.

---

## NICE TO HAVE (only if above is done + bug-free)

| # | Task | Who | Days |
|---|------|-----|------|
| 18 | Voidrunner enemy (reuse FSM, skip Scout, rush Core) | A | 1d |
| 19 | Energy bar + gain (+3/hit, +10/kill) | A | 0.5d |
| 20 | Day counter on HUD | C | 0.5d |
| 21 | 1 exploration + 1 night music track | C sources | 0.5d |

---

## CUT LIST — Do NOT implement

- All zones except Meadow Edge
- All enemies except Shadowling (Voidrunner only if time)
- All weapons except Thorn Sword (no Spore Bomb, Vine Whip, Petal Shield)
- All weapon upgrades
- Cross-breeding system and breeding bench UI
- All minigames (Plant Experimentation, Crafting Assembly, Harvest QTE)
- Quest system (daily, progress, discovery, story)
- Save/load system
- All endings (True, Survival, Discovery, Endless)
- 6 of 8 plants (only Thornvine + Gloomshroom)
- Full inventory (30-slot grid, stacking, drag/drop)
- Plant Codex, full HUD (minimap, hotbar, wave counter, energy)
- Difficulty tiers, Surge Night, Voidlord
- All audio (exploration, preparation, night music, SFX) unless Nice-to-Have
- Colorblind mode, tutorial, text speed
- Garden expansion, structures (storage, watchtower)
- Player animations (attack, dodge, respawn) — use placeholder
- All VFX beyond placeholder white-arc sword swing

---

## Day-by-Day Schedule

### Week 1

| Day | A (Lead) | B (Unity dev) | C (Figma + Beginner) |
|-----|----------|---------------|----------------------|
| 1 | Pair B onboarding (2h). Start CORE-05 sword. | Onboarding exercises 1–3. | Figma mockups: HUD, Pause. |
| 2 | CORE-05 sword (finish). | Onboarding exercises 4–5. Read codebase. | Figma mockups: Night Survived, Main Menu. |
| 3 | CORE-08 death/respawn. CORE-09 night survived screen. | CORE-01: decorate Meadow Edge, place resource nodes. | Start CORE-10: HUD setup (A gives template at end of day). |
| 4 | Pair C for HUD signal wiring (1h). Code review B's zone. | CORE-01 finish. Start CORE-02 pickup. | CORE-10: connect HP bars to signals. |
| 5 | Integration: test full loop (walk → fight → survive). Fix blockers. | CORE-02 finish. Fix B's review feedback. | UI-05: Pause menu. CORE-10 polish. |

### Week 2

| Day | A (Lead) | B (Unity dev) | C (Figma + Beginner) |
|-----|----------|---------------|----------------------|
| 6 | Thornvine + Gloomshroom plant effects. | Simple plant placement system. | Main Menu screen. |
| 7 | Simple difficulty scaling. Code review. | Bench crafting interaction. | Inventory list overlay (pair with A 1h). |
| 8 | Integration test: full demo with plants + crafting. | Plant placement polish. Fix review feedback. | Inventory list finish. |
| 9 | **FEATURE FREEZE.** Bug-fix only. | Bug-fix. | Bug-fix + QA testing. |
| 10 | Final bug-fix. Build export. | Bug-fix. Polish. | QA testing. Final check. |

---

## B's Onboarding Exercises (Days 1–2)

Complete in order. A pairs for ~2h on Day 1 to explain concepts.

| # | Exercise | Unity Equivalent |
|---|----------|-----------------|
| 1 | New scene + Sprite2D + script that prints in `_ready()` | GameObject + MonoBehaviour.Start() |
| 2 | CharacterBody2D + `move_and_slide()` in `_physics_process()` | Rigidbody2D + FixedUpdate |
| 3 | Button emits signal → Label updates text | UnityEvent → UI.Text |
| 4 | Area2D coin disappears on `body_entered`, increments counter | Collider2D.OnTriggerEnter2D |
| 5 | Read `player_controller.gd`, `shadowling.gd`, `wave_spawner.gd` | — |

**Key GDScript differences from C#:** `var` not typed by default, `func` not method, `@export` = `[SerializeField]`, `@onready` = Awake, `$NodePath` = transform.Find, signals = events.

---

## C's Task Templates

### Pause Menu (UI-05) — Step by step

1. Create `ui/menus/pause_menu.tscn` — root: CanvasLayer
2. Add ColorRect (Color: black, alpha 0.5) as full-screen background
3. Add VBoxContainer centered on screen with buttons: Resume, Main Menu
4. Set root `process_mode` = PROCESS_MODE_ALWAYS
5. Script: `ui/menus/pause_menu.gd`
   - `_input(event)`: if event is `ui_cancel` (Escape) → toggle visible + toggle `get_tree().paused`
   - Resume button `pressed` signal → same toggle
   - Main Menu → `get_tree().paused = false` then `get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")`

### HUD (CORE-10) — Step by step

1. Study `ui/hud/core_hp_bar.tscn` for reference
2. Create `ui/hud/hud.tscn` — root: CanvasLayer
3. Add ProgressBar nodes for Player HP (top-left) and Core HP (top-center)
4. A provides signal connection template: `player.health_changed.connect(_on_player_hp_changed)`
5. `_on_player_hp_changed(new_hp)` → update bar value
6. Damage shake: `var tween = create_tween(); tween.tween_property(bar, "position:x", bar.position.x + 5, 0.05).set_trans(Tween.TRANS_SINE); tween.tween_property(bar, "position:x", bar.position.x, 0.05)`

---

## Technical Conventions

- **Folder structure:** feature-based (see README.md). New files go in the correct feature folder.
- **Naming:** `snake_case.gd` for scripts, `PascalCase` for class_name, `snake_case` for variables/functions.
- **Signals:** Use Godot signals for decoupling. Never directly reference other systems.
- **Resources:** Use `.tres` resource files for data (weapon stats, enemy stats, plant data). Never hard-code gameplay values.
- **Scenes:** One `.tscn` per entity. Prefer composition (attach component nodes) over inheritance.
- **Collision layers:** Use constants from `shared/collision_layers.gd`.
- **Autoloads:** `GameManager` for global state. Add new autoloads only if truly global.

---

## Acceptance Criteria for Final Demo

The demo is DONE when a player can:

1. Start from Main Menu → click "Start Game"
2. Walk around Meadow Edge and pick up Petal Shards + Verdant Sap
3. Walk to crafting bench → press E → craft Thorn Sword (if has materials)
4. During Afternoon, place Thornvine and/or Gloomshroom in garden grid
5. Night falls automatically → Shadowlings spawn from 1–3 entry points
6. Fight Shadowlings with Thorn Sword (swing arc damages enemies)
7. Plants damage/slow enemies passively
8. If player dies → respawn at Core after 5s
9. If Core HP reaches 0 → Game Over screen
10. If all Shadowlings killed → "Night Survived" screen → rewards → morning
11. Next night is slightly harder (+10% HP, +1 enemy)
12. HUD shows Player HP + Core HP updating in real time
13. Pause menu works (Escape → Resume / Main Menu)
14. No crashes, no softlocks, no game-breaking bugs
15. Game runs at ≥30 FPS

**Anything not on this list is out of scope.**
