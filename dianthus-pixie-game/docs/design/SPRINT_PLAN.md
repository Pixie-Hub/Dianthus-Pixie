# Dianthus Pixie — Sprint Plan & Task Assignments

**Last Updated:** 2025-04-17  
**Team Size:** 3 | **Sprint Length:** 2 weeks | **Total:** 7 sprints + 1 half-sprint onboarding

---

## Team Roster

| ID | Role | Strengths | Limitations |
|----|------|-----------|-------------|
| **A** | Lead Programmer | Godot 4.x, FSM, combat, spawners, architecture | Must also code-review |
| **B** | Programmer (Unity bg) | Strong dev, understands game patterns | Never used Godot |
| **C** | Figma + Beginner Dev | UI/UX mockups, visual design, data entry | No game engine experience |

---

## Scope Cuts (College Project Realism)

> **Vertical Slice:** Explore Meadow Edge → collect resources → craft Thorn Sword → place plants → survive night → "Night Survived" screen → repeat with scaling. Must be rock-solid first.

### CUT entirely

| Task | Reason |
|------|--------|
| WORLD-03 Obsidian Bog | 4th zone, Day 14 unlock — players won't reach in demo |
| WORLD-04 Core Sanctum | Gated behind final quest chain |
| WORLD-05 Garden Expansion | Keep fixed 12×10 garden |
| WORLD-06 Garden Structures | Nice-to-have |
| ENEMY-05 The Devourer | XL, no GDD phase details — stub as cinematic |
| DIFF-03 Voidlord Mini-Boss | Surge Nights provide enough spikes |
| END-03 Discovery Ending | Requires full discovery quests |
| END-04 Endless Mode | True Ending sufficient |
| MINI-02 Crafting Assembly | One minigame enough |
| MINI-03 Harvest QTE | Cut |
| ACCESS-02 Colorblind Mode | Nice-to-have |
| ACCESS-04 Text Speed | Low priority |
| RES-01 Resource Scarcity | Fold into DIFF-01 as multiplier |

### SIMPLIFY

| Task | Change |
|------|--------|
| PLANT-12 (24 Combos) | Reduce to 8 combos (4 GDD + 4 custom) |
| ENEMY-04 Swarm Larva | Reuse Shadowling FSM, skip group AI |
| AUDIO-03 Night Music | Simple track swap, no dynamic layer |
| VFX-03 Enemy Anims | Full for Shadowling+Voidrunner; walk+death for others |
| VFX-04 Plant Anims | Bloom+idle only |
| VFX-05 Weapon VFX | Thorn Sword only; others placeholder |
| QUEST-02/03/04 | 2-3 quests per type, not full roster |

Estimated remaining: ~65-70 task-days (down from ~110+).

---

## Person B — Godot Onboarding (Unity → Godot)

Complete in Sprint 0 (3-4 days). A pairs for ~2h on Day 1.

| # | Topic | Unity | Godot |
|---|-------|-------|-------|
| 1 | GDScript | C# | Dynamic typed, Python-like. `var`, `func`, `class_name`, `extends` |
| 2 | Scene Tree | GameObject+Components | Everything is Node. `.tscn`=Prefab, `.gd`=MonoBehaviour |
| 3 | Signals | UnityEvent | `signal my_sig`; `emit_signal()`; `connect()` |
| 4 | @export/@onready | [SerializeField]/Awake | `@export var x := 5.0`; `@onready var s = $Sprite2D` |
| 5 | Lifecycle | Start/Update/Fixed | `_ready()`, `_process(delta)`, `_physics_process(delta)` |
| 6 | Input | Input System | Project Settings→Input Map; `Input.is_action_pressed()` |
| 7 | Area2D | Collider2D+trigger | `Area2D` for overlaps, `CharacterBody2D` for physics |
| 8 | Resources | ScriptableObject | `class_name X extends Resource`; `.tres` files |
| 9 | Autoloads | DontDestroyOnLoad | Project Settings→Autoload for singletons |
| 10 | TileMap | Unity Tilemap | TileMapLayer, TileSet resource, physics layers |

**Exercises (in order):**
1. New scene + Sprite2D + script that prints in `_ready()`
2. CharacterBody2D + `move_and_slide()` in `_physics_process()`
3. Button emits signal → Label updates text
4. Area2D coin disappears on `body_entered`, increments counter
5. Read `player_controller.gd`, `shadowling.gd`, `wave_spawner.gd`

