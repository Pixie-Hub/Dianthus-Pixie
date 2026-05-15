# ENEMY-05 - The Devourer Boss: Current Implementation Reference

> Task: `ENEMY-05` | Current status: Done in `docs/design/TASK_BREAKDOWN.md` | Main files: `enemies/devourer/`, `enemies/spawner/wave_spawner.gd`, `combat/weapons/weapon_data.gd`, `ui/hud/`

The Devourer is the final named boss in the current story path. There is no Voidlord or mini-boss precursor. Story 05 names the Devourer through the Ruins of Veld omen, Story 06 prepares Dianthus Pollen power, and Story 07 turns the next Meadow Edge night defense into the Devourer fight.

## Current Design Contract

| Field | Current value |
| --- | --- |
| Base HP | 1200 |
| Base damage | 50 |
| Phase thresholds | Phase 2 at 70% HP, Phase 3 at 30% HP |
| Low-HP surge threshold | 15% HP |
| Weakness | Equipped weapon data with `is_pollen_weapon = true` applies 1.5x damage |
| Arena | Meadow Edge night defense surface |
| Trigger | Active `story_07_devourer` quest changes WaveSpawner forecast into a boss fight |
| Quest completion event | `devourer_defeated` |

## Implemented Files

| Path | Purpose |
| --- | --- |
| `enemies/devourer/the_devourer.gd` | Boss script, phase tracking, pollen multiplier, death/quest reporting |
| `enemies/devourer/the_devourer.tscn` | Boss scene |
| `enemies/devourer/states/devourer_idle.gd` | Idle/activation entry |
| `enemies/devourer/states/devourer_phase1.gd` | Phase 1 movement, Void Slam, Shadowling summons |
| `enemies/devourer/states/devourer_phase2.gd` | Phase 2 behavior and mixed minion pressure |
| `enemies/devourer/states/devourer_phase3.gd` | Phase 3 pressure, low-HP surge behavior |
| `enemies/devourer/devourer_dark_pulse.gd` | Boss projectile behavior |
| `enemies/spawner/wave_spawner.gd` | Boss forecast, spawn, death tracking, music start/stop |
| `combat/weapons/weapon_data.gd` | `is_pollen_weapon` flag |

## Fight Flow

1. `QuestManager` starts or advances to `story_07_devourer`.
2. `WaveSpawner` regenerates its forecast.
3. If `story_07_devourer` is active, the forecast becomes a Devourer boss forecast.
4. At night, Meadow Edge starts `_start_devourer_fight()` instead of a normal wave.
5. `WaveSpawner` spawns `TheDevourer`, applies difficulty tier multipliers, starts boss music, emits `boss_spawned`, and tracks the boss as the current wave.
6. The Devourer changes phase at 70% and 30% HP.
7. Devourer death reports `devourer_defeated`, kills remaining registered minions, emits enemy death, and lets `WaveSpawner` clear the wave.
8. The story/ending managers resolve the result through normal quest and ending flags.

## Pollen Weakness

The boss does not inspect recipe text. It checks the player's selected weapon slot, loads the `WeaponData`, and applies `POLLEN_DAMAGE_MULTIPLIER` when `is_pollen_weapon` is true.

Design implication: any future weapon intended to wound the Devourer directly should use the existing `WeaponData.is_pollen_weapon` flag rather than a new boss-specific exception.

## Current Caveats

- The Devourer fight belongs to Meadow Edge only.
- Regular Surge Night is still deferred under `DIFF-02`; do not describe it as fully shipped.
- Night 21 escalation remains `DIFF-03` and does not introduce a named boss.
- Full weapon VFX polish is still deferred under `VFX-05`.
- Older prompt files may still describe the boss as unimplemented; this guide and `TASK_BREAKDOWN.md` are the current design references.
