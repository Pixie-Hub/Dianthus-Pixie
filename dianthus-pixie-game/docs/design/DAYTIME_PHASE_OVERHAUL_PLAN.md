# Daytime Phase Overhaul Plan

This document proposes a design overhaul for the daytime phase of Dianthus Pixie. The goal is to make the 3-minute exploration window feel active, strategic, and connected to the preparation and defense phases without replacing the existing core loop.

## Source Alignment

The current game structure already supports this direction:

- GDD loop: daytime exploration and resource gathering, garden crafting and experimentation, then night defense.
- `TASK_BREAKDOWN.md` marks `CORE-01` Meadow Edge Exploration Zone as not started, while `CORE-02` Resource Pickup System is done.
- `MINI-03` Harvest QTE Minigame is planned for rare resource pickups.
- `RES-01` Resource Scarcity Scaling is planned so Common resources remain accessible while Uncommon and Rare resources become scarcer over time.

This means the current passive pickup loop is best treated as an early vertical-slice placeholder, not the final intended daytime design.

## Core Diagnosis

The current daytime phase is not engaging because it has too few decisions per minute. Walking near resources can prove inventory pickup, HUD feedback, and item data, but it does not create enough gameplay pressure for a 3-minute phase.

The core loop does not need to be replaced yet. The existing loop of explore -> craft/breed -> defend is still sound. The issue is that the exploration phase currently lacks:

- Route choices.
- Active gathering actions.
- Risk/reward decisions.
- Small obstacles.
- Discoveries or landmarks.
- Strategic consequences for the upcoming night.

If daytime remains only passive auto-gathering, then the loop itself will start to feel broken because the first third of every day becomes downtime. The design fix is to make daytime a short expedition phase where the player chooses what to pursue and what to abandon before night pressure returns.

## Map And World Diagnosis

The map size and world depth are a major part of the engagement problem. The current Meadow Edge scene is effectively a compact 40x30 tile zone with a small set of placed pickups. That is enough for a vertical slice, but it is not enough for a 3-minute exploration phase.

The problem is not only that the map is small. The larger issue is that it has little depth:

- The space does not ask the player to choose between routes.
- Resources are not arranged into readable sub-areas with different identities.
- There are few landmarks to remember.
- There are no meaningful shortcuts, blocked paths, side pockets, or hidden areas.
- The player has no reason to learn the map across multiple days.
- The safest path and the most rewarding path feel too similar.

Daytime will feel empty if the world is a flat collection area. It needs to become a small expedition map with routes, landmarks, risk zones, and reasons to revisit.

## Design Goal

Turn daytime from "walk through resources" into a short expedition phase where the player chooses:

- Which resource route to prioritize.
- Whether to spend time on risky high-value opportunities.
- Whether to solve small obstacles or take a slower path.
- Whether to improve tonight's defense or invest in long-term growth.

For a 3-minute phase, a good target is:

- 2-3 meaningful route choices.
- 2-4 active gathering interactions.
- 1 optional risk/reward event.
- 1 late-phase pressure decision.

## Design Pillars

### 1. Time Is The Main Cost

The player should rarely be able to do everything in one daytime phase. A good daytime run should end with the player thinking, "I got what I needed, but I had to leave something behind."

### 2. Resources Need Context

Petal Shards, Verdant Sap, rare plants, and discovery clues should not be scattered evenly. They should belong to recognizable places with different levels of safety, travel time, and value.

### 3. Active Play Should Be Selective

Not every pickup needs a minigame. Common resources should stay fast. Higher-value nodes should ask for timing, interaction, or risk.

### 4. Daytime Should Affect Night

The player should sometimes choose between gathering resources and improving information or safety for the next defense phase.

## Actionable Mechanics

### 1. Active Harvesting Tiers

Replace pure passive gathering with a tiered interaction model.

- Common resources: auto-pickup or instant interact.
- Uncommon resources: short hold interaction, around 1-2 seconds.
- Rare resources: trigger a short Harvest QTE.

