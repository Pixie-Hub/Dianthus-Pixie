# Dianthus Pixie — Task Breakdown

**Project:** Dianthus Pixie  
**Engine:** Godot 4.x  
**Art:** Aseprite (16×16 tiles, 16×24 characters)  
**Last Updated:** 2026-04-26  
**GDD Reference:** `Dianthus Pixie GDD.md` (v1.1)

> **Legend — Effort:** XS < 2 h · S < 1 d · M 1–3 d · L 3–7 d · XL > 1 wk  
> **Legend — Priority:** Critical > High > Medium > Low  
> **⚠️** = GDD ambiguity / missing detail flagged

---

## Phase 0 — Foundation

| Task ID | Title | Category | Priority | Status | Dependencies | Assignee | Effort | Acceptance Criteria |
|---------|-------|----------|----------|--------|--------------|----------|--------|---------------------|
| FOUND-01 | Godot 4.x Project Scaffold | Core Mechanics | Critical | Done | — | [Unassigned] | S | • Godot 4.x project opens error-free; folder structure in place per repo layout; • `.gitignore` and `.editorconfig` committed |
| FOUND-02 | Tilemap & Tileset Setup | World & Map | Critical | Done | FOUND-01 | [Unassigned] | M | • TileSet resource with 16×16 px tiles per GDD §18; • at least one ground and one wall tile render correctly; • physics collision layers defined (walkable vs. blocked) |
| FOUND-03 | Player Controller (Move + Collide) | Player | Critical | Done | FOUND-01 | [Unassigned] | M | • Player moves at 5 tiles/sec on 8-directional input per GDD §9.1; • `CollisionShape2D` prevents wall penetration; • idle and walk animation states transition correctly |
| FOUND-04 | Camera System | Core Mechanics | High | Done | FOUND-03 | [Unassigned] | S | • `Camera2D` follows player with smooth lerp; • configurable limits prevent scrolling outside zone bounds; • no dead-zone bleed on zone edges |
| FOUND-05 | Day-Night Cycle Timer | Core Mechanics | Critical | Done | FOUND-01 | [Unassigned] | M | • Timer emits `phase_changed` signals for Morning, Afternoon, and Night per GDD §2; • world-color tint transitions smoothly between phases; • debug overlay shows current phase label |
| FOUND-06 | Scene Transition System | Core Mechanics | High | Done | FOUND-01 | [Unassigned] | S | • Fade-in/fade-out loads target scene without flicker; • player position and inventory persist across zone transitions; • transition is non-interruptible at night |

---

## Phase 1 — Core Loop (Vertical Slice)

