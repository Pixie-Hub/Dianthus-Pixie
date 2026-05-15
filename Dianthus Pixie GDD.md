# Dianthus Pixie

## Game Design Document

> Engine: Godot 4.6 Forward Plus | Style: 2D pixel art | Current design version: 1.2 | Updated: 2026-05-15

---

# 1. Current Scope

Dianthus Pixie is a single-player survival-crafting action game about restoring and defending the Dianthus Core. The current implemented scope is final-zone scoped, not an open-ended future-zone plan.

The final zone list is:

| Zone | Role | Defense? | Core? | Current state |
| --- | --- | --- | --- | --- |
| Meadow Edge | Home base, garden, crafting/breeding, fortification, night waves, final boss arena | Yes | Yes | Implemented |
| Dusk Forest | Exploration zone and Blackwater Hollow story/resource path | No | No | Implemented |
| Ruins of Veld | Exploration zone and Ancient Omen story landmark | No | No | Implemented |

Obsidian Bog is no longer a required zone. Its useful design role is represented by Blackwater Hollow inside Dusk Forest. Core Sanctum is no longer a required zone. Its useful design role is represented by the Sacred Bloom state of the Dianthus Core in Meadow Edge.

# 2. High Concept

The player explores during the day, gathers resources, tends and expands the garden, crafts plant-based weapons and abilities, breeds hybrid plants, and prepares defenses before night. At night, the defense loop only happens in Meadow Edge: enemies attack the Dianthus Core and the player must protect it.

Dusk Forest and Ruins of Veld are exploration zones. They support resource discovery, story progression, ambience, and return-to-defense pressure, but they do not host night waves.

# 3. Player-Facing Loop

1. Start in Meadow Edge.
2. Explore Meadow Edge or unlocked exploration zones during daytime.
3. Gather resources, seeds, extracts, rare materials, and story discoveries.
4. Return to Meadow Edge before night.
5. Craft weapons or abilities, breed plants, place plants, tend vitality, build fortifications, and adjust loadout.
6. Defend the Dianthus Core from night waves in Meadow Edge.
7. Receive night-survived rewards and continue to the next day.
8. Progress story quests until the Devourer path unlocks the final defense.

# 4. World Design

## 4.1 Meadow Edge

Meadow Edge is the permanent home base. It contains the Dianthus Core, garden grid, plant placement space, crafting/breeding bench, fortification spots, watchtower/storage structures, wave spawner, night-survived result UI, and the final Devourer encounter surface.

Implemented Meadow Edge content includes:

- Warm grassland route layout with side pockets and resource placement.
- Dianthus Core HP, aura, damage, death animation, and Sacred Bloom pollen interaction.
- Garden expansion and garden structures.
- Four perimeter fortification spots.
- WaveSpawner with forecast support and enemy type scaling.
- Night defense manager integration.
- Return pressure and map/minimap support.

## 4.2 Dusk Forest

Dusk Forest is an exploration zone unlocked through Story 02 and `unlock_zone_dusk_forest`. It includes dim forest ambience, marker-aware travel, resource placement, Blackwater Hollow access, cinematic atmosphere VFX, and direct return-to-defense prompts.

It does not contain the Dianthus Core, WaveSpawner, or a night defense loop.

## 4.3 Blackwater Hollow

Blackwater Hollow is a sub-area concept inside Dusk Forest. It absorbs the old Obsidian Bog design role. It is used for darker exploration, rare resources, and the story bridge into the Ruins path. It is not a fourth primary zone.

## 4.4 Ruins of Veld

Ruins of Veld is an exploration zone unlocked after the Dusk Forest/Blackwater story resolution grants `unlock_zone_ruins`. It contains the Ancient Omen landmark. Interacting with that landmark emits the Devourer omen event used by Story 05.

It does not contain the Dianthus Core, WaveSpawner, or a night defense loop. The final fight returns to Meadow Edge.

# 5. Story Path

The current story chain runs from early Core whispers through Dusk Forest, Blackwater Hollow, Ruins of Veld, the Devourer omen, Sacred Bloom pollen crafting, and the final Devourer defense.

Current story beats:

1. Meadow Edge establishes the Dianthus Core and night threat.
2. Dusk Forest opens through the omen path.
3. Blackwater Hollow reveals that darkness can shelter life rather than only destroy it.
4. Ruins of Veld reveals the Ancient Omen and names the Devourer as the real final threat.
5. Story 05 completes when the Devourer omen is deciphered.
6. Story 06 asks the player to harvest Dianthus Pollen from Sacred Bloom and craft the required weapon path.
7. Story 07 activates the final Devourer encounter in Meadow Edge.

There is no Voidlord, no mini-boss precursor, and no required Core Sanctum confrontation.

# 6. Endings

Implemented ending paths are:

| Ending | Trigger direction |
| --- | --- |
| True Ending | Defeat the Devourer, complete the main story, and meet the day threshold. |
| Survival Ending | Reach the survival threshold without completing the full Devourer story path. |
| Discovery Ending | Complete the discovery progression path. |

Endless mode unlocks from the True Ending path and uses the local leaderboard system.

# 7. Systems

## 7.1 Day, Night, and Defense

The project uses a day/night cycle with daytime preparation and night defense. The implementation centers on `DayNightCycle`, `NightDefenseManager`, `WaveSpawner`, `GameManager`, and Meadow Edge scene wiring.

Night defense is Meadow Edge only. Exploration zones can provide return prompts and direct travel back to defense, but they do not run local waves.

Surge Night remains deferred under `DIFF-02`; Night 21 escalation remains a pressure concept under `DIFF-03`, not a named boss.

## 7.2 Health, Energy, and Failure

