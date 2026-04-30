# Tutorial Workflow - Dianthus Pixie

## Overview

Dokumen ini menjelaskan alur tutorial interaktif yang dipandu oleh **Dianthus Core**. Tutorial berlangsung selama 4 hari pertama dalam game, dengan setiap fase mengajarkan mechanics dasar secara bertahap.

---

## Fase Overview

| Fase | Waktu | Durasi | Fokus |
|------|-------|--------|-------|
| **Fase 1** | Pagi Hari Ke-1 | ~3-5 menit | Movement & Exploration |
| **Fase 2** | Langsung setelah Fase 1 | ~3-5 menit | Crafting (Thorn Sword) |
| **Fase 3** | Malam Hari Ke-1 | ~5-7 menit | Combat (Survive Night 1) |
| **Fase 4** | Pagi & Malam Hari Ke-3 | ~5-8 menit | Plant Defense |
| **Fase 5** | Fajar Hari Ke-4 | Penutup | Tutorial Complete |

> **Catatan:** Hari ke-2 dibiarkan bebas untuk eksplorasi mandiri tanpa panduan.

---

## Fase 1: Pagi Hari Ke-1 — Bangun dan Menjelajah

### Trigger
Permainan baru saja dimulai, matahari terbit.

### Dialog dari Dianthus Core

```
[Day 1 Morning - auto-trigger on game start]

Dianthus Core: Wake, little alchemist.
Dianthus Core: The meadow is safe while the sun is high.
Dianthus Core: Safety is something we cultivate before night tests it.

[Movement Callout]
Dianthus Core: Move with [WASD] or arrow keys.
Dianthus Core: Feel the edges of the garden. Gather anything that catches the light.

[Inventory Callout]
Dianthus Core: Open your pack with [I] to check what you have found.

[Objective Prompt]
Dianthus Core: Goal: move around, open the inventory, and collect your first resource.
```

### Mechanics yang Diajarkan

| Input | Action | UI Indicator |
|-------|--------|--------------|
| `W` | Move forward | — |
| `A` | Move left | — |
| `S` | Move backward | — |
| `D` | Move right | — |
| `I` | Open inventory | Inventory panel highlight |

### Progression Rules

1. **Step 1:** Players must move at least 5 seconds using WASD
2. **Step 2:** Players must open inventory (press `I`)
3. **Step 3:** Players must pick up at least one resource
4. **Auto-advance:** Tutorial progresses when all conditions met

### Visual Cues

- **Core glow intensifies** saat tutorial dimulai
- **Floating particles** mengarah ke resource yang bisa dikumpulkan
- **UI highlight** muncul saat inventory dibuka

### Exit Condition
Semua objective selesai

---

## Fase 2: Langsung setelah Fase 1 — Persiapan dan Membuat Senjata

### Trigger
Fase 1 selesai (player telah bergerak, membuka inventory, dan mengumpulkan resource pertama)

### Dialog dari Dianthus Core

```
[Day 1 Afternoon - triggered by time]

Dianthus Core: The sun leans west. This is preparation time.
Dianthus Core: Raw petals and sap are only promises until your hands give them shape.
Dianthus Core: Stand near the Breeding Bench and press [E].

[Breeding Bench Callout]
Dianthus Core: Thorn Sword is enough for tonight.
Dianthus Core: Simple tools can still save a living garden.

[Objective Prompt]
Dianthus Core: Goal: open the crafting bench and craft your first weapon.
```

### Mechanics yang Diajarkan

| Input | Action | UI Indicator |
|-------|--------|--------------|
| `E` | Interact / Open crafting menu | Crafting panel highlight |
| Mouse Click | Select recipe | Recipe glow |
| Craft Button | Execute crafting | Progress bar animation |

### Crafting Recipe Target

| Item | Materials | Purpose |
|------|-----------|---------|
| **Thorn Sword** | 3x Thorn Petal, 2x Plant Sap | First weapon |

### Progression Rules

1. **Step 1:** Players must be within interaction range of Breeding Bench
2. **Step 2:** Players must open crafting menu (press `E`)
3. **Step 3:** Players must select Thorn Sword recipe
4. **Step 4:** Players must confirm crafting

### Visual Cues

- **Breeding Bench glows** dengan pulse animation saat trigger aktif
- **Resource indicators** menunjukkan material yang diperlukan
- **Recipe highlight** pada Thorn Sword

### Exit Condition
Thorn Sword berhasil dibuat

---

## Fase 3: Malam Hari Ke-1 — Ancaman Pertama

### Trigger
Waktu berubah ke malam (sun angle < 15° dari horizon)