| Task ID | Title | Category | Priority | Status | Dependencies | Assignee | Effort | Acceptance Criteria |
|---------|-------|----------|----------|--------|--------------|----------|--------|---------------------|
| CORE-01 | Meadow Edge Exploration Zone | World & Map | Critical | Not Started | FOUND-02 | [Unassigned] | M | • Zone tilemap renders with warm/vibrant daytime palette per GDD §12.1; • player walks entire zone without clipping; • Petal Shard and Verdant Sap pickup nodes placed |
| CORE-02 | Resource Pickup System | Resource & Inventory | Critical | Done | CORE-01 | [Unassigned] | S | • Player collects Petal Shard and Verdant Sap on area overlap per GDD §6.1; • items added to 30-slot inventory data structure; • pickup confirmation feedback (SFX + item count update) |
| CORE-03 | Dianthus Core Entity & HP | Core Mechanics | Critical | Done | FOUND-01 | [Unassigned] | M | • Core placed at garden center per GDD §10.2; • glowing pink-white aura renders and dims proportionally as HP falls per GDD §12.1; • Core HP bar displayed on HUD |
| CORE-04 | Game Over on Core HP 0 | Core Mechanics | Critical | Done | CORE-03 | [Unassigned] | S | • Game Over screen appears immediately (no grace period) when Core HP reaches 0 per GDD §5.1; • screen shows days survived with Restart and Main Menu options; • no last-stand mechanic |
| CORE-05 | Thorn Sword Melee Attack | Combat | Critical | Done | FOUND-03 | [Unassigned] | M | • 90° swing arc hitbox active for correct attack frames per GDD §14; • deals correct base damage to enemies in arc; • swing VFX and SFX trigger on each attack |
| CORE-06 | Shadowling Enemy FSM | Enemy AI | Critical | Done | FOUND-03 | [Unassigned] | L | • Shadowling stats: 40 HP, 8 DMG/hit per GDD §8.1; • standard FSM: Idle → Scout → Siege → Attack → Retreat (retreat at HP < 20% or < 2 allies in proximity); • each state has distinct visual/movement behaviour ⚠️ *GDD §15 does not specify the detection radius for "allies in area" — a default range value must be decided* |
| CORE-07 | Wave Spawner (1 Wave, 1–3 Entry Points) | Enemy AI | Critical | Done | CORE-06 | [Unassigned] | M | • Night phase triggers spawner; 1–3 of 4 cardinal entry points activate randomly per GDD §10.3; • wave cleared signal fires only when all enemies die or despawn; • spawner resets cleanly for next night |
| CORE-08 | Player Death & Respawn | Player | Critical | Done | CORE-03 | [Unassigned] | S | • Player respawns near Core after 5 s per GDD §5.1; • -25% stored energy applied on respawn; • 3 s invincibility window after respawn; equipped items are retained |
| CORE-09 | Win Condition: Survive Night | Core Mechanics | Critical | Done | CORE-07 | [Unassigned] | S | • All waves defeated before dawn triggers "Night Survived" result screen with 3–5 Common + 1 Uncommon resource reward per GDD §6.3; • transitions to next day Morning phase |
| CORE-10 | Basic HUD (Player HP + Core HP) | UI/HUD | High | Done | CORE-03 | [Unassigned] | S | • Player HP bar (red, top-left) and Core HP bar (green, top-center) per GDD §11.1; • both bars update in real time; • bar shakes briefly on damage received per GDD §12.2 |

---

## Phase 2 — Plant & Crafting

| Task ID | Title | Category | Priority | Status | Dependencies | Assignee | Effort | Acceptance Criteria |
|---------|-------|----------|----------|--------|--------------|----------|--------|---------------------|
| PLANT-01 | Breeding Bench Structure | Plant & Crafting | Critical | Done | FOUND-02 | [Unassigned] | M | • Bench placeable in garden per GDD §10.2; • interactable from adjacent tile; • interaction opens Cross-Breeding UI |
| PLANT-02 | Cross-Breeding UI | Plant & Crafting | Critical | Done | PLANT-01 | [Unassigned] | L | • Two plant input slots and one output slot per GDD §7.2; • known combos show deterministic result preview; unknown combos show "?"; • Confirm triggers minigame ⚠️ *GDD §7.2 specifies no UI layout or input flow — wireframe needed before implementation* |
| PLANT-03 | Plant Grid Placement System | Plant & Crafting | Critical | Done | FOUND-02 | [Unassigned] | M | • Plants placed on 16×16 px per tile garden grid per GDD §7.4; • hard cap of 8 active plants enforced with UI feedback; • placement restricted to Afternoon (Preparation) phase only |
| PLANT-04 | Plant Effect Radius Visualization | Plant & Crafting | High | Done | PLANT-03 | [Unassigned] | S | • Radius overlay shown per plant type during placement mode per GDD §7.4; • overlay removed after confirming; • radius values configured per plant resource |
| PLANT-05 | All 8 Base Plants Implementation | Plant & Crafting | Critical | Done | PLANT-03 | [Unassigned] | XL | • All 8 plants functional per GDD §7.1: Dianthus, Bougainvillea, Rafflesia, Melati, Wijaya Kusuma, Beringin, Kecombrang, Kunyit; • unlock conditions match GDD; • each plant's passive/active effect triggers correctly in combat |
| PLANT-06 | Crafting Menu (4 Weapons + Upgrades) | Plant & Crafting | Critical | Done | PLANT-01 | [Unassigned] | L | • All 4 weapons craftable per GDD §7.3: Thorn Sword, Spore Bomb, Vine Whip, Petal Shield; • each one-step upgrade path available (e.g. Blazeblade); • crafting deducts correct materials from inventory |
| PLANT-07 | Full Energy System | Core Mechanics | Critical | Done | CORE-08 | [Unassigned] | M | • +3 energy/hit, +10/kill, +2 energy/s near Core per GDD §13.3; • active skill costs 20–50 energy; • energy bar added to HUD with smooth fill animation |
| PLANT-08 | Loadout System (2 Weapons + 1 Skill Slot) | Player | High | Done | CORE-05, PLANT-06 | [Unassigned] | M | • 2 weapon slots (hotbar 1 & 2) + 1 active skill slot per GDD §9.2; • loadout locked during Night phase; • swap available at Garden Base or in Afternoon phase only |
| PLANT-09 | Spore Bomb Weapon | Combat | High | Done | PLANT-06 | [Unassigned] | M | • Thrown projectile, 1 s delay before detonation, AoE damage + slow per GDD §14; • upgrade to Void Grenade with Shadow Resin; • impact VFX plays on detonation |
| PLANT-10 | Vine Whip Weapon | Combat | High | Done | PLANT-06 | [Unassigned] | M | • 2.5-tile melee range with enemy pull mechanic per GDD §14; • upgrade to Crystal Lash with Kunyit; • pull animation and SFX plays |
| PLANT-11 | Petal Shield Weapon | Combat | High | Done | PLANT-06 | [Unassigned] | M | • Blocks 80% incoming damage; perfect-timing block triggers counter-attack per GDD §14; • upgrade to Iron Bloom Shield with Shadow Resin; • block/counter VFX plays |

