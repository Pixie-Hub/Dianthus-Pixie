# Plant Codex — Dianthus Pixie
**Document Type:** Game Design Reference  
**Version:** 1.0  
**Last Updated:** 2026-05-04  
**Scope:** All 11 currently implemented plants — 7 base + 4 hybrids.

---

## Overview

Plants are the backbone of the garden-defense loop. Placed on a 16×16 px grid during the
Daytime phase (max 8 active), they provide passive combat, support, and survival effects
that persist through the night wave. Each plant has a **vitality** stat (0–100 %) that decays
overnight and can be restored via tending.

All plants require a **seed** to place. Seeds are consumed on placement. Base plant seeds
are found in the world; hybrid seeds are created at the **Breeding Bench** by combining
two parent extracts.

---

## How Seeds Work

| Term | Meaning |
|------|---------|
| **Seed** | Single-use item; consumed when the plant is placed on the garden grid. |
| **Extract** | Crafting material harvested from a living plant; used in hybrid breeding. |
| **Rarity** | Determines stack limit — Common (99), Uncommon (20), Rare (5). |
| **Vitality** | 0–100 %; overnight decay is 15 % (Easy), 20 % (Normal), 25 % (Hard). Wilted plants (0 %) disable all effects until tended. |
| **Tending** | Hold **E** near a plant for 2.5 s; costs 1 Petal Shard; restores 50 % vitality. |

---

## Base Plants

### 1. Bougainvillea

| Attribute | Value |
|-----------|-------|
| **Full Name** | Bougainvillea (Bougainvillea spectabilis) |
| **Role** | Offensive |
| **Seed ID** | `bougainvillea_seed` |
| **Seed Rarity** | Common (stack 99) |
| **Plant HP** | 30 |
| **Effect Radius** | 24 px |
| **Effect** | Passive aura: deals **5 DMG per tick** (1-second interval) to every enemy inside the radius. |
| **Weakness** | Small radius; only effective if enemies route through it. Wilts quickly on Hard. |

**Acquisition — Bougainvillea Seed**
- **Tutorial Gift:** Player gets 1 seed on Day 3 (tutorial handout).
- **Meadow Edge Pickup:** 1–2 seeds placed as ground pickups near the safe main path (accessible Day 1).
- **Shadowling Drop:** 20 % chance on death (Day 1+). This is the primary renewable source.
- **Wild Seedling Event:** Guaranteed reward if Bougainvillea is the "least recently discovered" base plant.
- **Night Survived Reward:** 1 seed on Days 1–3 (alongside Petal Shard payout).

> **Design Note:** Bougainvillea should feel free and plentiful. It is the player's first plant and must be obtainable without any prior knowledge of the world. Shadowling drops ensure the player passively restocks it while defending.

---

### 2. Rafflesia

| Attribute | Value |
|-----------|-------|
| **Full Name** | Rafflesia (Rafflesia arnoldii) |
| **Role** | Defensive |
| **Seed ID** | `rafflesia_seed` |
| **Seed Rarity** | Uncommon (stack 20) |
| **Plant HP** | 40 |
| **Effect Radius** | 40 px |
| **Effect** | Applies a **0.6× speed multiplier** to every enemy entering the radius. Slow persists as long as the enemy stays in range; recalculates cleanly when multiple Rafflesias overlap. |
| **Weakness** | Deals no damage; relies on player or other plants to capitalise on the slow. |

**Acquisition — Rafflesia Seed**
- **Meadow Edge Side Pocket:** 1 seed hidden in the Petal Field side-path, reachable safely on Day 1 but off the critical path.
- **Voidrunner Drop:** 15 % chance on death (Day 2+). Encourages players to push deeper at night without relying solely on daytime scavenging.
- **Wild Seedling Event:** Priority reward if Rafflesia has not yet been discovered.
- **Sap Grove Resource Node:** Spawns as an uncommon pickup in the Sap Grove arm of Meadow Edge.

> **Design Note:** One Rafflesia significantly changes enemy routing. Making it findable on Day 1 (but requiring a small detour) rewards exploration without gatekeeping the defensive layer.

---

### 3. Melati

| Attribute | Value |
|-----------|-------|
| **Full Name** | Melati (Jasminum sambac) |
| **Role** | Support |
| **Seed ID** | `melati_seed` |
| **Seed Rarity** | Uncommon (stack 20) |
| **Plant HP** | 25 |
| **Effect Radius** | 32 px |
| **Effect** | Continuously restores **+3 Energy per second** to the player while they remain within the radius. |
| **Weakness** | Player must stay near the plant to receive energy; low HP means it needs protection. |

