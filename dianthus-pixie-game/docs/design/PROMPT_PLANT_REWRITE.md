# PLANT-REWRITE — Real-World Plant Catalogue Overhaul

**Project:** Dianthus Pixie
**Engine:** Godot 4.6 (GDScript)
**Effort:** L (2–3 days)
**Priority:** High
**Dependencies:** PLANT-01 (Thornvine & Gloomshroom — Done)
**Downstream dependents:** Plant Placement, Cross-Breeding system, Crafting Recipes, Weapon Upgrades

---

## 1. Objective

Rewrite the entire Plant Catalogue (GDD §7.1) to use **real-world plant species**, with a strong emphasis on **Indonesian flora**. Cross-bred hybrids may remain fantastical but should feel grounded in the botanical origins of their parent plants.

This task involves:

1. **Renaming & reflavoring** all 8 base plants to match real-world counterparts.
2. **Updating scripts, scenes, class names, and groups** for the 2 already-implemented plants (Thornvine → Bougainvillea, Gloomshroom → Rafflesia).
3. **Updating the GDD** (§7.1, §7.2, §7.3) to reflect the new names and lore.
4. **Updating all references** across the codebase — debug keys, player_controller, weapon recipes, save data, etc.
5. **Leaving `TODO: <TASK-ID>` stubs** for plants not yet implemented.

---

## 2. New Plant Catalogue

### Design Principles

- Each base plant maps to a **real species** found in or strongly associated with Indonesia.
- Game names use the **common/Indonesian name** — whichever fits the fantasy setting better.
- Gameplay roles (Offensive / Defensive / Support / Hybrid) remain unchanged.
- Stats remain unchanged — only names, lore, visual directions, and group names change.

---

### 2a. Dianthus (KEEP AS-IS)

| Field | Value |
|-------|-------|
| **Real species** | *Dianthus caryophyllus* (Carnation family) |
| **Game name** | **Dianthus** |
| **Role** | Hybrid (Core) |
| **Effect** | Source of life energy; emits a protective aura around the garden |
| **Lore** | A rare, luminous carnation that pulses with life energy. Its glow attracts creatures of darkness — but also holds the key to repelling them. |
| **Unlock** | Available from start |
| **Notes** | No code changes. Already a real genus. The game is named after it. |

---

### 2b. Thornvine → Bougainvillea

| Field | Value |
|-------|-------|
| **Real species** | *Bougainvillea spectabilis* |
| **Game name** | **Bougainvillea** |
| **Indonesian context** | Called *Bunga Kertas* (paper flower). Ubiquitous across Indonesia — fences, walls, gardens. Beautiful bracts but **vicious hidden thorns**. |
| **Role** | Offensive |
| **Effect** | Thorny vine that damages enemies in radius (5 DMG/tick, 1.0s interval, 24px radius) |
| **Lore** | Don't let the paper-thin petals fool you. Beneath Bougainvillea's beauty lies a tangle of razor-sharp thorns that shred anything pushing through. Indonesian gardeners know — respect the vine. |
| **Unlock** | Available from start |
| **Placeholder color** | Magenta-pink `Color(0.85, 0.15, 0.45)` |
| **Stats** | HP: 30, DMG/tick: 5, Tick: 1.0s, Radius: 24px |

**Code changes (already implemented as Thornvine):**
- Rename `class_name Thornvine` → `class_name Bougainvillea`
- Rename files: `thornvine.gd` → `bougainvillea.gd`, `thornvine.tscn` → `bougainvillea.tscn`
- Group: `"thornvines"` → `"bougainvilleas"`
- Update preload paths in `player_controller.gd` (F10 debug cycle)
- Update any references in crafting recipes, PERSON_TASKS.md, save data

---

### 2c. Gloomshroom → Rafflesia

