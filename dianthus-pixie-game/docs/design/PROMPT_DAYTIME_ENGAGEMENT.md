# Prompt: Daytime Engagement Overhaul — Making the 3-Minute Day Feel Full

## Problem Statement

Despite six daytime-focused tasks being completed (DAY-01 through DAY-06), the daytime phase remains boring. Players finish gathering, crafting, breeding, and plant placement with approximately **60 seconds to spare**, then idle until nightfall.

### Root Cause Analysis

The existing daytime systems create **decisions about what to do**, but each activity completes too quickly and too passively. The specific causes are:

1. **Crafting and breeding pause the game clock.** The player opens the bench, the game freezes, they craft/breed in paused time, then unpause with zero time cost. This eliminates what should be one of the biggest daytime time sinks.
2. **Plant placement is instantaneous.** Enter placement mode, click 1–8 tiles, exit. Under 10 seconds for a full garden rearrangement.
3. **No daytime threats.** The world is completely safe during DAY. Once the player learns the routes, there is zero tension while gathering. The bramble patches are a one-time obstacle per day.
4. **Resource nodes are spatially static.** The same positions are used every day (randomized by a seeded RNG that only toggles whether a node spawns). The player memorizes the map within 2–3 days and stops exploring.
5. **Only 2 scout tracks exist.** Each takes ~5 seconds to interact with. Combined cost: ~40 seconds of travel + 10 seconds of interaction. That fills less than 30% of the phase.
6. **No garden upkeep cost.** Plants, once placed, require zero maintenance. The garden does not demand any daytime attention.
7. **Nothing scales daytime complexity.** Enemy HP/DMG/count scales with day count, but daytime has no parallel progression. Day 1 and Day 20 feel identical during exploration.
8. **No time-consuming preparation actions.** Loadout changes are instant. There are no traps to set, walls to repair, or fortifications to build.

### What Currently Works

These systems are solid and should be preserved:

- **Route structure** — 3 arms with distinct resource profiles (Petal Field, Sap Grove, Old Root Hollow/Ruin Glimmer)
- **Rarity-based spawn probabilities** — COMMON/UNCOMMON/RARE tiers with scarcity scaling
- **Harvest QTE** — Active interaction for UNCOMMON/RARE pickups
- **Bramble patches** — Obstacle-gated optional pockets
- **Scout tracks** — Daytime-to-night strategic link
- **Return pressure** — Dusk tint, audio, HUD warning at 30 seconds remaining
- **Daily quest variety** — Objectives like "collect 10 Petal Shards" or "defeat 5 Shadowlings"

---

## Design Goal

Transform daytime from a **checklist of quick tasks** into a **time-pressured expedition + preparation phase** where the player consistently runs out of time and must make trade-offs between:

- **Gathering** — resources for crafting and breeding
- **Preparing** — fortifying the garden and setting up defenses
- **Investigating** — scouting, discovering, and reacting to daily events
- **Maintaining** — keeping existing plants and defenses operational

Target: the player should finish each day feeling like they accomplished **most** of what they needed but had to **sacrifice 1–2 priorities** due to time pressure.

---

## Proposal 1: Real-Time Crafting & Breeding (High Impact, Low Effort)

### Problem It Solves
Crafting and breeding currently cost zero in-game time because they pause the clock.

### Design
- **Crafting Screen and Cross-Breeding Screen no longer pause the game tree.** Instead, they use `PROCESS_MODE_ALWAYS` but do NOT call `get_tree().paused = true`. The world keeps ticking while the player is in a menu.
- **Add a short crafting delay:** When the player presses "Craft" or "Breed", a progress bar fills over **3–5 seconds of real time** before the item/weapon is produced. The player can cancel, but they lose the time spent.
- The player must **stand near the Breeding Bench** for the duration. Walking away cancels the action.
- This alone converts ~15–30 seconds of "free" paused time into real time investment per crafting session.