### Dialog dari Dianthus Core

```
[Night 1 - triggered by nightfall]

Dianthus Core: The dark has found us.
Dianthus Core: Shadowlings will seek the Core before they understand you.
Dianthus Core: Do not let them touch the heart of the garden.

[Combat Callout]
Dianthus Core: Strike with [SPACE] or the attack button.
Dianthus Core: Stay close enough to protect me, but move before they surround you.

[Defense Rule]
Dianthus Core: If your strength breaks, you will return near me after a breath.
Dianthus Core: If my light breaks, the garden ends.

[Objective Prompt]
Dianthus Core: Goal: hit a shadow creature and survive Night 1.
```

### Mechanics yang Diajarkan

| Input | Action | UI Indicator |
|-------|--------|--------------|
| `SPACE` | Attack | Weapon swing animation |
| Movement | Dodge enemies | — |
| Mouse Click | Alternative attack | — |

### Combat Rules

1. **Player Death:** Respawn near Core (3-second delay)
2. **Core Death:** Game Over - Tutorial Failed
3. **Shadowling Target Priority:** Players first, then Core
4. **Night Duration:** ~5 minutes real-time

### Spawn Configuration

| Wave | Time | Enemy Count | Enemy Type |
|------|------|-------------|------------|
| Wave 1 | 0:00 | 2 | Shadowling Basic |
| Wave 2 | 1:30 | 3 | Shadowling Basic |
| Wave 3 | 3:00 | 4 | Shadowling + 1 Fast |

### Progression Rules

1. **Step 1:** Players must hit at least one Shadowling
2. **Step 2:** Players must survive for 2 minutes
3. **Step 3:** Players must still be alive at morning

### Visual Cues

- **Enemy health bars** muncul saat combat dimulai
- **Core health indicator** highlighted
- **Danger indicators** pada approaching enemies
- **Screen edge pulse** merah saat Core dalam bahaya

### Exit Condition
Morning arrives (5 minutes elapsed) dengan Core masih hidup

---

## Fase 4: Pagi & Malam Hari Ke-3 — Pertahanan Kebun

### Trigger
Masuk pagi hari ke-3 (Day count = 3, Day phase dimulai)

### Catatan
Hari ke-2 adalah **free play day** - pemain bisa eksplorasi tanpa tutorial guidance.

### Dialog dari Dianthus Core

```
[Day 3 Morning - triggered by Day 3 + Day phase]

Dianthus Core: You have survived more than fear.
Dianthus Core: Now learn to make the garden fight beside you.

[Plant Callout]
Dianthus Core: Place a plant with [P] during preparation.
Dianthus Core: Each root, thorn, and bloom changes the shape of the night.

[Plant Types]
Dianthus Core: Bougainvillea wounds enemies that come too close.
Dianthus Core: Rafflesia slows their rush.
Dianthus Core: Melati steadies your energy when you fight nearby.

[Defense Activation]
Dianthus Core: At night, pull enemies through a plant's radius.
Dianthus Core: Its roots will answer when the wave presses hard.

[Objective Prompt]
Dianthus Core: Goal: place a plant, trigger a plant ability at night, and survive through Night 3.
```

### Mechanics yang Diajarkan

| Input | Action | UI Indicator |
|-------|--------|--------------|
| `P` | Enter plant placement mode | Placement grid appears |
| Click | Place plant | Plant spawn animation |
| `R` | Rotate plant | Grid rotation |
| `ESC` | Cancel placement | Mode exit |
| Plant trigger | Activate plant ability | Visual feedback |

### Plant Types untuk Tutorial

| Plant | Effect | Placement Zone |
|-------|--------|----------------|
| **Bougainvillea** | Damage nearby enemies | Mid-range from Core |
| **Rafflesia** | Slow enemies | Chokepoints |
| **Melati** | Heal player | Near player spawn |

### Progression Rules

1. **Step 1:** Players must enter placement mode (press `P`)
2. **Step 2:** Players must place at least one plant
3. **Step 3:** Players must trigger at least one plant ability at night
4. **Step 4:** Players must survive Night 3

### Visual Cues

- **Placement grid** appears with valid/invalid zones
- **Plant radius preview** saat cursor bergerak
- **Plant glow** saat ability aktif
- **Enemy path indicators** menunjukkan plant coverage

### Exit Condition
Morning of Day 4 arrives dengan Core masih hidup

---

## Fase 5: Penutup Tutorial

### Trigger
Morning of Day 4 (time > sunrise on day 4)

### Dialog dari Dianthus Core