---

## Phase 3 — Content Expansion

| Task ID | Title | Category | Priority | Status | Dependencies | Assignee | Effort | Acceptance Criteria |
|---------|-------|----------|----------|--------|--------------|----------|--------|---------------------|
| ENEMY-01 | Voidrunner Enemy FSM | Enemy AI | High | Done | CORE-06 | [Unassigned] | M | • 25 HP, 5 DMG/hit per GDD §8.1; • FSM skips Scout state entirely, rushes Core immediately on spawn; • weak to slow traps and Rafflesia; unlocks Day 2 |
| ENEMY-02 | Stonehusk Enemy FSM | Enemy AI | High | Done | CORE-06 | [Unassigned] | M | • 120 HP, 20 DMG/hit per GDD §8.1; • Retreat state removed — stays in Siege/Attack until death; • weak to Vine Whip and Crystal Lash; unlocks Day 4 |
| ENEMY-03 | Phantom Weaver Enemy FSM | Enemy AI | High | Done | CORE-06 | [Unassigned] | L | • 60 HP, 12 DMG/hit per GDD §8.1; • teleports when HP < 30% and re-enters Scout state; • weak to Wijaya Kusuma and light-AoE; unlocks Day 6 |
| ENEMY-04 | Swarm Larva Enemy FSM | Enemy AI | High | Not Started | CORE-06 | [Unassigned] | L | • 15 HP/unit, 3 DMG, spawns 5–10 per GDD §8.1; • group movement coordinated toward Core; • weak to AoE weapons; unlocks Day 8 ⚠️ *GDD §8.1 does not clarify whether each unit has an independent FSM or a shared group FSM — must be decided* |
| ENEMY-05 | The Devourer Boss (3 Phases + Minion Summon) | Enemy AI | High | Not Started | ENEMY-01, ENEMY-02, ENEMY-03, ENEMY-04 | [Unassigned] | XL | • 1200 HP, 50 DMG/hit per GDD §8.1; • 3 mechanically distinct phases with minion summoning; • weak to Dianthus Pollen weapon; triggers on final story night ⚠️ *GDD §8.1 names 3 phases but defines no HP thresholds, phase-transition logic, or minion types — full sub-document required before implementation* |
| WORLD-01 | Dusk Forest Zone | World & Map | High | Not Started | CORE-01 | [Unassigned] | L | • Dim-light biome tilemap with desaturated palette; Moonspore, Wijaya Kusuma, Rafflesia nodes placed per GDD §10.1; • unlocks Day 3; scene transition from Meadow Edge |
| WORLD-02 | Ruins of Veld Zone | World & Map | High | Not Started | WORLD-01 | [Unassigned] | L | • Ruined-city biome tilemap; Shadow Resin and Kunyit nodes per GDD §10.1; • unlocks Day 7 via story quest gate; zone contains a story-relevant landmark |
| WORLD-03 | Obsidian Bog Zone | World & Map | Medium | Not Started | WORLD-02 | [Unassigned] | L | • Black-swamp tilemap; Aether Bloom spawn nodes per GDD §10.1; • unlocks Day 14 ⚠️ *GDD §10.1 says "terrain sulit" but does not define the mechanic — movement speed penalty? periodic damage? must be decided* |
| WORLD-04 | Core Sanctum Zone | World & Map | Medium | Not Started | WORLD-03, QUEST-05 | [Unassigned] | M | • Sacred biome tilemap; unlimited Dianthus Pollen nodes per GDD §10.1; • access gated behind final story quest completion |
| WORLD-05 | Garden Expansion (12×10 → 20×16) | World & Map | Medium | Not Started | PLANT-03 | [Unassigned] | M | • Garden grid expandable with Verdant Sap + Stone per GDD §10.2; • expanded grid slots immediately usable for plant placement; • expansion is incremental, not a single unlock |
| WORLD-06 | Garden Structures (Storage & Watchtower) | World & Map | Medium | Not Started | WORLD-05 | [Unassigned] | M | • Storage structure adds inventory slots per GDD §10.2 & §6.2; • Watchtower displays spawn direction indicators on minimap during night per GDD §10.2; • both structures require material cost |
| DIFF-01 | Difficulty Scaling System | Core Mechanics | High | Done | CORE-07 | [Unassigned] | M | • Enemy HP/DMG/speed scale per tier per GDD §8.2: Early (D1–5), Mid (D6–14), Late (D15–29), Endless (D30+); • spawn count increases on schedule; • all values data-driven in a resource file |
| DIFF-02 | Surge Night (Every 7th Night) | Core Mechanics | High | Not Started | DIFF-01 | [Unassigned] | M | • Nights 7, 14, 21… spawn 3× normal enemy count, all one tier stronger per GDD §8.2; • all 4 entry points active simultaneously; • Surge Night ambient wind cue fires per GDD §12.3 |
| DIFF-03 | Voidlord Mini-Boss (Night 21) | Enemy AI | Medium | Not Started | ENEMY-01, DIFF-01 | [Unassigned] | M | • Voidlord appears Night 21 as Devourer precursor per GDD §8.2; • unique attack pattern distinct from Voidrunner; • defeat triggers story dialogue and zone unlock hint |
| PLANT-12 | All 24 Cross-Breed Combinations | Plant & Crafting | Medium | Not Started | PLANT-02, PLANT-05 | [Unassigned] | XL | • All 24 combos implemented as data-driven resources per GDD §7.2; • known combos always yield same result; • failure states (Wilted Plant at > 30% score, no output at < 30%) functional ⚠️ *GDD §7.2 defines only 4 of 24 combos — full combination table must be authored before this task begins* |