**Acquisition — Melati Seed**
- **Dusk Forest Zone (WORLD-01):** 1–2 seeds as fixed ground pickups near the forest entrance. Unlocks Day 3.
- **Night Survived Reward:** 1 seed on Day 3–6 (one-time payout per night range to discourage pure farming).
- **Voidrunner Drop:** 10 % chance on death (Day 2+).
- **Wild Seedling Event:** Available if player has not yet placed a Melati.

> **Design Note:** Melati is intentionally locked behind Day 3 to give the player time to learn the base combat loop before adding energy-intensive active skills. It should feel like a meaningful upgrade unlock, not a Day 1 freebie.

---

### 4. Wijaya Kusuma

| Attribute | Value |
|-----------|-------|
| **Full Name** | Wijaya Kusuma (Epiphyllum oxypetalum) |
| **Role** | Offensive (Night-Only) |
| **Seed ID** | `wijaya_kusuma_seed` |
| **Seed Rarity** | Uncommon (stack 20) |
| **Plant HP** | 30 |
| **Effect Radius** | 48 px (detection range for target acquisition) |
| **Effect** | **Night-only:** fires a homing projectile every **1.5 s** at the nearest enemy. Each projectile deals **8 DMG** with 2 s lifetime / 90 px/s speed. Dormant during daytime. |
| **Weakness** | Completely passive during the day; requires night to justify its grid slot. |

**Acquisition — Wijaya Kusuma Seed**
- **Dusk Forest Zone (WORLD-01):** 1 fixed seed near the deep forest landmark. The plant's night-only lore aligns with the dim biome.
- **Phantom Weaver Drop:** 20 % chance on death (Day 6+). Rewards players who tackle harder content.
- **Wild Seedling Event:** Can appear as a reward in Dusk Forest zone events.
- **Old Root Hollow:** 1 seed tucked inside the hollow reward pocket in Meadow Edge (behind a Bramble obstacle).

> **Design Note:** Wijaya Kusuma naturally teaches the "night watch" loop — players who place it during Preparation find a semi-autonomous turret waiting for them at night. Gating it behind Dusk Forest means the player earned the forest access before this power spike appears.

---

### 5. Beringin

| Attribute | Value |
|-----------|-------|
| **Full Name** | Beringin (Ficus benjamina) |
| **Role** | Defensive |
| **Seed ID** | `beringin_seed` |
| **Seed Rarity** | Uncommon (stack 20) |
| **Plant HP** | 50 |
| **Effect Radius** | 32 px |
| **Effect** | On enemy enter, spawns a **root wall** (24×8 px, 60 HP) oriented perpendicular to the intruder. Wall lasts 20 s or until destroyed; 25 s cooldown before next wall. Enemies touching the wall deal their own melee damage to it each second. |
| **Weakness** | Reactive placement — wall only spawns when an enemy enters the radius. If the Beringin is wilted, no new walls spawn. |

**Acquisition — Beringin Seed**
- **Old Root Hollow (Meadow Edge):** 1 seed as the pocket's primary reward, reinforcing the Beringin's "ancient tree" identity.
- **Wild Seedling Event:** High-priority reward in tree-heavy areas.
- **Stonehusk Drop:** 15 % chance on death (Day 4+). Thematically, the armoured enemy carries the resilient tree seed.
- **Quest Reward:** Completing the "Echoes Beneath the Stones" story quest (story_04_ruins) grants 1 Beringin Seed as a side reward.

> **Design Note:** Beringin rewards careful garden layout. Placed at chokepoints it can intercept multiple enemies. Placing it with a Rafflesia behind it creates a classic slow-and-stop combo. The 25 s cooldown prevents spam.

---

### 6. Kecombrang

| Attribute | Value |
|-----------|-------|
| **Full Name** | Kecombrang (Etlingera elatior) |
| **Role** | Support |
| **Seed ID** | `kecombrang_seed` |
| **Seed Rarity** | Rare (stack 5) |
| **Plant HP** | 25 |
| **Effect Radius** | 28 px |
| **Effect** | Grants **+20 % attack speed** to the player while in range. Stacks additive with other Kecombrang plants; recalculates cleanly on exit or wilt. |
| **Weakness** | Small radius — the player must fight close to it to benefit. Low HP; needs guarding. |