```
[Day 4 Morning - triggered by Day 4 sunrise]

Dianthus Core: The garden breathes easier now.
Dianthus Core: You have walked its paths, shaped thorns into tools,
               faced the first shadow, and planted guardians around my heart.

[Lesson Summary]
Dianthus Core: From here, listen to the light in the leaves.
Dianthus Core: Gather in the day, prepare before dusk, and defend when the dark arrives.

[Closing]
Dianthus Core: I will keep glowing as long as you keep choosing to return.

[Signal: Tutorial Complete]
```

### Tutorial Complete Actions

1. **Quest Completion:** `quest_complete:tutorial_complete`
2. **Achievement Unlock:** "Garden's Guardian"
3. **Tutorial System Disable:** No more guided prompts
4. **Free Play Mode:** Player manages garden independently

### Status Akhir

```
Tutorial System: DISABLED
Active Guidance: NONE
Player Mode: AUTONOMOUS

Day 1-3 guidance complete.
Player now manages garden without direct Core guidance.
```

---

## Dialogic Timeline Integration

### File: `dialogic/timelines/access_03_tutorial.dtl`

```
label tutorial_complete (Tutorial Close)
"Dianthus Core": The garden breathes easier now.
"Dianthus Core": You have walked its paths, shaped thorns into tools,
                faced the first shadow, and planted guardians around my heart.
"Dianthus Core": From here, listen to the light in the leaves.
"Dianthus Core": Gather in the day, prepare before dusk, and defend when the dark arrives.
"Dianthus Core": I will keep glowing as long as you keep choosing to return.
[signal arg="quest_complete:tutorial_day3_defense"]
[end_timeline]

label day_1_movement (Day 1 Morning - Movement)
[signal arg="quest_start:tutorial_day1_movement"]
"Dianthus Core": Wake, little alchemist.
"Dianthus Core": The meadow is safe while the sun is high,
                 but safety is something we cultivate before night tests it.
"Dianthus Core": Move with [WASD] or arrow keys. Feel the edges of the garden.
"Dianthus Core": Open your pack with [I] when you want to check what you have found.
"Dianthus Core": Goal: move around, open inventory, collect first resource.
[end_timeline]

label day_1_crafting (Day 1 Afternoon - Crafting)
[signal arg="quest_start:tutorial_day1_crafting"]
"Dianthus Core": The sun leans west. This is preparation time.
"Dianthus Core": Raw petals and sap are only promises until your hands give them shape.
"Dianthus Core": Stand near the Breeding Bench and press [E].
"Dianthus Core": Thorn Sword is enough for tonight. Simple tools can still save a living garden.
"Dianthus Core": Goal: open the crafting bench and craft your first weapon.
[end_timeline]

label night_1_combat (Night 1 - First Defense)
[signal arg="quest_start:tutorial_day1_combat"]
"Dianthus Core": The dark has found us.
"Dianthus Core": Shadowlings will seek the Core before they understand you.
"Dianthus Core": Do not let them touch the heart of the garden.
"Dianthus Core": Strike with [SPACE] or the attack button.
"Dianthus Core": Stay close enough to protect me, but move before they surround you.
"Dianthus Core": If your strength breaks, you will return near me after a breath.
"Dianthus Core": If my light breaks, the garden ends.
"Dianthus Core": Goal: hit a shadow creature and survive Night 1.
[end_timeline]

label day_3_garden_defense (Day 3 Morning - Garden Defense)
[signal arg="quest_start:tutorial_day3_defense"]
"Dianthus Core": You have survived more than fear.
"Dianthus Core": Now learn to make the garden fight beside you.
"Dianthus Core": Place a plant with [P] during preparation.
"Dianthus Core": Each root, thorn, and bloom changes the shape of the night.
"Dianthus Core": Bougainvillea wounds enemies that come too close.
"Dianthus Core": Rafflesia slows their rush. Melati steadies your energy.
"Dianthus Core": At night, pull enemies through a plant's radius.
"Dianthus Core": Its roots will answer when the wave presses hard.
"Dianthus Core": Goal: place a plant, trigger a plant ability at night, survive Night 3.
[end_timeline]
```

---

## State Machine Flow