---

## Phase 4 — UI, Quests & Systems

| Task ID | Title | Category | Priority | Status | Dependencies | Assignee | Effort | Acceptance Criteria |
|---------|-------|----------|----------|--------|--------------|----------|--------|---------------------|
| UI-01 | Full HUD Implementation | UI/HUD | High | Done | CORE-10, PLANT-07 | [Unassigned] | L | • All 7 HUD elements per GDD §11.1: Player HP, Core HP, Energy Meter, Time-of-Day indicator, Hotbar (2 weapon + 1 skill), Minimap, Wave Counter; • minimap shows spawn direction arrows at night only |
| UI-02 | Inventory Screen (30-Slot Grid) | UI/HUD | High | Done | CORE-02 | [Unassigned] | M | • 30-slot grid per GDD §6.2; • stack limits enforced (99 Common / 20 Uncommon / 5 Rare); • shortcut I opens/closes |
| UI-03 | Quest Log Screen | UI/HUD | High | Done | QUEST-01 | [Unassigned] | M | • Active quests shown with progress bars per GDD §11.2; • shortcut Q opens/closes; • completed quests archived in a separate tab |
| UI-04 | Plant Codex Screen | UI/HUD | Medium | Done | PLANT-05, QUEST-04 | [Unassigned] | M | • Lists all discovered plants and attempted combos per GDD §11.2; • entries unlock on discovery; • unknown combos display "?" |
| UI-05 | Pause Menu | UI/HUD | High | Not Started | FOUND-01 | [Unassigned] | S | • Accessible at any time (excluding hard-scripted cutscenes); • sub-screens: Settings, Save/Load, Main Menu per GDD §11.2; • game time frozen while paused |
| SAVE-01 | Auto-Save System (Post-Night) | Save System | High | Done | CORE-09 | [Unassigned] | M | • Auto-save fires on day transition after successful night per GDD §11.3; • persists: day count, inventory, garden layout, quest state, player stats, unlock flags |
| SAVE-02 | Manual Save & Single-Slot Load | Save System | High | Done | SAVE-01 | [Unassigned] | S | • Manual save available in Exploration and Preparation phases per GDD §11.3; • single slot; New Game shows overwrite confirmation if save exists |
| QUEST-01 | Quest System Architecture | Quest System | High | Done | FOUND-01 | [Unassigned] | L | • `QuestManager` autoload tracks active/completed quests via signals; • quest data defined in `Resource` files (not hard-coded); • `quest_progress_updated` and `quest_completed` signals emitted correctly |
| QUEST-02 | Daily Quests | Quest System | Medium | Not Started | QUEST-01 | [Unassigned] | M | • Daily objectives generated each Morning per GDD §16 (e.g., "Collect 10 Petal Shard", "Defeat 5 Shadowling"); • reward granted on completion; • quest expires at end of same day |
| QUEST-03 | Progress Quests | Quest System | Medium | Not Started | QUEST-01 | [Unassigned] | M | • Milestone quests track cumulative stats per GDD §16 (e.g., "Survive to Day 10", "Unlock all zones before Day 15"); • reward: Aether Bloom or upgrade unlock |
| QUEST-04 | Discovery Quests | Quest System | Medium | Not Started | QUEST-01, PLANT-05 | [Unassigned] | M | • Quests fire when new plant is found or new breeding combo is attempted per GDD §16; • reward: Codex entries and new recipes |
| QUEST-05 | Story Quests | Quest System | High | Not Started | QUEST-01, WORLD-02 | [Unassigned] | L | • Full chain per GDD §16: Ruins investigation → Voidlord → Devourer; • critical quests carry time limits; • failure triggers alternative ending, not immediate game over per GDD §5.1 |
| END-01 | True Ending | Core Mechanics | High | Not Started | ENEMY-05, QUEST-05 | [Unassigned] | M | • Full Dianthus potential unlocked + Devourer defeated on Day 30+ triggers True Ending per GDD §5.2; • Endless mode unlocks after credits |
| END-02 | Survival Ending | Core Mechanics | Medium | Not Started | DIFF-01 | [Unassigned] | S | • Surviving to Day 20 without unlocking full Dianthus potential triggers Survival Ending per GDD §5.2; • open-story resolution screen displayed |
| END-03 | Discovery Ending | Core Mechanics | Medium | Not Started | QUEST-04 | [Unassigned] | S | • Completing all Discovery Quests triggers Discovery Ending per GDD §5.2; • Dianthus evolves into a living creature in the outro |
| END-04 | Endless Post-Game Mode | Core Mechanics | Low | Not Started | END-01 | [Unassigned] | M | • Endless mode unlocks after True Ending per GDD §5.2; • exponential scaling (×1.5 HP/DMG every 5 days) continues indefinitely; • local leaderboard records highest day reached |