| Field | Value |
|-------|-------|
| **Real species** | *Rafflesia arnoldii* |
| **Game name** | **Rafflesia** |
| **Indonesian context** | World's largest flower, **endemic to Sumatra and Borneo**. Famous for its corpse-like stench. A national icon of Indonesian biodiversity. |
| **Role** | Defensive |
| **Effect** | Emits a foul miasma that slows enemies in radius (0.6× speed, 40px radius) |
| **Lore** | The stench of a blooming Rafflesia is legendary — a wave of rotting sweetness so thick it chokes the air. Shadow creatures that stumble into its miasma find their limbs heavy and their advance grinding to a halt. |
| **Unlock** | Day 2, forage |
| **Placeholder color** | Deep red-brown `Color(0.65, 0.12, 0.15)` |
| **Stats** | HP: 40, Slow: 0.6×, Radius: 40px |

**Code changes (already implemented as Gloomshroom):**
- Rename `class_name Gloomshroom` → `class_name Rafflesia`
- Rename files: `gloomshroom.gd` → `rafflesia.gd`, `gloomshroom.tscn` → `rafflesia.tscn`
- Group: `"gloomshrooms"` → `"rafflesias"`
- Update `_recalculate_slow()` to check group `"rafflesias"` and cast to `Rafflesia`
- Update preload paths in `player_controller.gd` (F10 debug cycle)

---

### 2d. Sunpetal → Melati (Jasmine)

| Field | Value |
|-------|-------|
| **Real species** | *Jasminum sambac* |
| **Game name** | **Melati** |
| **Indonesian context** | Indonesia's **national flower** (*Puspa Bangsa*). Symbolizes purity, grace, sincerity. Used in ceremonies, weddings, and traditional medicine across Java and Bali. |
| **Role** | Support |
| **Effect** | Passively regenerates the player's energy nearby (+3 energy/sec, 32px radius) |
| **Lore** | The fragrance of Melati has soothed Indonesian hearts for centuries. In the garden, its calming scent restores the alchemist's vitality — a gentle reminder that not all power comes through violence. |
| **Unlock** | Day 3, quest reward |
| **Placeholder color** | Soft white-cream `Color(0.95, 0.95, 0.85)` |
| **Stats** | HP: 25, Energy regen: 3/sec, Radius: 32px |
| **Group** | `"plants"`, `"melatis"` |
| **Status** | `TODO: PLANT-02` — Not yet implemented |

---

### 2e. Nightbloom → Wijaya Kusuma (Queen of the Night)

| Field | Value |
|-------|-------|
| **Real species** | *Epiphyllum oxypetalum* |
| **Game name** | **Wijaya Kusuma** |
| **Indonesian context** | Sacred in Javanese culture. Blooms only once at night and wilts by dawn. Finding one in bloom is an omen of great fortune — or great danger. Associated with Javanese royalty and mystical power. |
| **Role** | Offensive |
| **Effect** | Auto-attacks enemies within radius at night only. Fires spectral petal projectiles (8 DMG, 1.5s interval, 48px radius). Dormant during daytime. |
| **Lore** | Wijaya Kusuma opens its pale petals only under moonlight. When darkness descends and the garden is besieged, it awakens — launching spectral petals at any shadow creature that dares approach. By dawn, it sleeps again, as if nothing happened. |
| **Unlock** | Day 4, breeding |
| **Placeholder color** | Pale moonlit white `Color(0.9, 0.85, 1.0)` |
| **Stats** | HP: 35, DMG: 8/projectile, Fire rate: 1.5s, Radius: 48px |
| **Group** | `"plants"`, `"wijaya_kusumas"` |
| **Status** | `TODO: PLANT-03` — Not yet implemented |

---

### 2f. Mosswarden → Beringin (Banyan)