The planned `MINI-03` task already supports this direction. The QTE should be reserved for rare resources so it feels like an event instead of constant friction.

Player choice:

"Do I spend extra time harvesting this rare node, or do I skip it and reach the next route before the phase ends?"

MVP version:

- Add one rare harvest node type.
- On success, award full yield or bonus yield.
- On failure, award 50% yield as described in the GDD.

### 2. Route-Based Expedition Choices

Restructure daytime gathering around visible route options instead of evenly scattered pickups.

Example route identities:

- Meadow Bloom: safe route with Petal Shards and basic plant materials.
- Sap Grove: Verdant Sap route with bramble obstacles and slower traversal.
- Strange Sprout: lower guaranteed resources, but chance to discover a new plant.
- Ruin Glimmer: story clue or rare material route with higher danger or time cost.

Player choice:

"Tonight I need traps, so I will take the Sap Grove route even though it costs more time."

MVP version:

- Add 2-3 named points of interest to Meadow Edge.
- Give each point of interest a distinct resource profile.
- Make the player choose one main route and maybe one side stop during a 3-minute phase.

### 3. Minor Obstacles

Add light obstacles that create interruption and route evaluation without turning daytime into full combat.

Possible obstacles:

- Bramble patch: blocks a shortcut or resource pocket, cleared with attacks.
- Spore cloud: slows movement unless avoided.
- Root snare: brief timed input to escape.
- Cracked cache: requires several hits to open.
- Small daytime pest: weak enemy guarding optional high-value nodes.

Player choice:

"Do I clear this bramble for the Verdant Sap pocket, or detour to safer resources?"

MVP version:

- Start with bramble patches because they can reuse movement, attack, collision, and HP concepts.
- Place them near optional rewards, not on mandatory paths.

### 4. Daytime Actions That Affect Night

Add optional daytime interactions that change the next defense phase.

Possible actions:

- Scout tracks: reveals one likely enemy entry direction for tonight.
- Seal burrow: reduces enemies from one lane, but costs daytime.
- Gather sunlight pollen: grants a temporary Dianthus Core shield at night.
- Rescue wild seedling: unlocks or discounts a plant option for afternoon preparation.
- Mark enemy path: improves route preview information during defense setup.

Player choice:

"I can gather more resources, or I can spend 20 seconds scouting because my west defense is weak."

MVP version:

- Add Scout Tracks as a low-risk first prototype.
- Interacting with tracks reveals one active night spawn direction on the HUD, minimap, or preparation UI.

## Map Improvement Plan

### 1. Expand The Playable Footprint With Purpose

Do not only make the map larger. A larger empty map will make the problem worse. Expand the map around route structure.

Recommended first Meadow Edge target:

- Keep Garden Base near the center or lower-center.
- Add 3 explorable arms from the base.
- Each arm should take around 25-45 seconds to fully travel and harvest.
- Full completion of all arms should be impossible or very tight within 3 minutes.

This creates a time economy where the player must choose a plan before moving.

### 2. Create Distinct Sub-Areas

Meadow Edge should be split into small recognizable regions.

Suggested initial regions:

- Garden Gate: safe transition area near the core and crafting bench.
- Petal Field: open, safe, common-resource area.
- Sap Grove: denser trees, Verdant Sap, bramble shortcuts.
- Old Root Hollow: obstacle-heavy pocket with uncommon resource chances.
- Ruin Glimmer: small story/discovery corner that hints at later zones.

Each area should have a different visual silhouette, resource table, and traversal feel.

### 3. Add Landmarks

The player needs memorable objects that help them navigate without reading UI.

Examples:

- A huge fallen tree at Sap Grove.
- A ring of pink flowers at Petal Field.
- A cracked stone arch at Ruin Glimmer.
- A glowing root bridge near Old Root Hollow.
- A small pond or stream that shapes pathing.

Landmarks make the world feel authored instead of randomly filled.

### 4. Use Loops, Shortcuts, And Side Pockets

The map should not be one open rectangle. Better exploration layouts use loops and small decisions.

Recommended layout features:

