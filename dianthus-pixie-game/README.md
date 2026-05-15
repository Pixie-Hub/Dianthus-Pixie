# Dianthus Pixie

Dianthus Pixie is a 2D survival-crafting action game built in Godot 4.6. The player explores for resources during the day, prepares the garden with crafting, breeding, plants, and fortifications, then defends the Dianthus Core from night waves in Meadow Edge.

## Current Scope

The implemented game is scoped to three final zones:

- **Meadow Edge** - home base, garden, Dianthus Core, crafting/breeding bench, fortifications, night defense, and the final Devourer fight.
- **Dusk Forest** - exploration zone unlocked through the story path; includes Blackwater Hollow content and resources, but no Core and no night defense.
- **Ruins of Veld** - exploration zone with the Ancient Omen landmark used by the Devourer story chain, but no Core and no night defense.

Obsidian Bog and Core Sanctum are no longer required future zones. Their design roles are folded into Blackwater Hollow and the Sacred Bloom state of the Meadow Edge Dianthus Core.

## Implemented Gameplay

- Day/night loop with daytime exploration and Meadow Edge night defense.
- Dianthus Core health, Core game over, player death/respawn, and night-survived rewards.
- Resource pickup, 30-slot inventory, stack limits, rarity colors, save/load, and storage upgrades.
- Plant placement with 11 implemented plants: Bougainvillea, Rafflesia, Melati, Wijaya Kusuma, Beringin, Kecombrang, Kunyit, Bunga Api, Bunga Bayang, Melati Emas, and Baja Kuning.
- Crafting for four weapons, four weapon upgrades, and three active abilities.
- Breeding bench and four implemented hybrid combinations. The remaining 20 planned combinations are still deferred under `PLANT-12`.
- Enemy FSMs for Shadowling, Voidrunner, Stonehusk, Phantom Weaver, Swarm Larva, and the three-phase Devourer boss.
- Quest, daily quest, progress quest, discovery quest, story quest, Dialogic timeline, ending, Codex, tutorial infrastructure, audio, VFX, HUD, map, and pause/menu systems.

## Controls

- Move: `WASD` or arrow keys
- Interact: `E`
- Attack: left mouse or `Space`
- Dodge: configured as the `dodge` input action in `project.godot`
- Inventory: `I`
- Crafting screen: `C`
- Breeding screen: `B`
- Plant Codex: `J`
- Plant placement: `P`
- Quest log: `Q`
- Loadout: `L`
- Map: `M`
- Active skill: `F`
- Weapon slots: `1`, `2`
- Skip daytime: `N`

Several debug shortcuts exist for testing and are documented in `docs/design/PERSON_TASKS.md`.

## Project Structure

- `accessibility/` - difficulty, settings, and tutorial systems
- `audio/` - SFX and music managers plus runtime audio resources
- `combat/` - weapons, projectiles, and combat data
- `core/` - day/night flow, Dianthus Core, endings, cutscenes, transitions, and night defense
- `crafting/` - crafting recipes, bench logic, breeding data, and breeding UI
- `dialogic/` - project-owned Dialogic timelines, characters, and styles
- `enemies/` - enemy scenes, FSM states, spawner, and Devourer boss
- `inventory/` - inventory manager, item database, pickups, and item UI
- `minigames/` - plant experimentation, crafting assembly, and harvest QTE
- `plants/` - plant entities, placement systems, sprites, and plant VFX
- `player/` - player scene, controller, animation, and sprite assets
- `quests/` - quest resources, quest manager, daily roller, story flags
- `save/` - save/load and leaderboard persistence
- `shared/` - autoloads, components, constants, fonts, and utilities
- `ui/` - HUD, menus, screens, Codex, quest UI, and reusable components
- `vfx/` - shared effects, particles, shaders, and animation helpers
- `world/` - garden structures, zone scenes, transitions, and tilesets

## References

- Current task status: `docs/design/TASK_BREAKDOWN.md`
- Detailed design reference: `docs/design/Dianthus Pixie GDD.md`
- Story reference: `docs/design/STORY_OUTLINE.md`
- Main scene: `res://ui/menus/main_menu.tscn`