| Field | Value |
|-------|-------|
| **Real species** | *Ficus benjamina* |
| **Game name** | **Beringin** |
| **Indonesian context** | Indonesia's **national tree** featured on the Pancasila coat of arms. Its aerial roots form dense, wall-like structures. Culturally associated with protection and community shelter. Village gathering spots (alun-alun) traditionally center around a Beringin tree. |
| **Role** | Defensive |
| **Effect** | Grows a temporary living root-wall (3×1 tile barrier) that blocks enemy pathing for 20 seconds. Enemies must attack through it (Wall HP: 60). |
| **Lore** | The Beringin's roots descend from above like curtains of living wood. When planted in the garden's path, its roots weave into an impassable wall — buying the alchemist precious seconds against the tide of shadow. |
| **Unlock** | Day 5, craft |
| **Placeholder color** | Bark brown-green `Color(0.35, 0.45, 0.25)` |
| **Stats** | HP: 35 (plant), Wall HP: 60, Wall duration: 20s, Wall size: 3×1 tiles |
| **Group** | `"plants"`, `"beringins"` |
| **Status** | `TODO: PLANT-04` — Not yet implemented |

---

### 2g. Emberfern → Kecombrang (Torch Ginger)

| Field | Value |
|-------|-------|
| **Real species** | *Etlingera elatior* |
| **Game name** | **Kecombrang** |
| **Indonesian context** | Known as *Honje* or *Torch Ginger*. Native to Southeast Asia. The bright red/pink inflorescence resembles a **flaming torch**. Widely used in Sumatran and Sundanese cuisine (sambal, sayur asam). A plant that is both beautiful and functional — just like its in-game role. |
| **Role** | Support |
| **Effect** | When activated (costs energy), boosts player attack speed +20% for 15 seconds within radius |
| **Lore** | The Kecombrang burns with an inner fire that never goes out. Stand near its torch-like bloom and feel your blood quicken, your strikes sharpen. Sumatran warriors once carried its petals into battle for courage. |
| **Unlock** | Day 7, rare forage |
| **Placeholder color** | Torch red-orange `Color(0.9, 0.3, 0.15)` |
| **Stats** | HP: 20, Attack speed buff: +20%, Buff duration: 15s, Radius: 28px, Activation cost: 25 energy |
| **Group** | `"plants"`, `"kecombrangs"` |
| **Status** | `TODO: PLANT-05` — Not yet implemented |

---

### 2h. Crystalroot → Kunyit (Turmeric)

| Field | Value |
|-------|-------|
| **Real species** | *Curcuma longa* |
| **Game name** | **Kunyit** |
| **Indonesian context** | Fundamental to Indonesian culture — used in *jamu* (traditional herbal medicine), cooking, and dyeing. The golden-yellow rhizome is believed to have protective and strengthening properties. In Javanese tradition, turmeric paste (*lulur*) is applied before weddings to fortify the body and spirit. |
| **Role** | Hybrid |
| **Effect** | Strengthens melee weapons — adds +3 bonus damage and armor penetration to player attacks while in radius |
| **Lore** | Kunyit's golden root runs deep, carrying the concentrated essence of the earth. Alchemists who coat their blades in its extract find their strikes heavier, cutting through shadow-hide as if it were paper. The old jamu makers always said: Kunyit strengthens what is weak. |
| **Unlock** | Discovery Quest |
| **Placeholder color** | Golden yellow `Color(0.9, 0.7, 0.1)` |
| **Stats** | HP: 30, Bonus melee DMG: +3, Armor penetration: true, Radius: 24px |
| **Group** | `"plants"`, `"kunyits"` |
| **Status** | `TODO: PLANT-06` — Not yet implemented |

---

## 3. Cross-Breeding Combinations (Updated)

Cross-bred plants are **fantasy hybrids** but their names and effects are inspired by their parent species. Indonesian-flavored naming where possible.