**Acquisition — Kecombrang Seed**
- **Void Fissure Event Reward:** One of three possible rare rewards when the Void Fissure 10 s survival challenge is completed successfully. This is the **primary intended route**.
- **Ruins of Veld (WORLD-02):** 1 fixed rare node accessible Day 7+.
- **Stonehusk Drop:** 5 % chance on death (Day 4+). Very low to preserve rarity feel.
- **Kecombrang Extract Node (Dusk Forest):** The zone contains a rare Kecombrang Extract resource node; harvesting it with a Harvest QTE has a 30 % chance to also drop 1 seed.

> **Design Note:** Kecombrang is rare because +20 % attack speed is a noticeable combat power spike. Players should actively seek the Void Fissure event rather than stumbling onto seeds. The extract-to-seed crossover also teaches the "harvest rare plants before they disappear" mechanic.

---

### 7. Kunyit

| Attribute | Value |
|-----------|-------|
| **Full Name** | Kunyit (Curcuma longa) |
| **Role** | Support (Melee-Focused) |
| **Seed ID** | `kunyit_seed` |
| **Seed Rarity** | Rare (stack 5) |
| **Plant HP** | 25 |
| **Effect Radius** | 24 px |
| **Effect** | Grants **+3 bonus melee damage** to all player melee attacks while in range. Multiple Kunyit plants stack additively. |
| **Weakness** | Smallest radius in the game; player must be almost on top of it to benefit. Synergy only with melee weapons (Thorn Sword, Blazeblade, Vine Whip). |

**Acquisition — Kunyit Seed**
- **Void Fissure Event Reward:** Alternate rare drop from the Fissure challenge alongside Kecombrang Seed (mutually exclusive per event instance).
- **Ruins of Veld (WORLD-02):** 1 fixed rare node, placed deeper in the zone than Kecombrang to incentivise full exploration.
- **Quest Reward:** Completing "Petals of Power" (story_06_pollen) grants 1 Kunyit Seed as a bonus alongside the Dianthus Pollen objective.
- **Corrupted Root Event:** Low-tier secret drop (10 % chance) when the root HP is depleted without the player taking damage — skill reward for clean play.

> **Design Note:** Kunyit and Kecombrang are designed as a complementary late-game pair. A player holding the Blazeblade (Thorn Sword upgrade) who stands near both plants deals significantly increased burst damage — but they must sacrifice garden space for pure-player-buff plants, creating a risk/reward loadout decision.

---

## Hybrid Plants

Hybrid seeds are the **output of the Breeding Bench**. To obtain a hybrid seed the player must:
1. Possess the two required **extract** items in their inventory.
2. Open the Breeding Bench (interact with **E**, daytime only).
3. Select the combination in the Cross-Breeding UI.
4. Wait **4 seconds** (real-time, must stay within 48 px of bench).
5. On success, the hybrid seed is added to the inventory; the extracts are consumed.

Hybrid seeds carry the same one-use-per-plant rule as base seeds. To grow the same hybrid
again, the player must breed another one.

---

### 8. Bunga Api

| Attribute | Value |
|-----------|-------|
| **Full Name** | Bunga Api ("Fire Flower") — Hybrid |
| **Role** | Hybrid — Offensive |
| **Seed ID** | `bunga_api_seed` |
| **Seed Rarity** | Rare (stack 5) — hybrid |
| **Plant HP** | 35 |
| **Effect Radius** | 28 px |
| **Breed Recipe** | `bougainvillea_extract` + `kecombrang_extract` |
| **Effect** | Enhanced thorns deal **7 DMG per tick** (1 s interval) to enemies in radius AND apply a **burn** that deals **+3 DMG/s for 2 s** after the enemy leaves. Burn stacks its timer on re-entry. |
| **Unlock Trigger** | Breed the combo once → combo recorded in BreedingManager; `bunga_api` discovered in Codex. |

**Acquiring the Recipe:**
- The combo is an **educated guess** the game rewards: Bougainvillea (thorn damage) + Kecombrang (fire extract with a spicy, energetic flavour) = fire thorns. Players who understand both parent plants intuitively arrive at this recipe.
- **Discovery Quest** fires when the player first breeds an undiscovered combo, hinting at nearby thematic pairings.
- **Codex Hint (locked entry):** After discovering Bunga Api's existence (e.g., via a Wild Seedling event rewarding a bunga_api_seed), the codex shows "Requires two extracts — one from your first defensive thorns, one from the swift red stalk."

