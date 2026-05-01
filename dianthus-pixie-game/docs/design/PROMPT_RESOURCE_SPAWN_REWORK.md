# Prompt: Rework Daytime Resource Spawning — Rarity-Based Probability & Zone Assignment

## Task ID
**RES-01** (Resource Scarcity Scaling) — partially addresses this task's acceptance criteria.

## Objective

Rework the daytime resource pickup spawning system in `world/zones/meadow_edge/meadow_edge.gd` so that:

1. **Spawn probability is derived from item rarity** — the `ItemDatabase.Rarity` enum (`COMMON`, `UNCOMMON`, `RARE`) drives each material's base chance of appearing on any given day.
2. **Each material has a designated spawn zone** — materials are tied to specific named sub-areas of the Meadow Edge map.
3. **Day 1 is guaranteed** — exactly 3 Petal Shards and 2 Verdant Sap always spawn on Day 1, regardless of probability rolls.

---

## Current State

### Spawning System (`meadow_edge.gd`)

The existing `_spawn_daytime_resources()` system uses a `DAYTIME_RESOURCE_RULES` array. Each rule is a Dictionary:
```
{
    prefix, item_id, amount, spawn_chance, day_one_count (optional), minimum_count, positions[]
}
```
- A seeded `RandomNumberGenerator` (seed = `RESOURCE_RNG_SEED_BASE + day_count * RESOURCE_RNG_DAY_STEP`) rolls per position.
- `day_one_count` forces a fixed count on Day 1; `minimum_count` guarantees a minimum on other days.
- Positions are shuffled, then iterated — guaranteed slots fill first, then extra slots are rolled against `spawn_chance`.
- Pickups are cleared and re-spawned each DAY phase via `_on_phase_changed`.

### Currently Spawned Materials

| Material | Rarity | Zone | Positions | Chance | Day 1 | Min |
|----------|--------|------|-----------|--------|-------|-----|
| petal_shard | COMMON | Petal Field | 5 | 72% | 3 | 2 |
| verdant_sap | COMMON | Sap Grove | 3 | 68% | 2 | 1 |
| bougainvillea_extract | UNCOMMON | Sap Grove | 2 | 55% | — | 0 |
| beringin_root | UNCOMMON | Old Root Hollow | 2 | 50% | — | 0 |
| aether_bloom | RARE | Ruin Glimmer | 3 | 35% | — | 1 |

### Materials NOT Yet Spawned in the World

These exist in `ItemDatabase` but have no pickup spawn points:

| Material | Rarity | Intended Zone |
|----------|--------|---------------|
| moonspore | UNCOMMON | Old Root Hollow or Sap Grove (nocturnal theme) |
| shadow_resin | UNCOMMON | Ruin Glimmer or Old Root Hollow (dark theme) |
| rafflesia_extract | UNCOMMON | Petal Field side pocket (near thicket) |
| kecombrang_extract | RARE | Sap Grove deep pocket (behind fallen tree) |
| kunyit_extract | RARE | Old Root Hollow (behind bramble gate) |
| dianthus_pollen | RARE | Garden Gate area (near Core, very rare) |

### Map Sub-Areas (from `DAYTIME_PHASE_OVERHAUL_PLAN.md` and scene visuals)

| Zone Name | Approximate Center | Tile Coords | Character |
|-----------|--------------------|-------------|-----------|
| **Garden Gate** | (768, 842) | Central, near Core | Safe starting area |
| **Petal Field** | (356, 596) | West of Garden Gate | Open, safe, pink flower ring |
| **Sap Grove** | (1160, 570) | East of Garden Gate | Dense trees, fallen log, pond |
| **Old Root Hollow** | (720, 340) | North-center | Obstacle-heavy, glowing root |
| **Ruin Glimmer** | (760, 210) | Far north | Story/discovery corner, stone arch |
| **South Return Pocket** | (1030, 800) | Southeast | Quick return loop area |

### Item Rarity Tiers (from `ItemDatabase`)