---

## Phase 5 — Minigames, Audio & Polish

| Task ID | Title | Category | Priority | Status | Dependencies | Assignee | Effort | Acceptance Criteria |
|---------|-------|----------|----------|--------|--------------|----------|--------|---------------------|
| MINI-01 | Plant Experimentation Minigame | Minigames | High | Not Started | PLANT-02 | [Unassigned] | L | • Rhythm/puzzle input determines breeding quality (Biasa/Superior/Masterwork) per GDD §17; • score < 30% → resource lost, no output per GDD §7.2; • skippable after tutorial ⚠️ *GDD §17 gives no input scheme, scoring algorithm, or visual layout — prototype two concepts before committing* |
| MINI-02 | Crafting Assembly Minigame | Minigames | Medium | Not Started | PLANT-06 | [Unassigned] | L | • Drag-and-drop components in correct order per GDD §17; • perfect run awards +10% weapon damage; • playable with both mouse and controller |
| MINI-03 | Harvest QTE Minigame | Minigames | Medium | Not Started | CORE-02 | [Unassigned] | M | • QTE fires on rare resource pickup per GDD §17; • failure = 50% yield; • input window scales with current difficulty setting |
| AUDIO-01 | Exploration Phase Music | Audio/Visual | Medium | Not Started | FOUND-01 | [Unassigned] | M | • Light acoustic track plays during Morning/Exploration per GDD §12.3; • loops seamlessly; • volume respects audio settings |
| AUDIO-02 | Preparation Phase Music | Audio/Visual | Medium | Not Started | FOUND-05 | [Unassigned] | S | • Tense underscore plays during Afternoon per GDD §12.3; • smooth crossfade from Exploration track |
| AUDIO-03 | Night Defense Music (Dynamic Layer) | Audio/Visual | High | Not Started | FOUND-05 | [Unassigned] | M | • Dark synth-percussion track plays at Night per GDD §12.3; • high-intensity layer added automatically when >50% enemies alive; • layer crossfade is smooth in both directions |
| AUDIO-04 | Key SFX Implementation | Audio/Visual | Medium | Not Started | CORE-05, PLANT-05 | [Unassigned] | L | • All key SFX per GDD §12.3: crafting chime, plant activation, enemy hit, Core damage boom, Surge Night wind cue; • SFX volume balanced against music |
| VFX-01 | Player Animations | Audio/Visual | High | Not Started | FOUND-03 | [Unassigned] | L | • Attack, roll/dodge, and respawn animations per GDD §12.2; • states linked to player state machine; • respawn plays brief invincibility glow |
| VFX-02 | Dianthus Core Animations | Audio/Visual | High | Not Started | CORE-03 | [Unassigned] | M | • Idle glow, damage state, and destruction animations per GDD §12.2; • glow intensity tied to current HP value |
| VFX-03 | Enemy Animations | Audio/Visual | Medium | Not Started | CORE-06 | [Unassigned] | L | • Walk, attack, death, and retreat animations for all 6 enemy types per GDD §12.2; • death animation plays fully before entity removed |
| VFX-04 | Plant Animations | Audio/Visual | Medium | Not Started | PLANT-05 | [Unassigned] | M | • Bloom (placement), active effect, and wither animations for all 8 plants per GDD §12.2; • wither triggers when plant is destroyed by enemies |
| VFX-05 | Weapon VFX | Audio/Visual | Medium | Not Started | CORE-05, PLANT-09, PLANT-10, PLANT-11 | [Unassigned] | M | • Swing arc and impact particles for all 4 weapons and their upgraded forms per GDD §12.2 |
| ACCESS-01 | 3 Difficulty Levels | Accessibility | High | Done | DIFF-01 | [Unassigned] | M | • Normal (default), Easy (enemy −20% stats), Hard (enemy +30% stats) per GDD §11.4; • selectable at new game start; • changeable in Settings mid-run |
| ACCESS-02 | Colorblind Mode | Accessibility | Medium | Done | UI-01 | [Unassigned] | S | • HP and Energy bars show supplemental icons alongside color coding per GDD §11.4; • toggle available in Settings |
| ACCESS-03 | Interactive Tutorial (Days 1–3) | Accessibility | High | Not Started | CORE-09 | [Unassigned] | L | • Tutorial guides player through movement, combat, crafting, and night defense across Days 1–3 per GDD §11.4; • fully skippable via Settings |
| ACCESS-04 | Text Speed Setting | Accessibility | Low | Not Started | UI-05, DIALOG-01 | [Unassigned] | XS | • Text speed slider (Slow / Normal / Fast / Instant) in Settings per GDD §11.4; • wired to Dialogic text-speed setting |
| DIALOG-01 | Dialogic Dialog System Integration | Quest System | High | In Progress | FOUND-01 | [Unassigned] | M | • Dialogic addon installed at `addons/dialogic/`; • author `.dch` character resources for named NPCs; • create `.dtl` timeline files for tutorial prompts + story quest cutscenes per GDD §16; • `Dialogic.start(timeline)` callable from QuestManager / NPC interact; • text-speed setting wired to Dialogic subsystem; • dialog pauses game world input while active |
| RES-01 | Resource Scarcity Scaling | Resource & Inventory | Medium | Not Started | DIFF-01 | [Unassigned] | M | • Common resources remain accessible throughout; Uncommon/Rare spawn rates decrease every 5 days per GDD §6.3; • Night reward (3–5 Common + 1 Uncommon per cleared wave) implemented |
| QA-01 | Full QA Pass | Polish/QA | High | Not Started | (all above) | [Unassigned] | XL | • All phases tested end-to-end; • no Critical or High bugs (crash, game-breaking, data loss); • performance ≥ 30 FPS on target hardware; • all GDD §5–§17 features verified functional |