**Extracting Parent Materials:**
- `bougainvillea_extract` — drops from Bougainvillea plants on Harvest QTE (meadow edge), or as uncommon loot from Shadowlings.
- `kecombrang_extract` — found as a rare Meadow Edge resource node; drops from Void Fissure reward.

---

### 9. Bunga Bayang

| Attribute | Value |
|-----------|-------|
| **Full Name** | Bunga Bayang ("Shadow Flower") — Hybrid |
| **Role** | Hybrid — Defensive / Offensive |
| **Seed ID** | `bunga_bayang_seed` |
| **Seed Rarity** | Rare (stack 5) — hybrid |
| **Plant HP** | 40 |
| **Effect Radius** | 36 px |
| **Breed Recipe** | `rafflesia_extract` + `shadow_resin` |
| **Effect** | Applies **0.7× slow** to all enemies in radius (same mechanics as Rafflesia but slightly weaker). Additionally, **night-only:** fires a tracking projectile every **2 s** that deals **4 DMG** per hit (1.5 s lifetime, 80 px/s). The slow and the projectile both operate simultaneously. |
| **Unlock Trigger** | Breed combo once. |

**Acquiring the Recipe:**
- Shadow Resin is found in the Meadow Edge night-area and later Ruins of Veld, thematically linking the shadow-plant to darker zones.
- Players who have Rafflesia already know the slow effect; combining with shadow-touched material implies "dark resonance."

**Extracting Parent Materials:**
- `rafflesia_extract` — uncommon drop from Rafflesia Harvest QTE, or drops from Phantom Weavers (Day 6+).
- `shadow_resin` — uncommon item found in Old Root Hollow side pocket and Dusk Forest; also drops from Shadowlings (5 % chance).

---

### 10. Melati Emas

| Attribute | Value |
|-----------|-------|
| **Full Name** | Melati Emas ("Golden Jasmine") — Hybrid |
| **Role** | Hybrid — Support |
| **Seed ID** | `melati_emas_seed` |
| **Seed Rarity** | Rare (stack 5) — hybrid |
| **Plant HP** | 25 |
| **Effect Radius** | 32 px |
| **Breed Recipe** | `verdant_sap` + `dianthus_pollen` |
| **Effect** | While the player is in range: **+2 HP per second** (continuous healing) AND **+4 Energy per second** (stronger than standalone Melati). Both benefits apply simultaneously. |
| **Unlock Trigger** | Breed combo once. |

**Acquiring the Recipe:**
- Verdant Sap is the garden's "universal lifeblood" — an early common resource. Dianthus Pollen is a rare, precious resource tied to the core flower. This recipe symbolises infusing life-energy directly from the Dianthus Core.
- The combo is strongly hinted by the lore of both ingredients and rewards the player who has explored the story far enough to hold Dianthus Pollen.

**Extracting Parent Materials:**
- `verdant_sap` — common drop throughout Meadow Edge (no QTE needed).
- `dianthus_pollen` — rare; found in the Core Sanctum zone (WORLD-04, story-gated) or as a rare Night Survived reward on Day 20+.

---

### 11. Baja Kuning

| Attribute | Value |
|-----------|-------|
| **Full Name** | Baja Kuning ("Yellow Steel") — Hybrid |
| **Role** | Hybrid — Defensive |
| **Seed ID** | `baja_kuning_seed` |
| **Seed Rarity** | Rare (stack 5) — hybrid |
| **Plant HP** | 50 |
| **Effect Radius** | 28 px |
| **Breed Recipe** | `kunyit_extract` + `shadow_resin` |
| **Effect** | Grants **30 % damage reduction** (applied multiplicatively with other sources) to the player while in radius. This is the highest single-plant defensive benefit in the game. |
| **Planned:** counter-reflect mechanic (TODO: PLANT-12) — when the player perfect-blocks within the plant's radius, a portion of the blocked damage is reflected back to the attacker. |
| **Unlock Trigger** | Breed combo once. |

**Acquiring the Recipe:**
- Kunyit's golden colour and hardening properties combine with shadow resin's crystalline toughness for the "iron bloom" effect.
- Recipe is intentionally late-game: Kunyit Extract is rare, and Shadow Resin is uncommon. This ensures Baja Kuning is a mid-to-late-game comfort upgrade, not an early crutch.