| Rarity | Enum Value | Max Stack | Existing Items |
|--------|-----------|-----------|----------------|
| COMMON | 0 | 99 | petal_shard, verdant_sap, bougainvillea_seed |
| UNCOMMON | 1 | 20 | moonspore, shadow_resin, bougainvillea_extract, rafflesia_extract, beringin_root, rafflesia_seed, melati_seed, wijaya_kusuma_seed, beringin_seed |
| RARE | 2 | 5 | aether_bloom, dianthus_pollen, kecombrang_extract, kunyit_extract, kecombrang_seed, kunyit_seed, all hybrid seeds |

---

## Design Specification

### 1. Rarity-Based Spawn Probability

Replace the current per-rule `spawn_chance` values with a rarity-driven base probability system. Define constants in `meadow_edge.gd`:

```
RARITY_SPAWN_CHANCE = {
    ItemDatabase.Rarity.COMMON:   0.80,
    ItemDatabase.Rarity.UNCOMMON: 0.45,
    ItemDatabase.Rarity.RARE:     0.20,
}
```

Each material rule should **no longer** have a hardcoded `spawn_chance`. Instead, `_spawn_resource_rule()` should look up the rarity from `ItemDatabase.get_rarity(item_id)` and use the corresponding `RARITY_SPAWN_CHANCE` value.

**Scarcity scaling (optional, for RES-01 completeness):** Every 5 days, reduce UNCOMMON and RARE base chances by a small multiplier. Suggested formula:

```
effective_chance = base_chance * pow(0.92, floor((day_count - 1) / 5))
```

This means:
- Day 1–5: full base chance
- Day 6–10: ×0.92
- Day 11–15: ×0.846
- Day 16–20: ×0.778
- etc.

COMMON materials should **not** scale down (they remain accessible throughout per GDD §6.3).

### 2. Zone-Material Assignment

Expand `DAYTIME_RESOURCE_RULES` to include **all** world-spawnable materials. Each material is assigned to exactly one zone, with spawn positions placed at meaningful locations within that zone.

**Complete spawn table:**

| Material | Rarity | Zone | Positions | Amount | Min Count | Day 1 Count |
|----------|--------|------|-----------|--------|-----------|-------------|
| petal_shard | COMMON | Petal Field | 5 | 1 | 2 | 3 |
| verdant_sap | COMMON | Sap Grove | 4 | 1 | 1 | 2 |
| moonspore | UNCOMMON | Old Root Hollow | 3 | 1 | 0 | — |
| shadow_resin | UNCOMMON | Ruin Glimmer | 2 | 1 | 0 | — |
| bougainvillea_extract | UNCOMMON | Petal Field | 2 | 1 | 0 | — |
| rafflesia_extract | UNCOMMON | Sap Grove | 2 | 1 | 0 | — |
| beringin_root | UNCOMMON | Old Root Hollow | 2 | 1 | 0 | — |
| aether_bloom | RARE | Ruin Glimmer | 2 | 1 | 0 | — |
| dianthus_pollen | RARE | Garden Gate | 1 | 1 | 0 | — |
| kecombrang_extract | RARE | Sap Grove | 1 | 1 | 0 | — |
| kunyit_extract | RARE | Old Root Hollow | 1 | 1 | 0 | — |

**Position placement guidelines:**
- COMMON materials: near main paths, easy to reach.
- UNCOMMON materials: at side-pocket ends or behind obstacles, requiring detours.
- RARE materials: farthest from Garden Gate, or in the hardest-to-reach corners of their zone. The lone `dianthus_pollen` near the Core should be a special "sacred bloom" spot.
- Positions should not overlap with existing bramble patches, scout tracks, or the breeding bench.

### 3. Day 1 Guarantee

On Day 1:
- **Exactly 3 Petal Shards** spawn (no more from random rolls, no less).
- **Exactly 2 Verdant Sap** spawn (no more from random rolls, no less).
- **All other materials skip random rolls** — they do not spawn on Day 1. Only the two guaranteed COMMON materials appear, keeping Day 1 simple for the tutorial flow.

Implementation: when `DayNightCycle.day_count == 1`, only rules with a `day_one_count` key are processed. Rules without `day_one_count` are skipped entirely. The existing `can_roll_extra` logic already suppresses extra rolls when `day_one_count` is present; extend it so rules without `day_one_count` spawn nothing on Day 1.