---

## ⚠️ Top 5 Highest-Risk Items

### Risk 1 — ENEMY-05: The Devourer (3-Phase Boss)
**Why risky:** GDD §8.1 confirms a 3-phase boss with minion summoning but defines **zero** phase thresholds, transition triggers, or minion types. It is the most complex entity in the project and directly gates the True Ending (END-01).  
**Mitigation:**
- Author a dedicated Devourer sub-document (HP breakpoints, phase abilities, minion roster) before any code is written.
- Stub the boss as a standard enemy in Phase 3; layer phases iteratively in a separate sprint.
- Set a hard feature-freeze date so boss polish does not delay the rest of the game.

---

### Risk 2 — PLANT-12: All 24 Cross-Breed Combinations
**Why risky:** GDD §7.2 defines only 4 of the 24 planned combos. The remaining 20 are unspecified, creating content-design debt that blocks MINI-01 (minigame integration) and QUEST-04 (Discovery Quests).  
**Mitigation:**
- Create a cross-breeding spreadsheet immediately — fill all 24 combos before PLANT-05 is merged.
- Store combo data in external `.tres` resource files (not hard-coded) so new combos are non-breaking additions.

---

### Risk 3 — MINI-01: Plant Experimentation Minigame
**Why risky:** GDD §17 describes the minigame only as *"ritme sederhana / puzzle singkat"* with no input scheme, scoring formula, or visual mockup. This vagueness commonly causes scope creep or a feel-bad integration into the crafting loop.  
**Mitigation:**
- Prototype two independent mechanic candidates (rhythm-tap vs. node-connection puzzle) as isolated scenes during Phase 2.
- Run a short playtest before committing to one approach.
- Define a minimum-viable scoring function (e.g., a single accuracy percentage) early so PLANT-02 can integrate it even if visual polish is deferred.

---

### Risk 4 — AUDIO-03: Dynamic Music Layer System
**Why risky:** Reactive music (toggling a high-intensity audio bus layer based on live enemy count) requires careful `AudioStreamPlayer` bus routing in Godot. A late or rushed implementation produces jarring cuts that hurt perceived game quality.  
**Mitigation:**
- Prototype the bus-layering system (crossfade via `set_volume_db` tween) as a standalone scene in Phase 1, before night combat is content-complete.
- Define crossfade duration (recommended 2–4 s) and bus routing in a `MusicManager` autoload from day one.

---

### Risk 5 — SAVE-01 / SAVE-02: Save State Coherence
**Why risky:** The single save slot must serialize a large, evolving graph of state: day count, 30-slot inventory, garden grid (plant positions, HP, unlock status), quest progress, difficulty, and unlock flags. Features added in later phases routinely break earlier save schemas.  
**Mitigation:**
- Define and version the save dictionary schema (e.g., `{ "schema_version": 1, … }`) during Phase 1, even if only stub fields are used.
- Write a schema migration function that upgrades older saves when `schema_version` is outdated — call it on every load.
- Avoid storing node references in the save file; serialize IDs and reconstruct references at load time.