**Extracting Parent Materials:**
- `kunyit_extract` — rare; drops from Kunyit Harvest QTE, and as a rare loot from Stonehusks (Day 4+).
- `shadow_resin` — uncommon; Old Root Hollow, Dusk Forest, Shadowling rare drop.

---

## Acquisition Summary Table

| Plant | Seed Rarity | Primary Route | Secondary Route | Enemy Drop |
|-------|------------|---------------|----------------|------------|
| Bougainvillea | Common | Starting gift / main path pickups | Night Survived Day 1–3 | Shadowling 20 % |
| Rafflesia | Uncommon | Petal Field side pocket | Wild Seedling Event | Voidrunner 15 % |
| Melati | Uncommon | Dusk Forest (Day 3+) | Night Survived Day 3–6 | Voidrunner 10 % |
| Wijaya Kusuma | Uncommon | Dusk Forest deep landmark | Old Root Hollow | Phantom Weaver 20 % |
| Beringin | Uncommon | Old Root Hollow reward | Wild Seedling Event | Stonehusk 15 % |
| Kecombrang | Rare | Void Fissure Event reward | Ruins of Veld (Day 7+) | Stonehusk 5 % |
| Kunyit | Rare | Void Fissure Event reward | Ruins of Veld deep node | Corrupted Root (clean kill) |
| Bunga Api | Rare (hybrid) | Breeding Bench (Bougainvillea Extract + Kecombrang Extract) | — | — |
| Bunga Bayang | Rare (hybrid) | Breeding Bench (Rafflesia Extract + Shadow Resin) | — | — |
| Melati Emas | Rare (hybrid) | Breeding Bench (Verdant Sap + Dianthus Pollen) | — | — |
| Baja Kuning | Rare (hybrid) | Breeding Bench (Kunyit Extract + Shadow Resin) | — | — |

---

## Implementation Status

| Feature | Status | Notes |
|---------|--------|-------|
| All 11 plant scripts + scenes | ✅ Done | `plants/entities/*.gd` + `.tscn` |
| Seed items in ItemDatabase | ✅ Done | All 11 seeds registered |
| Plant placement (grid, palette) | ✅ Done | `plant_placement_manager.gd` |
| Vitality / tending | ✅ Done | `plant_base.gd` |
| Hybrid breeding via bench | ✅ Done | `breeding_manager.gd` |
| Plant Codex UI | ✅ Done | `codex_screen.gd` |
| Enemy seed drops | ✅ Done | `_get_seed_drop_table()` virtual in `enemy_base.gd`; Shadowling 20% bougie, Voidrunner 15%/10% rafflesia/melati, Stonehusk 15%/5% beringin/kecombrang, Phantom Weaver 20% wijaya_kusuma |
| Wild Seedling Event seed selection | ✅ Done | Day-gated priority: Day 1+ common/rafflesia, Day 3+ mid-tier, Day 7+ rare; undiscovered seeds prioritised |
| Dusk Forest zone seed pickups | ✅ Done | `dusk_forest.gd` DAYTIME_RESOURCE_RULES; melati_seed×1–2 + wijaya_kusuma_seed×1 guaranteed Day 3+; rafflesia_seed/moonspore/shadow_resin/kecombrang_extract also present |
| Ruins of Veld rare seed nodes | ✅ Done | `ruins_of_veld.gd` DAYTIME_RESOURCE_RULES; kecombrang_seed×1 + kunyit_seed×1 guaranteed Day 7+; kunyit_seed placed deeper to incentivise exploration |
| Void Fissure seed reward selection | ✅ Done | Prefers undiscovered kecombrang_seed/kunyit_seed; falls back to rare materials when both discovered |
| Corrupted Root clean-kill seed drop | ✅ Done | `kunyit_seed` given if player took 0 hits during fight and kunyit not yet discovered |

---

## Design Principles Applied

1. **Every seed has at least two acquisition paths** — no single point of failure blocks a plant.
2. **Rarity is risk-weighted** — Common seeds flow from safe play; Rare seeds require entering dangerous zones or completing skill events.
3. **Thematic coherence** — each enemy's seed drop reflects the plant's cultural or mechanical identity (e.g., the aggressive Shadowling carries the thorn plant's seed).
4. **Hybrid recipes are discoverable through play** — a player who knows both parent plants can reason their way to the recipe without looking it up.
5. **Progression gates are soft** — no plant is exclusively locked behind a single quest; zone-locked seeds always have an alternative drop route that becomes available at the same day range.