### Why This Works
The bench is located in the garden, near the Core. Every second spent crafting is a second not spent gathering. This creates a daily trade-off: "Do I craft now, or gather one more route arm and craft tomorrow?"

### Implementation Scope
- Modify `crafting_screen.gd` and `cross_breeding_screen.gd`: remove `get_tree().paused = true/false` calls
- Add a `CraftingTimer` (3–5 seconds) that runs in real time before `CraftingManager.craft()` executes
- Add a distance check: if player moves >48px from bench, cancel crafting and close screen
- Add a progress bar to the crafting/breeding UI
- Breeding Bench interaction already checks proximity — extend to enforce stay-near requirement

### Task IDs
New: **DAY-07** (Real-Time Crafting)

---

## Proposal 2: Garden Maintenance — Plant Wilting & Watering (High Impact, Medium Effort)

### Problem It Solves
Plants require zero upkeep after placement, eliminating all garden-related daytime activity.

### Design
Each placed plant has a **vitality meter** (0–100%, starts at 100%).

- **Overnight decay:** Every night survived, each plant loses 15–25% vitality (scaled by difficulty). Plants at 0% vitality become **wilted** and stop providing their effect (no damage, no buffs, no barriers).
- **Watering/Tending interaction:** During DAY, the player can press E near a wilted or low-vitality plant to **tend** it. Tending takes **2–3 seconds** (hold interaction) and restores 50% vitality. Costs 1 Petal Shard per plant tended.
- **Visual feedback:** Plant modulate shifts toward grey/brown as vitality drops. Wilted plants are visually obvious (desaturated, drooping).
- **Full garden of 8 plants** = up to 8 tending interactions × 2–3 seconds each = **16–24 seconds** of dedicated garden time per day, plus the Petal Shard cost.

### Why This Works
- Creates a daily garden visit that costs real time and resources
- Introduces a resource sink for Common items (Petal Shards become important even in late game)
- Adds a strategic choice: "Do I tend all 8 plants, or let 2 weak ones wilt and save time?"
- Scales naturally — more plants = more maintenance burden

### Implementation Scope
- Add `var vitality: float = 100.0` to `plant_base.gd`
- Add `tend()` method that restores vitality, requires proximity + E key hold
- Add `_apply_overnight_decay()` called on `DayNightCycle.phase_changed → "DAY"`
- Add visual vitality feedback (modulate lerp in `_process`)
- Plants with vitality ≤ 0 disable their effect (check in each plant subclass)
- Add vitality to garden save/load serialization
- Petal Shard cost deducted via `InventoryManager.remove_item()`

### Task IDs
New: **DAY-08** (Plant Vitality & Tending)

---

## Proposal 3: Daytime Roaming Threats — Night Remnants (Medium Impact, Medium Effort)

### Problem It Solves
Daytime has zero combat tension. The world feels completely inert once brambles are cleared.

### Design
Each morning, **1–3 weakened "remnant" enemies** from the previous night's wave persist into the DAY phase instead of despawning. These are:

- **Half HP** of their normal night values
- **Slower** (60% base speed)
- Patrol near the route arms, especially guarding high-value resource nodes
- Drop a small bonus resource on death (1 random UNCOMMON material)
- Count toward daily quest "kill" objectives
- Do NOT attack the Core — they roam aimlessly near their spawn point

