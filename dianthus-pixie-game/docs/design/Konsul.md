# Dianthus Pixie - Current Presentation Brief

## Project Overview

- Engine: Godot 4.6, Forward Plus
- Genre: 2D survival-crafting action
- Current scope: three final zones only
- Main loop: daytime exploration/preparation, Meadow Edge night defense, story progression toward the Devourer
- Current source of task truth: `docs/design/TASK_BREAKDOWN.md`

## Final Zone Scope

| Zone | Current role | Defense/Core status |
| --- | --- | --- |
| Meadow Edge | Home base, garden, crafting/breeding, fortifications, wave defense, final Devourer fight | Contains Dianthus Core and night defense |
| Dusk Forest | Exploration zone, ambience, resources, Blackwater Hollow path | No Core, no local night defense |
| Ruins of Veld | Exploration zone, Ancient Omen landmark, Devourer story reveal | No Core, no local night defense |

Obsidian Bog and Core Sanctum are no longer required zones. Obsidian Bog's role is folded into Blackwater Hollow. Core Sanctum's role is folded into Sacred Bloom at the Meadow Edge Dianthus Core.

## Implemented Systems To Present

- Day/night loop and return pressure.
- Meadow Edge night defense with WaveSpawner, enemy forecasts, and night-survived rewards.
- Dianthus Core HP, game over, Sacred Bloom pollen harvest, and Core animation states.
- Dusk Forest and Ruins of Veld exploration flow with marker-aware transitions.
- Story quest chain from Core whispers through the Devourer omen and final Devourer fight.
- Inventory, crafting, breeding, plant placement, plant vitality/tending, fortifications, garden structures, save/load, difficulty, Codex, quest log, HUD, and map systems.
- Six enemy types including The Devourer.
- Three ending paths plus Endless leaderboard support.

## Known Limits / Do Not Overpromise

| Area | Current state |
| --- | --- |
| Surge Night | `DIFF-02` is Not Started |
| Night 21 escalation | `DIFF-03` is Not Started and has no Voidlord |
| Cross-breeding | Four hybrid combos implemented; remaining 20 deferred under `PLANT-12` |
| Weapon VFX | `VFX-05` is Not Started |
| Interactive tutorial | `ACCESS-03` is In Progress |
| Full QA | `QA-01` is Not Started |

## Devourer Path

The current story does not use a Voidlord. The Ruins of Veld Ancient Omen reveals the Devourer as the final threat. Story 06 prepares Dianthus Pollen power from Sacred Bloom. Story 07 turns a Meadow Edge night defense into the final Devourer fight.

The final confrontation is part of the garden defense loop, not a separate Core Sanctum zone.

## Recommended Presentation Framing

Present Dianthus Pixie as a scoped vertical-slice game with a complete three-zone adventure path:

1. Explore and gather in Meadow Edge, Dusk Forest, and Ruins of Veld.
2. Build up the garden and plant arsenal in Meadow Edge.
3. Defend the Dianthus Core at night.
4. Follow the omen story to identify the Devourer.
5. Return to Meadow Edge for the final defense.

Avoid describing Obsidian Bog, Core Sanctum, Voidlord, all 24 breeding combos, Surge Night, or final QA as shipped content.