---

## Person C — Figma Deliverables

| # | Screen | Used By | Priority |
|---|--------|---------|----------|
| 1 | Full HUD layout | CORE-10, UI-01 | Critical |
| 2 | Inventory (30-slot grid) | UI-02 | High |
| 3 | Cross-Breeding UI | PLANT-02 | High |
| 4 | Crafting Menu | PLANT-06 | High |
| 5 | Pause Menu | UI-05 | High |
| 6 | Quest Log | UI-03 | Medium |
| 7 | Night Survived screen | CORE-09 | High |
| 8 | Main Menu | — | Medium |
| 9 | Game Over review | — | Low |

**Format:** 640×360 or 1280×720 frames. Export to `docs/design/mockups/`.

## Person C — Beginner Godot Tasks

### C-1: Pause Menu (UI-05) — Easiest entry point

1. Create `ui/menus/pause_menu.tscn` — root: CanvasLayer
2. Add ColorRect (semi-transparent) + VBoxContainer with Buttons
3. Buttons: Resume, Settings (stub), Save (stub), Main Menu
4. Set root `process_mode` = PROCESS_MODE_ALWAYS
5. Script toggles `get_tree().paused` and `visible`

### C-2: Basic HUD (CORE-10) — Pair with A

1. Study existing `ui/hud/` scenes
2. Follow Figma mockup #1 for layout
3. Use ProgressBar or TextureProgressBar nodes
4. A provides signal wiring template
5. Add bar shake tween on damage (A helps)

### C-3: .tres Data Entry

A creates base Resource scripts; C fills `.tres` files in Godot Editor.

**File locations:**
- Plants → `plants/entities/` (PlantData)
- Enemies → `enemies/data/` (EnemyData)
- Recipes → `crafting/data/` (RecipeData)
- Quests → `quests/data/` (QuestData)
- Breed combos → `crafting/breeding/` (BreedComboData)

**Convention:** `snake_case.tres`, one file per entity. Right-click folder → New Resource → fill fields per GDD.

---

## Sprint Schedule

### Sprint 0 — Onboarding (Days 1–4)

| Person | Tasks |
|--------|-------|
| **A** | Pair with B (2h); create Resource base scripts for C; review tech debt |
| **B** | Complete onboarding exercises 1–5; read codebase |
| **C** | Figma mockups #1 HUD, #5 Pause, #7 Night Survived, #8 Main Menu; read GDD |

---

### Sprint 1 (Weeks 1–2): Complete Vertical Slice

**Goal:** Playable loop — explore, collect, fight, survive night, result screen.

| Person | Task | Effort | Notes |
|--------|------|--------|-------|
| **A** | CORE-05 Thorn Sword Melee Attack | M | 90° arc hitbox, placeholder VFX |
| **A** | CORE-08 Player Death & Respawn | S | 5s timer, -25% energy, 3s invincibility |
| **A** | CORE-09 Win Condition: Survive Night | S | Result screen + reward + day advance |
| **B** | CORE-01 Meadow Edge Exploration Zone | M | Tilemap, palette, pickup nodes |
| **B** | CORE-02 Resource Pickup System | S | Area2D overlap → inventory add |
| **C** | CORE-10 Basic HUD (HP bars) | S | 🔀 Pair with A for signal wiring |
| **C** | UI-05 Pause Menu | S | Follow template C-1 |
| **C** | Figma: Inventory, Cross-Breeding, Crafting | — | Mockups #2, #3, #4 |

**Milestone:** Full vertical slice playable. Demo to team.

---

### Sprint 2 (Weeks 3–4): Combat + Plants Foundation

**Goal:** Energy system, plant placement, breeding bench, first new enemy.