| **Plant A** | **Plant B** | **Hybrid Result** | **Effect** | **Inspiration** |
|-------------|-------------|-------------------|------------|-----------------|
| Bougainvillea | Kecombrang | **Bunga Api** (Fire Flower) | Thorns + fire AoE — damages enemies with burning thorn burst (7 DMG/tick + 3 burn DMG over 2s) | Thorny vine meets torch ginger = flaming thorns. *Bunga Api* is Indonesian for "fire flower" / "fireworks". |
| Rafflesia | Wijaya Kusuma | **Bunga Bayang** (Shadow Bloom) | Slow + night auto-attack in area — creates a zone of miasma that both slows and fires dark projectiles at night (4 DMG, 0.7× slow) | Corpse flower stench meets moonlit night-bloom = a shadow zone that attacks. |
| Melati | Dianthus Pollen | **Melati Emas** (Golden Jasmine) | Regenerates both HP (+2/sec) and energy (+4/sec) to the player in radius — the ultimate support plant | Jasmine purity fused with Dianthus life energy = golden healing aura. |
| Kunyit | Shadow Resin | **Baja Kuning** (Yellow Iron) | Grants player armor buff (+30% damage reduction) + melee counter-attack (reflects 25% DMG taken back to attacker) | Turmeric's hardening properties + shadow essence = living armor. |

### Additional Hybrid Ideas (Future — PLANT-07+)

| **Plant A** | **Plant B** | **Hybrid Result** | **Effect** |
|-------------|-------------|-------------------|------------|
| Beringin | Kunyit | **Akar Baja** (Iron Root) | Indestructible root-wall (double wall HP, 40s duration) |
| Melati | Rafflesia | **Bunga Dualisme** (Duality Bloom) | Heals player while slowing enemies in the same radius — risk/reward positioning |
| Bougainvillea | Wijaya Kusuma | **Duri Malam** (Night Thorn) | Thorns that only activate at night but deal 3× damage |
| Kecombrang | Melati | **Obor Suci** (Sacred Torch) | Buff zone: +20% attack speed AND +2 energy regen simultaneously |

---

## 4. Updated Crafting Recipes

| **Weapon** | **Old Materials** | **New Materials** | **Upgrade Path** |
|------------|-------------------|-------------------|------------------|
| Thorn Sword | 3× Petal Shard + 2× Thornvine extract | 3× Petal Shard + 2× **Bougainvillea** extract | Thorn Sword → Blazeblade (+ **Kecombrang**) |
| Spore Bomb | 2× Moonspore + 1× Gloomshroom | 2× Moonspore + 1× **Rafflesia** | Spore Bomb → Void Grenade (+ Shadow Resin) |
| Vine Whip | 4× Verdant Sap + 1× Thornvine | 4× Verdant Sap + 1× **Bougainvillea** | Vine Whip → Crystal Lash (+ **Kunyit**) |
| Petal Shield | 5× Petal Shard + 2× Mosswarden | 5× Petal Shard + 2× **Beringin** root | Petal Shield → Iron Bloom Shield (+ Shadow Resin) |

---

## 5. Updated Zone Resources

| **Zone** | **Old Plant Resources** | **New Plant Resources** |
|----------|------------------------|------------------------|
| Meadow Edge (start) | Thornvine | **Bougainvillea**, Petal Shard, Verdant Sap |
| Dusk Forest (Day 3) | Gloomshroom, Nightbloom | **Rafflesia**, **Wijaya Kusuma**, Moonspore |
| Ruins of Veld (Day 7) | Crystalroot | **Kunyit**, Shadow Resin |
| Obsidian Bog (Day 14) | — | Aether Bloom, Void materials |
| Core Sanctum (Final) | — | Dianthus Pollen (unlimited) |

**Melati** (Jasmine) — unlocked via Day 3 quest, not zone-foraged.
**Beringin** (Banyan) — unlocked via crafting recipe at Day 5.
**Kecombrang** (Torch Ginger) — rare forage in any zone after Day 7.

---

## 6. Updated Enemy Weakness Table

| **Enemy** | **Old Weakness** | **New Weakness** |
|-----------|-----------------|-----------------|
| Shadowling | Sunpetal, Emberfern | **Melati**, **Kecombrang** |
| Voidrunner | Slow trap, Gloomshroom | Slow trap, **Rafflesia** |
| Stonehusk | Vine Whip, Crystal Lash | Vine Whip, Crystal Lash (Kunyit-upgraded) |
| Phantom Weaver | Nightbloom, light area | **Wijaya Kusuma**, light area |
| Swarm Larva | AoE weapon (Spore Bomb) | AoE weapon (Spore Bomb / Rafflesia) |
| The Devourer | Dianthus Pollen weapon | Dianthus Pollen weapon |