- Main loop from Garden Gate -> Petal Field -> Sap Grove -> Garden Gate.
- Optional side pockets with higher rewards.
- Shortcuts blocked by brambles or unlockable after clearing.
- One risky outer path with rare resources.
- One safe inner path with lower rewards.

The player should learn the map over time and get faster through knowledge.

### 5. Place Resources By Risk And Travel Time

Resource placement should follow clear rules:

- Common resources: near main paths and safe fields.
- Uncommon resources: at the end of side pockets or behind minor obstacles.
- Rare resources: far from base, behind risk, or tied to QTE events.
- Discovery plants: placed near landmarks, not random grass patches.
- Night-impact actions: placed far enough away that choosing them costs real gathering time.

This turns map layout into economy balance.

### 6. Add Return Pressure

The final 30 seconds of daytime should create a decision:

- Return now and prepare safely.
- Push for one more node and risk entering preparation late or underprepared.

Possible support systems:

- Stronger phase warning audio/visuals.
- World tint shift as afternoon approaches.
- Optional fast return shortcuts after clearing brambles.
- Garden path signs or subtle trail markers.

The point is not to punish the player harshly. The point is to make the clock matter.

### 7. Add Progressive World Depth Across Days

The same map should not feel identical every day.

Possible progression:

- Day 1: safe Petal Field and basic Sap Grove.
- Day 2: new Gloomshroom forage pocket opens.
- Day 3: Sunpetal quest marker appears.
- Day 4: brambles regrow in different positions.
- Day 5+: rare nodes become scarcer, but new shortcuts or tools improve routing.

This supports the GDD's scarcity scaling while making the world feel alive.

## Recommended 3-Minute Flow

### 0:00-0:20 - Read The Day

The player sees route opportunities, nearby resource state, and maybe one special event hint.

### 0:20-1:30 - Commit To A Route

The player gathers common and uncommon resources while handling one small obstacle.

### 1:30-2:20 - Optional High-Value Event

A rare harvest, discovery plant, scout clue, or obstacle-guarded cache asks for a time investment.

### 2:20-2:45 - Pressure Decision

The player decides whether to push deeper or start returning.

### 2:45-3:00 - Transition Pressure

Visual and audio changes signal the end of exploration and the need to prepare for defense.

## MVP Implementation Order

This order keeps the scope controlled:

1. Re-layout Meadow Edge into 3 distinct route arms with landmarks.
2. Add bramble obstacles around optional resource pockets.
3. Add one rare harvest node using the planned Harvest QTE behavior.
4. Add one Scout Tracks interaction that reveals a night spawn direction.
5. Add resource placement rules for Common, Uncommon, Rare, and discovery nodes.
6. Tune the 3-minute timer around how much of the expanded map can be reasonably completed.

## Success Criteria

The daytime phase is working when:

- The player cannot collect everything in one run.
- The player can explain why they chose one route over another.
- Rare resources feel exciting rather than automatic.
- The map has memorable places, not only pickup coordinates.
- At least one daytime choice changes preparation or night defense.
- Repeating the phase across multiple days creates different priorities.

## Design Risks

### Risk: Too Much Friction

If every resource requires interaction, gathering becomes tedious. Keep Common resources fast.

### Risk: Bigger But Still Empty

Increasing map size without route structure will make walking time worse. Expansion must add landmarks, shortcuts, and risk zones.

### Risk: Daytime Becomes Combat Phase

Minor enemies or obstacles should support exploration, not replace the night defense identity.

### Risk: Unclear Rewards

The player must understand why a route matters. Use visual resource identity, quest hints, and clear feedback.

## Lead Designer Recommendation

Treat the current daytime phase as a placeholder implementation of the intended exploration phase. The core loop is still viable, but the map and interaction model need depth before the 3-minute timer can feel good.

The highest-impact first change is not a new complex system. It is a better Meadow Edge layout: distinct routes, landmarks, optional side pockets, and resource placement that forces choices. Once the map supports decisions, active harvesting, brambles, and scouting will have a meaningful place to live.