- Player HP is shown in the HUD.
- The player can die and respawn near the Core after a delay.
- Energy supports active abilities and regenerates from combat/Core proximity.
- Dianthus Core HP reaches zero -> immediate game over.
- Core death has a scene-authored animation path.

## 7.3 Inventory and Resources

Inventory is slot-based with rarity-aware stack limits. Implemented resources and items include Petal Shard, Verdant Sap, Moonspore, Shadow Resin, Aether Bloom, Dianthus Pollen, Stone, plant seeds, plant extracts, and hybrid seeds.

Harvest QTE exists for uncommon and rare pickups. Resource scarcity scaling is implemented.

## 7.4 Crafting and Loadout

Crafting supports:

- Thorn Sword -> Blazeblade
- Spore Bomb -> Void Grenade
- Vine Whip -> Crystal Lash
- Petal Shield -> Iron Bloom Shield
- Dash
- Heal Pulse
- Thorn Burst

The player has two weapon slots and one active skill slot. Loadout changes are locked during night.

## 7.5 Breeding and Plants

Implemented plant entities:

| Plant | Role |
| --- | --- |
| Bougainvillea | Damage aura |
| Rafflesia | Slow aura |
| Melati | Energy regeneration |
| Wijaya Kusuma | Night projectile attacker |
| Beringin | Root wall defense |
| Kecombrang | Attack speed support |
| Kunyit | Melee damage support |
| Bunga Api | Hybrid fire thorns |
| Bunga Bayang | Hybrid slow and night attack |
| Melati Emas | Hybrid HP and energy regeneration |
| Baja Kuning | Hybrid damage reduction |

Four hybrid breeding combinations are implemented:

| Combo | Result |
| --- | --- |
| Bougainvillea Extract + Kecombrang Extract | Bunga Api Seed |
| Rafflesia Extract + Shadow Resin | Bunga Bayang Seed |
| Verdant Sap + Dianthus Pollen | Melati Emas Seed |
| Kunyit Extract + Shadow Resin | Baja Kuning Seed |

The old 24-combo goal is not fully implemented. The remaining 20 combos are explicitly deferred under `PLANT-12`.

## 7.6 Minigames

Implemented minigame surfaces:

- Plant Experimentation
- Crafting Assembly
- Harvest QTE

Plant Experimentation and Crafting Assembly can be skipped after tutorial completion through settings.

## 7.7 Enemies and Boss

Implemented enemies:

| Enemy | Notes |
| --- | --- |
| Shadowling | Base FSM enemy |
| Voidrunner | Fast rush enemy |
| Stonehusk | Heavy siege enemy |
| Phantom Weaver | Teleporting enemy |
| Swarm Larva | Small group enemy |
| The Devourer | Three-phase story boss |

The Devourer is a final story boss, not a precursor. It has 70% and 30% phase thresholds, minion summoning, a Devour Surge concept at low HP, boss music hooks, boss HUD hooks, and a Dianthus Pollen weapon multiplier.

## 7.8 Quest and Dialog

The quest system includes daily, progress, discovery, and story quests. Story dialog uses Dialogic timelines and character resources in the project-owned `dialogic/` folder.

Story quest implementation includes:

- `story_01_whispers`
- `story_02_omen`
- `story_03_journey`
- `story_04_ruins`
- `story_05_devourer_omens`
- `story_06_pollen`
- `story_07_devourer`
- Alternate story loss branches

## 7.9 UI and Screens

Implemented UI includes:

- HUD with player HP, Core HP, energy, hotbar, time indicator, minimap/map support, wave counter, tracked quest, status effects, and forecast surfaces.
- Inventory screen.
- Quest log.
- Plant Codex and enemy Codex.
- Crafting, breeding, loadout, settings, pause, main menu, game over, ending, and night-survived screens.

## 7.10 Save and Progression

Save/load persists day count, inventory, garden state, quest state, difficulty, unlock flags, discovered Codex data, plant vitality, structures, and related progression. Endless leaderboard persistence is implemented.

# 8. Controls

| Action | Binding |
| --- | --- |
| Move | WASD / arrow keys |
| Interact | E |
| Attack | Left mouse / Space |
| Inventory | I |
| Plant Codex | J |
| Plant placement | P |
| Quest log | Q |
| Loadout | L |
| Map | M |
| Active skill | F |
| Weapon slot 1 / 2 | 1 / 2 |
| Skip daytime | N |

Debug controls are intentionally not part of the real player flow. They are documented separately in `docs/design/PERSON_TASKS.md`.

# 9. Technical Baseline

| Area | Current implementation |
| --- | --- |
| Engine | Godot 4.6, Forward Plus |
| Main scene | `res://ui/menus/main_menu.tscn` |
| Resolution | 640x360 viewport, integer canvas stretch |
| Scripting | GDScript 2.0 |
| Dialog | Dialogic 2.x autoload |
| Save | Single-slot save/load with schema migration |
| Audio | SfxManager and MusicManager autoload scenes |
| AI | EnemyBase plus FSM states and custom Devourer states |
| World flow | SceneTransition plus marker-aware zone gates |

# 10. Deferred or Known Gaps

These are intentionally not presented as implemented features:

- `DIFF-02`: Surge Night is still Not Started.
- `DIFF-03`: Night 21 escalation is still Not Started and does not add a Voidlord.
- `PLANT-12`: Only four hybrid combinations are implemented; the remaining 20 are deferred.
- `VFX-05`: Full weapon VFX polish is still Not Started.
- `ACCESS-03`: Interactive tutorial is still In Progress.
- `QA-01`: Full QA pass is still Not Started.
- Some older prompt documents remain historical implementation briefs and may mention superseded zone or boss plans.