### Behavioral Rules
- Remnants only exist if the player survived the previous night (Day 1 has none)
- Count scales: Day 2–5 = 1 remnant, Day 6–14 = 2, Day 15+ = 3
- Remnant types are pulled from the previous night's actual wave composition
- Remnants despawn automatically at the 30-second return pressure mark (so they don't follow the player into night)

### Why This Works
- Adds light combat encounters during exploration without turning daytime into a second defense phase
- High-value nodes guarded by remnants create risk/reward decisions
- Rewards combat-savvy players with bonus UNCOMMON resources
- Creates narrative continuity: night battles leave traces in the world
- Scales with game progression naturally

### Implementation Scope
- Modify `wave_spawner.gd`: on `wave_cleared`, mark 1–3 enemies as `_remnant = true` instead of killing them; transition to a new `Remnant` FSM state (roam, no core targeting)
- Add `remnant_idle` / `remnant_roam` state: slow wander near initial position, attack player if within detection radius, do NOT seek Core
- Despawn remnants on `phase_changed → "NIGHT"` or at 30-second DAY remaining
- Add bonus loot drop in `enemy_base.gd` `_die()` when `_is_remnant`

### Task IDs
New: **DAY-09** (Night Remnants)

---

## Proposal 4: Daily Expedition Events — Randomized POIs (High Impact, Large Effort)

### Problem It Solves
The map is spatially static — nothing changes between days except which resource nodes spawn.

### Design
Each morning, **one random expedition event** spawns at a designated event location on the map. The player discovers it during exploration and can choose to engage or ignore it. Each event costs **15–30 seconds** of real time to resolve.

### Event Types (implement 4 for MVP, expand later)

#### 4A. Corrupted Root (Combat + Reward)
- A pulsing dark root node spawns at a random route arm
- The player must attack it (HP: 50, same as bramble interaction pattern)
- **Reward:** Destroying it **seals one enemy spawn point tonight** — that cardinal direction spawns zero enemies
- **Trade-off:** 10–15 seconds of combat + travel time to reach it

#### 4B. Wild Seedling Rescue (Timed Interaction + Reward)
- A glowing seedling node appears at a random side pocket
- Press E to begin a 4-second hold interaction
- **Reward:** Grants 1 random seed (plant type the player hasn't discovered yet, or a random base seed if all discovered)
- **Trade-off:** Travel time to the side pocket + 4 seconds of hold interaction

#### 4C. Void Fissure (Risk + Rare Reward)
- A small dark portal appears near Old Root Hollow or Ruin Glimmer
- Interacting starts a **10-second survival challenge**: the player must stay within a small circle while 3 weak shadow enemies spawn around them
- **Reward:** 1 RARE material (aether_bloom, dianthus_pollen, or kecombrang_extract)
- **Trade-off:** Combat risk + 15 seconds of time + health cost
- **Failure:** Walking outside the circle or dying cancels the event with no reward

#### 4D. Dianthus Resonance Bloom (Core Buff + Time Cost)
- A pink glowing flower appears near the Garden Gate area
- Interacting begins a 6-second channeling hold (player must stand still)
- **Reward:** Core starts tonight with a **temporary 20% max HP shield** (extra HP buffer that doesn't regenerate)
- **Trade-off:** 6 seconds of channeling + the node is near the garden (so the player must return early to use it)

### Spawn Rules
- One event per day, chosen randomly from the available pool
- Events rotate so the player doesn't see the same one two days in a row
- Event location is semi-random: each event type has 2–3 candidate positions, one is chosen per day
- Events are visible on the minimap as a **yellow "!" marker** during DAY phase
- Events despawn at the 30-second return pressure mark if not interacted with

### Why This Works
- Adds daily variety — the map feels different each morning
- Each event creates a unique time/risk trade-off
- Events reward both exploration (you have to find them) and engagement (you have to spend time on them)
- The single-event-per-day limit prevents overwhelm while ensuring every day has "one interesting thing"
- Connects to existing systems: Core HP, seeds, resources, enemy spawning

### Implementation Scope
- New `world/events/` folder with base class `DaytimeEvent` and 4 subclass scenes
- New `DaytimeEventSpawner` node in meadow_edge that picks and places one event each DAY phase
- Each event is an `Area2D` with interaction prompt, visual, timer/combat logic, and reward
- Minimap extension: yellow "!" dot for active event position
- Events self-destruct at 30-second DAY remaining or on phase change

### Task IDs
New: **DAY-10** (Daily Expedition Events)

---

## Proposal 5: Fortification Actions — Traps & Barricades (Medium Impact, Medium Effort)

### Problem It Solves
There is no way to spend daytime improving night defenses beyond plant placement. The player has no physical preparation actions.

### Design
Introduce **2 buildable defense structures** that the player can place during DAY at specific "fortification spots" near the garden perimeter:

#### 5A. Thorn Barricade
- **Cost:** 3 Petal Shards + 2 Verdant Sap
- **Build time:** 4 seconds (hold interaction at a fortification spot)
- **Effect:** Blocks one tile-wide lane for the first 3 enemies that collide with it (60 HP total, enemies attack it instead of passing through)
- **Lasts:** One night (destroyed or despawns at dawn)
- **Placement:** 4 fixed fortification spots at garden perimeter edges (N/S/E/W)

#### 5B. Spore Trap
- **Cost:** 2 Verdant Sap + 1 Moonspore
- **Build time:** 3 seconds (hold interaction)
- **Effect:** First enemy to walk over it takes 15 damage + 3-second slow (0.5× speed)
- **Lasts:** One trigger, then destroyed
- **Placement:** Same 4 fortification spots, player chooses barricade OR trap per spot

### Fortification Spot Rules
- Spots are visible during DAY as subtle ground markers (small stone circles)
- Maximum 4 structures per night (one per spot)
- Building all 4 costs: 12 Petal Shards + 8 Verdant Sap + up to 4 Moonspore
- This creates a significant resource drain that competes with crafting materials
- Structures are purely defensive — they don't help during daytime

### Why This Works
- Adds 12–16 seconds of build time per fortification × up to 4 = up to 64 seconds of preparation activity
- Creates resource competition: "Do I spend Verdant Sap on a trap or save it for crafting the Spore Bomb?"
- Connects daytime actions directly to night defense outcomes
- The fixed spots add map knowledge value (the player learns which directions are most vulnerable)
- Scales with resource availability — early game you can't afford many; late game you must choose between structures and weapon upgrades

### Implementation Scope
- New `world/fortifications/` folder with `FortificationSpot`, `ThornBarricade`, `SporeTrap` scenes
- `FortificationSpot` extends `Area2D`: E key interaction during DAY, checks inventory, build timer, spawns structure
- `ThornBarricade` extends `StaticBody2D`: HP-based blocking, collision with enemies
- `SporeTrap` extends `Area2D`: one-shot trigger on enemy enter, damage + slow
- 4 spots placed in `meadow_edge.tscn` at garden perimeter
- All structures `queue_free()` on `phase_changed → "DAY"` (nightly reset)
- Add to save/load if structures should persist across save (optional — simplest to make them transient)

### Task IDs
New: **DAY-11** (Fortification System)

---

## Proposal 6: Resource Node Positional Variety (Low Impact, Low Effort)

### Problem It Solves
Resource node positions are fixed per zone, making the map feel identical after a few days.

### Design
Each resource rule in `DAYTIME_RESOURCE_RULES` currently has a fixed `positions` array. Expand each array to have **2× as many candidate positions** as the maximum spawn count, and let the seeded RNG select which subset to use each day.

Example: Petal Shard currently has 5 positions. Expand to 10 candidate positions scattered across Petal Field. Each day, the RNG picks 3–5 of the 10 as active spawn points.

### Why This Works
- Zero new systems — just data changes to existing `meadow_edge.gd` constants
- The player can't autopilot to the same spots every day
- Encourages actual exploration instead of memorized routes
- Combines naturally with scarcity scaling (fewer nodes + different positions = real variety)

### Implementation Scope
- Expand position arrays in `DAYTIME_RESOURCE_RULES` (each zone gets 2× candidate positions)
- Existing `_get_shuffled_positions()` already shuffles and selects a subset — no code logic changes needed
- Add 20–30 new `Vector2` position entries across all zones

### Task IDs
Extend existing: **RES-01** (Resource Scarcity Scaling — positional variety addendum)

---

## Recommended Implementation Priority

| Priority | Proposal | Impact | Effort | Reason |
|----------|----------|--------|--------|--------|
| **1** | Real-Time Crafting (DAY-07) | High | S | Smallest code change, biggest immediate time-sink gain. Converts 15–30 seconds of paused time to real time per day. |
| **2** | Plant Vitality & Tending (DAY-08) | High | M | Creates a daily garden ritual (16–24 seconds), resource sink, strategic depth. Touches only plant_base.gd + UI. |
| **3** | Resource Node Positional Variety (RES-01 ext) | Low | XS | Pure data change, no new systems. Reduces route memorization. |
| **4** | Daily Expedition Events (DAY-10) | High | L | Biggest content addition. Implement after 1–3 to fill the remaining gap. Start with 2 events (Corrupted Root + Wild Seedling) then expand. |
| **5** | Fortification System (DAY-11) | Medium | M | Meaningful preparation time sink, but depends on having enough resources to spare (better after DAY-08 creates Petal Shard demand). |
| **6** | Night Remnants (DAY-09) | Medium | M | Adds tension but risk of making daytime feel too combat-heavy. Implement last, tune carefully. |

### Estimated Time Budget After All Proposals

| Activity | Current Time Cost | Proposed Time Cost |
|----------|------------------|--------------------|
| Route gathering (1 full arm + 1 side stop) | ~70s | ~70s (unchanged) |
| Harvest QTE (1–2 UNCOMMON/RARE nodes) | ~10s | ~10s (unchanged) |
| Scout tracks (1 of 2) | ~20s | ~20s (unchanged) |
| Crafting/Breeding (1–2 items) | **0s (paused)** | **10–15s (real time)** |
| Garden tending (4–8 plants) | **0s** | **10–24s** |
| Daily event (1 event) | **0s** | **15–30s** |
| Fortification (1–2 structures) | **0s** | **8–12s** |
| Remnant combat (1–2 enemies) | **0s** | **10–20s** |
| Return to garden | ~15s | ~15s |
| **Total** | **~115s / 180s** | **~168–216s / 180s** |

With all proposals implemented, the player **cannot do everything** — they must choose 4–5 of 7 available activities each day. This is exactly the target state.

---

## Compatibility Notes

- **Save schema:** DAY-08 (plant vitality) requires a schema version bump to serialize vitality per plant. Other proposals are transient state (no save changes).
- **Existing tasks:** None of these proposals conflict with Not Started tasks in `TASK_BREAKDOWN.md`. DAY-07 modifies crafting_screen/cross_breeding_screen (already Done tasks). DAY-08 modifies plant_base.gd (stable). DAY-09/10/11 add new systems in new folders.
- **Difficulty scaling:** DAY-08 decay rate and DAY-09 remnant count should scale with `DifficultyManager` tier (Easy = less decay/fewer remnants, Hard = more).
- **Tutorial impact:** ACCESS-03 (Interactive Tutorial, In Progress) should be updated to introduce tending and real-time crafting on Day 1–2 once those systems are implemented.

---

## Success Criteria

The daytime phase is engaging when:

1. The player **cannot complete all available activities** in a single 3-minute phase
2. Each day requires at least one **trade-off decision** ("I'll skip tending plant #7 to have time for the Corrupted Root event")
3. **Returning players on Day 10+** still find daytime interesting due to positional variety, scaling maintenance, and daily events
4. The preparation phase feels like it **directly improves tonight's defense** (fortifications, tended plants, scouted intel, sealed spawn points)
5. No single activity takes more than **30 seconds** (each piece is bite-sized, but the total exceeds the time budget)
6. Common resources (Petal Shards) have **ongoing demand** beyond early-game crafting (tending cost, fortification cost)