| Person | Task | Effort | Notes |
|--------|------|--------|-------|
| **A** | PLANT-07 Full Energy System | M | +3/hit, +10/kill, +2/s near Core |
| **A** | ENEMY-01 Voidrunner FSM | M | Reuse FSM framework |
| **A** | Code review B & C PRs | — | Ongoing |
| **B** | PLANT-01 Breeding Bench Structure | M | Placeable, interactable |
| **B** | PLANT-03 Plant Grid Placement | M | 32×32 grid, 8-plant cap, Afternoon only |
| **C** | PLANT-04 Plant Effect Radius Viz | S | Circle overlay during placement |
| **C** | .tres: 8 PlantData + 6 EnemyData resources | S | Data entry per GDD |
| **C** | Figma: Quest Log (#6) | — | Mockup |

🔀 **Pair:** A+B end of sprint — integrate placement with bench.

---

### Sprint 3 (Weeks 5–6): Weapons, Crafting, Loadout

**Goal:** Full weapon set, crafting menu, loadout system.

| Person | Task | Effort | Notes |
|--------|------|--------|-------|
| **A** | PLANT-09 Spore Bomb | M | Projectile + AoE + slow |
| **A** | PLANT-10 Vine Whip | M | 2.5-tile range + pull |
| **A** | PLANT-11 Petal Shield | M | Block + counter-attack |
| **B** | PLANT-06 Crafting Menu | L | UI + recipe logic + inventory deduction |
| **B** | PLANT-08 Loadout System | M | 2 weapons + 1 skill, lock at Night |
| **C** | PLANT-02 Cross-Breeding UI | L | 🔀 Pair with B — C builds UI, B wires logic |
| **C** | .tres: RecipeData (4 weapons + upgrades) | S | Per GDD §7.3 |

🔀 **Pair:** A+C — connect Cross-Breeding UI to backend.

---

### Sprint 4 (Weeks 7–8): Content Expansion + Difficulty

**Goal:** More enemies, Dusk Forest, difficulty scaling, start plant implementations.

| Person | Task | Effort | Notes |
|--------|------|--------|-------|
| **A** | ENEMY-02 Stonehusk FSM | M | No retreat, high HP tank |
| **A** | DIFF-01 Difficulty Scaling | M | Data-driven tier resource |
| **A** | DIFF-02 Surge Night | M | 3× enemies, all 4 spawn points |
| **B** | PLANT-05 All 8 Plants (start — 4 this sprint) | XL | First 4 plant effects |
| **B** | WORLD-01 Dusk Forest Zone | L | Tilemap + resources + transition |
| **C** | UI-02 Inventory Screen | M | 🔀 Pair with A for drag/stack |
| **C** | .tres: 8 BreedComboData + DifficultyTier data | S | Data entry |

---

### Sprint 5 (Weeks 9–10): Quests, Save, Remaining Enemies

**Goal:** Quest system, save/load, remaining enemies, plant completion.

| Person | Task | Effort | Notes |
|--------|------|--------|-------|
| **A** | QUEST-01 Quest System Architecture | L | QuestManager autoload, signals |
| **A** | ENEMY-03 Phantom Weaver FSM | L | Teleport mechanic |
| **B** | PLANT-05 All 8 Plants (finish — last 4) | XL | Remaining plant effects |
| **B** | SAVE-01 Auto-Save System | M | Post-night, versioned schema |
| **B** | SAVE-02 Manual Save & Load | S | Single slot, overwrite confirm |
| **C** | UI-03 Quest Log Screen | M | 🔀 Pair with B for data binding |
| **C** | .tres: 6–8 QuestData files | S | Daily/Progress/Discovery samples |
| **C** | QUEST-02 Daily Quests (2–3) | M | Simple objectives with A's system |

---

### Sprint 6 (Weeks 11–12): Audio, VFX, Polish

**Goal:** Audio, animations, remaining quests, tutorial start.

| Person | Task | Effort | Notes |
|--------|------|--------|-------|
| **A** | ENEMY-04 Swarm Larva (simplified) | M | Individual FSMs, fast+fragile |
| **A** | AUDIO-03 Night Music (simplified) | S | Track swap on night phase |
| **A** | ACCESS-01 3 Difficulty Levels | M | Easy/Normal/Hard multiplier |
| **B** | VFX-01 Player Animations | L | Attack, dodge, respawn |
| **B** | VFX-02 Core Animations | M | Glow, damage, destruction |
| **B** | WORLD-02 Ruins of Veld | L | Only if time permits — else cut |
| **C** | AUDIO-01 Exploration Music | M | Source/create, AudioStreamPlayer |
| **C** | AUDIO-02 Preparation Music | S | Crossfade from exploration |
| **C** | UI-04 Plant Codex Screen | M | List plants + combos |

🔀 **Pair:** A+B — integrate enemy anims with FSM states.

---

### Sprint 7 (Weeks 13–14): Endings, Tutorial, QA & Ship

**Goal:** Endings, tutorial, full QA, ship the build.

| Person | Task | Effort | Notes |
|--------|------|--------|-------|
| **A** | END-01 True Ending | M | Day 30+ trigger |
| **A** | END-02 Survival Ending | S | Day 20 trigger |
| **A** | ACCESS-03 Tutorial (Days 1–3) | L | 🔀 Pair with C — C writes text, A codes |
| **B** | MINI-01 Plant Experimentation Minigame | L | Rhythm/puzzle prototype |
| **B** | QUEST-05 Story Quests (simplified) | L | 2–3 story beats |
| **B** | VFX-03 Enemy Anims (simplified) | M | Shadowling+Voidrunner full; others minimal |
| **C** | AUDIO-04 Key SFX | L | Source SFX, wire to events |
| **C** | QA-01 Full QA Pass | XL | 🔀 ALL THREE — C leads, A+B fix bugs |

**Feature freeze: End of Sprint 7 Week 1. Week 2 = bug fixes only.**

---

## Pair-Programming Sessions

| Sprint | Who | What |
|--------|-----|------|
| 0 | A+B | Godot onboarding (2h) |
| 1 | A+C | HUD signal wiring (CORE-10) |
| 2 | A+B | Plant placement + bench integration |
| 3 | B+C | Cross-Breeding UI (C builds, B wires) |
| 3 | A+C | Cross-Breeding UI → backend connection |
| 4 | A+C | Inventory drag/stack logic |
| 5 | B+C | Quest Log data binding |
| 6 | A+B | Enemy animations ↔ FSM states |
| 7 | A+C | Tutorial (C writes dialogue, A codes triggers) |
| 7 | ALL | QA pass (C leads testing, A+B fix) |

---

## Per-Person Task Summary

### Person A (Lead) — 22 tasks

CORE-05, CORE-08, CORE-09, PLANT-07, PLANT-09, PLANT-10, PLANT-11,
ENEMY-01, ENEMY-02, ENEMY-03, ENEMY-04, DIFF-01, DIFF-02,
QUEST-01, ACCESS-01, ACCESS-03, AUDIO-03, END-01, END-02,
code review (ongoing), Resource base scripts, pair sessions

### Person B (Unity dev) — 18 tasks

CORE-01, CORE-02, PLANT-01, PLANT-03, PLANT-05, PLANT-06, PLANT-08,
WORLD-01, SAVE-01, SAVE-02, VFX-01, VFX-02, VFX-03,
WORLD-02 (if time), MINI-01, QUEST-05, pair sessions

### Person C (Figma + Beginner) — 18 tasks

CORE-10, UI-02, UI-03, UI-04, UI-05, PLANT-02, PLANT-04,
QUEST-02, AUDIO-01, AUDIO-02, AUDIO-04, QA-01,
Figma mockups (9 screens), .tres data entry (PlantData, EnemyData,
RecipeData, QuestData, BreedComboData, DifficultyTier),
pair sessions

---

## Dependency Chain (Critical Path)

```
FOUND-02 → CORE-01 → CORE-02 ─────────────────────────────────────→ UI-02
FOUND-03 → CORE-05 → PLANT-06 → PLANT-08
                    → PLANT-09/10/11
CORE-03  → CORE-08 → PLANT-07 → UI-01
CORE-07  → CORE-09 → SAVE-01 → SAVE-02
         → DIFF-01 → DIFF-02, ACCESS-01, END-02
CORE-06  → ENEMY-01/02/03/04
FOUND-02 → PLANT-01 → PLANT-02 → MINI-01
         → PLANT-03 → PLANT-04
                    → PLANT-05 → UI-04, QUEST-04
FOUND-01 → QUEST-01 → QUEST-02/03/04/05
         → UI-05
CORE-01  → WORLD-01 → WORLD-02
```

**Longest path:** FOUND-02 → CORE-01 → CORE-02 → ... → QUEST chain → END-01 (~12 weeks).
This is why Sprint 1 must nail the vertical slice — everything branches from it.