```
[GAME START]
     │
     ▼
[FASE 1: DAY 1 MORNING]
     │
     ├─ TutorialManager.start("tutorial_movement")
     ├─ Wait: player_move + open_inventory + collect_resource
     │
     ▼
[FASE 2: CRAFTING]
     │
     ├─ Tutorial phase complete → auto-start crafting tutorial
     ├─ TutorialManager.start("tutorial_crafting")
     ├─ Wait: craft_thorn_sword
     │
     ▼
[FREE PLAY: DAY 2]
     │
     ├─ No tutorial guidance
     ├─ Player explores freely
     │
     ▼
[FASE 3: NIGHT 1]
     │
     ├─ Time trigger (nightfall)
     ├─ TutorialManager.start("tutorial_combat")
     ├─ Spawn waves 1-3
     ├─ Wait: hit_enemy + survive_5min
     │
     ▼
[FASE 4: DAY 3 MORNING + NIGHT 3]
     │
     ├─ Time trigger (Day 3 morning)
     ├─ TutorialManager.start("tutorial_defense")
     ├─ Wait: place_plant + trigger_ability + survive_night
     │
     ▼
[FASE 5: DAY 4 MORNING]
     │
     ├─ Dialogic.start("tutorial_complete")
     ├─ Signal: quest_complete
     ├─ Disable tutorial system
     │
     ▼
[FREE PLAY: AUTONOMOUS MODE]
```

---

## Quest Integration

### Tutorial Quest Definitions

```gdscript
# tutorial_day1_movement.tres
quest_id: &"tutorial_day1_movement"
title: "First Steps"
description: "Explore the garden and collect resources"
objectives:
  - "Move using WASD keys"
  - "Open your inventory"
  - "Collect your first resource"
trigger: "game_start"
reward: null

# tutorial_day1_crafting.tres
quest_id: &"tutorial_day1_crafting"
title: "Shape Your Tool"
description: "Craft your first weapon"
objectives:
  - "Find the Breeding Bench"
  - "Open the crafting menu"
  - "Craft the Thorn Sword"
trigger: "tutorial:phase1_complete"
reward: { item: "thorn_sword" }

# tutorial_day1_combat.tres
quest_id: &"tutorial_day1_combat"
title: "Defend the Heart"
description: "Survive the first night"
objectives:
  - "Strike a Shadowling"
  - "Survive until morning"
trigger: "time:night_day1"
reward: { xp: 50 }

# tutorial_day3_defense.tres
quest_id: &"tutorial_day3_defense"
title: "Garden Guardians"
description: "Plant defenders around the Core"
objectives:
  - "Place a protective plant"
  - "Activate plant ability"
  - "Survive Night 3"
trigger: "time:morning_day3"
reward: { xp: 100, items: ["seed_bougainvillea", "seed_rafflesia"] }
```

---

## Technical Implementation Checklist

### Core Systems

- [ ] `TutorialManager` singleton dengan state machine
- [ ] Dialogic timeline integration untuk semua fase
- [ ] Time-based trigger system (untuk combat dan defense phase)
- [ ] Phase completion trigger system (untuk movement → crafting transition)
- [ ] Quest event reporting hooks

### UI Components

- [ ] Callout system dengan highlight
- [ ] Key binding indicators (WASD, I, E, SPACE, P)
- [ ] Progress indicators per fase
- [ ] Tutorial skip/dismiss options

### Gameplay Systems

- [ ] Movement tutorial hooks (player_controller.gd)
- [ ] Crafting tutorial hooks (breeding_bench.gd)
- [ ] Combat tutorial hooks (enemy_spawner.gd)
- [ ] Plant placement tutorial hooks (placement_system.gd)

### Persistence

- [ ] Save tutorial progress to user://tutorial_progress.cfg
- [ ] Load tutorial state on game start
- [ ] Settings toggle for tutorial visibility

---

## Appendix: Timeline Trigger Mapping

| Dialogic Label | Trigger Condition | Tutorial ID |
|----------------|-------------------|-------------|
| `day_1_movement` | `GameManager.game_started == true` | `tutorial_movement` |
| `day_1_crafting` | Phase 1 complete (movement + inventory + collect) | `tutorial_crafting` |
| `night_1_combat` | `DayNightCycle.is_night == true` | `tutorial_combat` |
| `day_3_garden_defense` | `DayNightCycle.day >= 3 && DayNightCycle.is_day() == true` | `tutorial_defense` |
| `tutorial_complete` | `DayNightCycle.day >= 4 && is_morning` | (end state) |

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-04-29 | Initial document created |
| 1.1 | 2026-04-29 | Merged Phase 1 (Movement) and Phase 2 (Crafting) - crafting tutorial now triggers immediately after Phase 1 completion, no separate Sore/Day phase |
| 1.2 | 2026-04-30 | Changed Phase 4 from Sore & Malam to Pagi & Malam; Day 3 defense now starts at the Day phase instead of afternoon |