### 4. Night Reward Note

The `night_survived_screen.gd` post-night rewards (3–5 Petal Shards + 1 Verdant Sap) are a separate system and should **not** change. Those are wave-clear rewards, not daytime spawns.

---

## Files to Modify

1. **`world/zones/meadow_edge/meadow_edge.gd`** — Main changes:
   - Add `RARITY_SPAWN_CHANCE` constant dict.
   - Replace the `DAYTIME_RESOURCE_RULES` array with the expanded 11-material table.
   - Add new spawn `positions` for the 6 missing materials (moonspore, shadow_resin, rafflesia_extract, kecombrang_extract, kunyit_extract, dianthus_pollen).
   - Modify `_spawn_resource_rule()` to derive spawn chance from `ItemDatabase.get_rarity()` instead of `rule.get("spawn_chance")`.
   - Add optional scarcity scaling multiplier based on `day_count`.
   - On Day 1, skip rules that lack `day_one_count`.

2. **`docs/design/TASK_BREAKDOWN.md`** — Update RES-01 status if the scarcity scaling formula is included; otherwise add a note that RES-01 is partially addressed.

## Files NOT to Modify

- `inventory/data/item_database.gd` — No changes needed; rarity data is already correct.
- `inventory/pickups/resource_pickup.gd` — No changes needed; it already reads rarity for Harvest QTE and visual color.
- `ui/screens/night_survived_screen.gd` — Night rewards are a separate system; do not touch.
- Scene files (`.tscn`) — Pickups are spawned dynamically from `meadow_edge.gd`; no scene edits required.

---

## Acceptance Criteria

1. On Day 1, exactly 3 Petal Shards and 2 Verdant Sap appear in the world. No other materials spawn.
2. On Day 2+, all 11 materials can potentially spawn, each at their designated zone positions.
3. COMMON materials spawn at ~80% per position, UNCOMMON at ~45%, RARE at ~20%.
4. No material spawns outside its assigned zone.
5. The seeded RNG produces identical resource layouts for the same day count across runs.
6. Existing systems (Harvest QTE on UNCOMMON/RARE pickups, tutorial hints, pickup SFX) continue to work unchanged.
7. (Optional) Scarcity scaling: UNCOMMON/RARE spawn rates decrease by ~8% every 5 days; COMMON stays constant.

---

## Debug Verification

- **F13** (existing): adds materials directly to inventory — unaffected by this change.
- **Shift+9** (existing): sets day timer to 35s — use to quickly cycle through days and verify spawn variation.
- Visually confirm: walk through Petal Field, Sap Grove, Old Root Hollow, Ruin Glimmer, and Garden Gate each day to see correct zone-material mapping.
- Day 1 test: start a new game, verify exactly 3 Petal Shards + 2 Verdant Sap, zero other pickups.
- Day 10+ test: verify that UNCOMMON/RARE pickups appear less frequently than on Day 2.

---

## Suggested Spawn Positions for New Materials

These are approximate pixel coordinates within each zone. Adjust if they overlap collision or visual features.

### Moonspore — Old Root Hollow (nocturnal spore, dim area)
- `Vector2(680, 300)` — near the glowing root bridge
- `Vector2(760, 380)` — deeper into the hollow
- `Vector2(840, 310)` — east wall of Old Root

### Shadow Resin — Ruin Glimmer (dark residue near ruins)
- `Vector2(700, 192)` — between the stone pillars
- `Vector2(820, 192)` — east pillar shadow

### Rafflesia Extract — Petal Field side pocket (west thicket edge)
- `Vector2(300, 548)` — near the side pocket path
- `Vector2(380, 480)` — deeper in the petal side pocket

### Kecombrang Extract — Sap Grove deep (behind fallen tree)
- `Vector2(1280, 440)` — past the fallen tree barrier

### Kunyit Extract — Old Root Hollow (behind obstacles)
- `Vector2(640, 280)` — west side, near the wall

### Dianthus Pollen — Garden Gate (rare sacred bloom near Core)
- `Vector2(800, 880)` — southeast of the Core clearing