---

## 7. Code Changes — Detailed Scope

### 7a. File Renames (Bougainvillea)

| Old | New |
|-----|-----|
| `plants/entities/thornvine.gd` | `plants/entities/bougainvillea.gd` |
| `plants/entities/thornvine.gd.uid` | `plants/entities/bougainvillea.gd.uid` |
| `plants/entities/thornvine.tscn` | `plants/entities/bougainvillea.tscn` |

**Inside `bougainvillea.gd`:**
- `class_name Thornvine` → `class_name Bougainvillea`
- `add_to_group(&"thornvines")` → `add_to_group(&"bougainvilleas")`

**Inside `bougainvillea.tscn`:**
- Script path: `res://plants/entities/thornvine.gd` → `res://plants/entities/bougainvillea.gd`
- Node name: keep as `Bougainvillea` or whatever root is named

### 7b. File Renames (Rafflesia)

| Old | New |
|-----|-----|
| `plants/entities/gloomshroom.gd` | `plants/entities/rafflesia.gd` |
| `plants/entities/gloomshroom.gd.uid` | `plants/entities/rafflesia.gd.uid` |
| `plants/entities/gloomshroom.tscn` | `plants/entities/rafflesia.tscn` |

**Inside `rafflesia.gd`:**
- `class_name Gloomshroom` → `class_name Rafflesia`
- `add_to_group(&"gloomshrooms")` → `add_to_group(&"rafflesias")`
- `_recalculate_slow()`: `get_nodes_in_group(&"gloomshrooms")` → `get_nodes_in_group(&"rafflesias")`
- `plant is Gloomshroom` → `plant is Rafflesia`

### 7c. player_controller.gd Updates

- `_debug_plant_cycle` F10: update preload paths and print labels:
  - `"res://plants/entities/thornvine.tscn"` → `"res://plants/entities/bougainvillea.tscn"`
  - `"res://plants/entities/gloomshroom.tscn"` → `"res://plants/entities/rafflesia.tscn"`
  - Print: `"Placed Thornvine"` → `"Placed Bougainvillea"`, `"Placed Gloomshroom"` → `"Placed Rafflesia"`

### 7d. Placeholder Color Updates

Update `modulate` in `.tscn` files:
- Bougainvillea: `Color(0.2, 0.5, 0.1)` → `Color(0.85, 0.15, 0.45)` (magenta-pink)
- Rafflesia: `Color(0.5, 0.25, 0.5)` → `Color(0.65, 0.12, 0.15)` (deep red-brown)

### 7e. References to Update (grep for these)

Search the entire codebase for these strings and update:
- `Thornvine` / `thornvine` / `thornvines`
- `Gloomshroom` / `gloomshroom` / `gloomshrooms`
- All `.tscn` resource paths referencing old filenames
- Save data keys if any (check `save_manager.gd`)
- GDD document (`Dianthus Pixie GDD.md`) — sections 7.1, 7.2, 7.3, 8.1, 10.1

---

## 8. GDD Section Updates (Summary)

### §7.1 Plant Catalogue — Replace table:

| **Plant** | **Role** | **Base Effect** | **Unlock** |
|-----------|----------|----------------|------------|
| Dianthus | Hybrid (Core) | Life energy source, protective aura | Start |
| Bougainvillea | Offensive | Thorn damage to enemies in radius | Start |
| Rafflesia | Defensive | Miasma slows enemies in radius | Day 2, forage |
| Melati | Support | Energy regen aura for player | Day 3, quest |
| Wijaya Kusuma | Offensive | Night-only auto-attack projectiles | Day 4, breeding |
| Beringin | Defensive | Living root-wall barrier | Day 5, craft |
| Kecombrang | Support | Attack speed buff activation | Day 7, rare forage |
| Kunyit | Hybrid | Melee damage + armor penetration buff | Discovery Quest |

### §7.2 Cross-Breeding — Replace combination table:

| **Plant A** | **Plant B** | **Result** |
|-------------|-------------|------------|
| Bougainvillea | Kecombrang | Bunga Api (fire thorn AoE) |
| Rafflesia | Wijaya Kusuma | Bunga Bayang (slow + night auto-attack) |
| Melati | Dianthus Pollen | Melati Emas (HP + energy regen) |
| Kunyit | Shadow Resin | Baja Kuning (armor + counter-attack) |

### §7.3 Crafting — Update material names per Section 4 above.

### §8.1 Enemy Roster — Update weakness column per Section 6 above.

### §10.1 Zones — Update resource lists per Section 5 above.

---

## 9. Acceptance Criteria

1. **Bougainvillea works identically to old Thornvine** — same damage, timing, and radius. Only names, colors, and file paths changed.
2. **Rafflesia works identically to old Gloomshroom** — same slow, radius, and recalculation logic. Only names, colors, and file paths changed.
3. **No orphaned references** — `grep -r "Thornvine\|Gloomshroom\|thornvine\|gloomshroom"` across the project returns zero results (except this prompt file and git history).
4. **F10 debug key** still works — cycles Bougainvillea → Rafflesia → Clear.
5. **Groups are correct** — `"bougainvilleas"` and `"rafflesias"` used everywhere.
6. **GDD is updated** — all sections reflect new plant names.
7. **PERSON_TASKS.md** references updated.
8. **Save compatibility** — if save files reference plant names, handle migration or note breaking change.
9. **Unimplemented plants have stubs** — TODO comments with task IDs (PLANT-02 through PLANT-06) in relevant files.
10. **No regressions** — Player, Core, Day/Night, HUD, Wave Spawner, Shadowling FSM all remain functional.

---

## 10. Plant Naming Quick-Reference

| **Old Name** | **New Name** | **Indonesian Name** | **Real Species** | **Task ID** |
|-------------|-------------|--------------------|--------------------|-------------|
| Dianthus | Dianthus | Dianthus | *Dianthus caryophyllus* | — (done) |
| Thornvine | Bougainvillea | Bunga Kertas | *Bougainvillea spectabilis* | This task |
| Gloomshroom | Rafflesia | Rafflesia | *Rafflesia arnoldii* | This task |
| Sunpetal | Melati | Melati | *Jasminum sambac* | PLANT-02 |
| Nightbloom | Wijaya Kusuma | Wijaya Kusuma | *Epiphyllum oxypetalum* | PLANT-03 |
| Mosswarden | Beringin | Beringin | *Ficus benjamina* | PLANT-04 |
| Emberfern | Kecombrang | Kecombrang / Honje | *Etlingera elatior* | PLANT-05 |
| Crystalroot | Kunyit | Kunyit | *Curcuma longa* | PLANT-06 |

| **Old Hybrid** | **New Hybrid** | **Indonesian Meaning** |
|----------------|---------------|----------------------|
| Blazethorn | Bunga Api | Fire Flower / Fireworks |
| Voidspore | Bunga Bayang | Shadow Bloom |
| Goldendianthus | Melati Emas | Golden Jasmine |
| Ironbloom | Baja Kuning | Yellow Iron |

---

## 11. Important Constraints

- **GDScript only** — no C#, no GDExtension.
- **Rename via git mv** where possible to preserve history.
- **UID files** — delete old `.gd.uid` files; Godot regenerates them on project open.
- **Scene files (.tscn)** — update script paths and resource references inside the text-based `.tscn` format.
- **Match existing code style** — tabs, type hints, `_` prefix for private vars/methods.
- **Do NOT implement unfinished plants** — only rename the two existing ones. Leave TODO stubs for PLANT-02 through PLANT-06.
- **Signals over direct references** — maintain existing patterns.
- **Test after rename** — run the game, press F10, press F5, verify plants still damage/slow enemies correctly.
