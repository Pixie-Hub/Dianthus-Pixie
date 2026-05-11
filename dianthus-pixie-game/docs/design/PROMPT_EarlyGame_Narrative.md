# Implementation Prompt: Early-Game Narrative Pacing (Days 1–3 → Dusk Forest Unlock)

## Scope

This prompt covers the narrative layer for the **first ~5 days** of gameplay: the opening cutscene through the Dusk Forest unlock. It addresses four pillars: **narrative pacing**, **cutscene opportunities**, **emotional progression**, and **player guidance**. No files should be created yet — this is a design specification for implementation.

---

## 1. Current State (What Exists)

### Opening Cutscene
- [core/cutscenes/opening_cutscene.gd](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/core/cutscenes/opening_cutscene.gd:0:0-0:0) — 8-beat cinematic (BLACK_HOLD → 3 narrations → CORE_VISUAL → Dialogic → FINAL_NARRATION → TRANSITION). Drifting petal particles, pink Core pulse, shadow silhouettes.
- [dialogic/timelines/opening_cutscene.dtl](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/dialogic/timelines/opening_cutscene.dtl:0:0-0:0) — 5 Core lines: "You heard me" → "my roots are torn" → "stay near my light." Uses `Cutscene` Dialogic style.

### Tutorial (Days 1–3)
- [accessibility/tutorial/tutorial_manager.gd](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/accessibility/tutorial/tutorial_manager.gd:0:0-0:0) — 4-phase state machine:
  - **Phase 1 (Day 1 Morning):** Move 5s, open inventory, collect 3 Petal Shards + 2 Verdant Sap.
  - **Phase 2 (Day 1 Afternoon):** Find bench, open it, select Thorn Sword, craft it.
  - **Phase 3 (Night 1):** Hit a shadow creature, survive the night.
  - **Phase 4 (Day 3 Morning):** Enter plant mode, place a plant, trigger plant ability, survive Night 3.
- [dialogic/timelines/interactive_tutorial.dtl](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/dialogic/timelines/interactive_tutorial.dtl:0:0-0:0) — 7 labeled Dialogic segments with Core dialogue at each phase transition. Uses `Gameplay` Dialogic style.

### Story Quest Chain Start
- `quest_manager.gd:_maybe_start_story_chain()` — auto-fires on Day 2 DAY phase if `flag_story_chain_started` not set. Starts `story_01_whispers`.
- [story_01_whispers.tres](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/quests/data/story/story_01_whispers.tres:0:0-0:0) — **"Survive 3 nights"** (`target_count = 3`, no time limit, no fail branch). This is the canonical objective count — the PROMPT_STORY_QUESTS.md table entry of "2 nights" is superseded by this decision. Reward: 1 Aether Bloom + `flag_story_chain_started`. On complete: plays [story_01_complete.dtl](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/dialogic/timelines/story_01_complete.dtl:0:0-0:0), chains to `story_02_omen`.
- [story_01_complete.dtl](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/dialogic/timelines/story_01_complete.dtl:0:0-0:0) — 4 Core lines: "Four nights have passed" → "The shadows learned the garden's shape" → "Keep the Aether Bloom close" → "The next omen will not whisper from far away. It will come with teeth." Signals `quest_start:story_02_omen`.

### Story 02: An Ill Omen
- [story_02_omen.tres](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/quests/data/story/story_02_omen.tres:0:0-0:0) — "Defeat 10 enemies" (3-day time limit). Reward: 3 Moonspore. On complete: plays [story_02_complete.dtl](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/dialogic/timelines/story_02_complete.dtl:0:0-0:0), chains to `story_03_journey`. On fail: plays [story_02_fail.dtl](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/dialogic/timelines/story_02_fail.dtl:0:0-0:0), chains to `story_alt_lost`.
- [story_02_complete.dtl](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/dialogic/timelines/story_02_complete.dtl:0:0-0:0) — 4 Core lines: "Ten shadows have fallen" → "Moonspore clings to them" → "I feel an old road waking beyond the meadow" → "Follow that memory while the day still belongs to us." Signals `quest_start:story_03_journey`.
- [story_02_fail.dtl](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/dialogic/timelines/story_02_fail.dtl:0:0-0:0) — 3 Core lines: alternate path acknowledgment, redirects to `story_alt_lost`.

### Dusk Forest
- [dusk_forest.gd](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/world/zones/dusk_forest/dusk_forest.gd:0:0-0:0) — `MIN_UNLOCK_DAY = 3`. Resources: melati_seed, wijaya_kusuma_seed, rafflesia_seed, moonspore, shadow_resin, kecombrang_extract, stone. CanvasModulate dim-blue `Color(0.6, 0.65, 0.85)`. Zone registered via `ZoneTracker.enter_zone("dusk_forest")`.
- **No scene transition from Meadow Edge exists yet** (blocked by WORLD-01/WORLD-02).
- **No Dusk Forest unlock gate** tied to story_02 completion or any flag.

---

## 2. Narrative Pacing Design

### The Emotional Arc: "Learning to Care"

The first 5 days should take the player from **confused arrival** → **competent survival** → **curious attachment** → **resolve to push outward**. Each day-night cycle should deepen the player's relationship with the garden and the Core.

### Day-by-Day Pacing Table

| Day | Phase | Gameplay Focus | Narrative Layer | Emotional Target |
|-----|-------|---------------|----------------|-----------------|
| **Day 1 Morning** | Tutorial Phase 1–2 | Movement, gathering, crafting | Core speaks as a wounded mentor. "Wake, little alchemist." First gentle guidance. | **Disorientation → Purpose.** The player is lost but the Core gives them something to do. |
| **Night 1** | Tutorial Phase 3 | First combat | Core warns, player defends. Shadowlings are small and few. | **Fear → Relief.** First night survived. The danger is real but manageable. |
| **Day 2 Morning** | story_01 auto-starts | Free exploration, deeper gathering | Core acknowledges the first night. **New: short monologue on Day 2 dawn.** story_01 appears in Quest Log. | **Growing confidence.** The player knows the loop. The story quest gives them a reason to keep surviving. |
| **Night 2** | story_01 progress (1/3) | Harder wave, possibly Voidrunners | No new dialogue. The silence is intentional — let the combat speak. | **Tension.** The waves are learning. |
| **Day 3 Morning** | Tutorial Phase 4 | Plant placement tutorial | Core teaches plant defense. **The garden becomes an active participant.** | **Empowerment.** The player shapes the battlefield. |
| **Night 3** | story_01 progress (2/3 or 3/3) | Survive with plant help | story_01 may complete at dawn. If so, completion dialogue plays. | **Accomplishment.** Three nights means the Core trusts you. |
| **Day 4 Morning** | Tutorial completes; story_02 starts | Kill quest begins, Dusk Forest gate opens | Tutorial completion dialogue → story_01 completion dialogue → story_02 start. **Critical narrative beat: the Core reveals the world is larger.** | **Curiosity.** The meadow is not the whole world. |
| **Nights 4–5** | story_02 progress | Active enemy hunting | Player must seek enemies, not just survive. Moonspore drops hint at night-life. | **Aggression → Discovery.** Fighting teaches you what enemies carry. |
| **Day 5–6** | story_02 completes | Dusk Forest becomes accessible | story_02 completion: Core speaks of "an old road waking beyond the meadow." First zone transition. | **Wonder.** The forest is dim but alive. The tone shifts from survival to exploration. |

### Pacing Gaps to Fill

1. **Day 2 dawn silence.** Currently nothing happens between tutorial Night 1 completion and story_01 starting. The player wakes to Day 2 with no acknowledgment. Need a brief Core monologue.
2. **story_01 objective overlap with tutorial.** story_01 requires "survive 3 nights" but tutorial Phase 4 also requires "survive Night 3." The player completes both simultaneously. This is fine mechanically, but narratively the tutorial completion should play *before* the story_01 completion.
3. **No Dusk Forest gate.** story_02 rewards Moonspore but doesn't set an unlock flag for the forest. story_03 ("The Long Road") gates on `zone_entered:ruins_of_veld`, not Dusk Forest entry. The forest needs its own unlock moment.
4. **No internal Pixie monologues.** The Core speaks, but the player character never reacts internally. The STORY_OUTLINE calls for "short internal monologues" after discoveries.

---

## 3. Cutscene Opportunities

### Existing Cutscene Infrastructure
- **Opening Cutscene:** Full cinematic with beat system, tween animations, skippable. Uses `Cutscene` Dialogic style.
- **Dialogic Gameplay Style:** In-game dialogue boxes that don't pause the world (used by tutorial and story quest completions).
- **Tutorial HUD:** Objective checklist overlay managed by `TutorialManager`.

### Proposed New Narrative Moments

#### A. Day 2 Dawn — "The Garden Held" (micro-cutscene)
- **Trigger:** `phase_changed("DAY")` when `day_count == 2` and tutorial Phase 3 is complete.
- **Format:** 2–3 Dialogic lines, `Gameplay` style. No camera lock, no pause.
- **Content:** Core acknowledges the first night wasn't luck. Introduces the idea that the soil remembers the Pixie's footsteps.
- **Implementation:** New Dialogic label in [interactive_tutorial.dtl](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/dialogic/timelines/interactive_tutorial.dtl:0:0-0:0) or a new `story_interludes.dtl` timeline. TutorialManager already fires dialogue on phase transitions — add a DAY_2_DAWN interlude state or use a one-shot flag.

#### B. Tutorial Complete → story_01 Complete Sequencing
- **Problem:** If Night 3 survival completes both tutorial and story_01 on the same Day 4 dawn, two Dialogic timelines try to play. `interactive_tutorial.dtl:tutorial_complete` and [story_01_complete.dtl](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/dialogic/timelines/story_01_complete.dtl:0:0-0:0).
- **Solution:** Tutorial completion dialogue should play first (it's the shorter, more personal moment). story_01 completion should queue after tutorial ends. Use `Dialogic.timeline_ended` one-shot connection or a deferred call.
- **Emotional order:** "The garden breathes easier now" (tutorial) → brief pause → "Four nights have passed, and still my light has not gone out" (story_01).

#### C. First Plant Placement — Internal Monologue
- **Trigger:** `plant_placed` signal, first time only (check a one-shot flag).
- **Format:** 1–2 lines from the Pixie using a named character box (`"Pixie" (Thought):`). Visually distinct from Core lines — use a different name color and portrait-less layout in the `Gameplay` Dialogic style.
- **Content per STORY_OUTLINE:** "The soil warms around it, as if the garden has been waiting to be touched without fear."
- **Implementation:** Create `dialogic/characters/Pixie.dch` for all internal monologues. All Pixie lines use the `(Thought)` variant portrait to signal interiority. Never use a nameless narrator line for Pixie dialogue — the named box distinguishes the player character's voice from the world's voice.

#### D. story_02 Complete — Dusk Forest Reveal
- **Trigger:** story_02 completion.
- **Format:** Dialogic `Gameplay` style, 4 lines (already authored). But should also trigger a **visual cue**: minimap or HUD pulse showing a new zone is available.
- **Enhancement:** After the existing [story_02_complete.dtl](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/dialogic/timelines/story_02_complete.dtl:0:0-0:0) plays, show a one-shot notification: "The Dusk Forest path has opened." This could be a floating UI notification or a brief Core addendum.

#### E. First Dusk Forest Entry — Zone Transition Moment
- **Trigger:** First `ZoneTracker.enter_zone("dusk_forest")` call.
- **Format:** 2 lines from Core + 1 internal Pixie monologue. `Gameplay` style.
- **Content:** Core: "The forest remembers night differently. Not as enemy, but as habit." `"Pixie" (Thought):` "It grows in darkness, but it does not feel cruel." (directly from STORY_OUTLINE §3 monologue list).
- **Blocked by:** WORLD-01/WORLD-02 (scene transitions not yet implemented). This cutscene should be authored but cannot be wired until zone transitions exist.

---

## 4. Emotional Progression Map

```
DAY 1 MORNING          NIGHT 1              DAY 2             NIGHT 2
  │                      │                    │                  │
  ▼                      ▼                    ▼                  ▼
Confusion → Purpose    Fear → Relief     Confidence → Routine   Tension
"Where am I?"         "I can fight."     "I know this loop."   "They're adapting."
Core: wounded mentor   Core: trembling    Core: grateful        (silence)
                                         story_01 starts


DAY 3                  NIGHT 3              DAY 4              NIGHTS 4-5
  │                      │                    │                  │
  ▼                      ▼                    ▼                  ▼
Empowerment           Accomplishment      Curiosity            Discovery
"The garden fights    "Three nights.      "What's beyond       "The enemies carry
 with me."             The Core trusts     the meadow?"         traces of life."
 Plant tutorial.       me now."            Tutorial done.       Moonspore appears.
                      story_01 completes. story_02 starts.     Active hunting.


DAY 5-6
  │
  ▼
Wonder → Resolve
"Darkness shelters life too."
Dusk Forest opens.
story_02 completes.
Tone shift: survival → exploration.
```

### Key Emotional Transitions

1. **Fear → Competence (Night 1 → Day 2):** The player survives something real. The Core stops explaining and starts trusting.
2. **Routine → Attachment (Day 2 → Day 3):** The game loop becomes familiar. The plant placement tutorial transforms the garden from a backdrop into something the player built. This is when the player starts *caring* about the garden, not just defending it.
3. **Attachment → Curiosity (Day 4):** Tutorial completion + story_01 completion land as a double beat. The Core opens the door: "I feel an old road waking beyond the meadow." The player has earned the right to ask "what else is out there?"
4. **Curiosity → Wonder (Dusk Forest entry):** The color palette shifts from warm meadow to dim blue. Night-blooming resources (Melati, Wijaya Kusuma) reframe darkness as complex, not purely hostile. This is the STORY_OUTLINE's key idea: "the Pixie learns darkness can shelter life as well as danger."

---

## 5. Player Guidance Design

### Guidance Channels (Ranked by Intrusiveness)

| Channel | Use When | Example |
|---------|----------|---------|
| **Quest Log objective** | Always-on passive guidance | "Survive 3 nights (1/3)" |
| **Core Dialogic line** | Phase transitions, milestone completions | "The sun leans west. This is preparation time." |
| **Tutorial HUD overlay** | Active tutorial phases only (Days 1–3) | Checklist: ☐ Place a plant ☐ Trigger plant ability |
| **Floating label / popup** | One-shot discoveries, item pickups | "+1 Night Intel" / "Dusk Forest Unlocked" |
| **Internal monologue** | First-time discoveries, emotionally charged moments | "The soil warms…" |
| **Minimap marker** | Spatial guidance toward objectives | Yellow pulsing dot for events |
| **Environmental cue** | Passive, no text | Core glow brightening, soil color change |

### Guidance Flow by Segment

#### Days 1–3 (Tutorial Active)
- **Primary guide:** Tutorial HUD checklist. The Core's Dialogic lines explain *why*, the checklist shows *what*.
- **Anti-overwhelm:** Tutorial objectives are sequential (movement → crafting → combat → plants). Never more than 4 checkboxes visible.
- **story_01 in background:** Quest Log shows "Survive 3 nights" but the tutorial HUD dominates attention. This is correct — the story quest should feel like a passive milestone, not a competing objective.

#### Day 4 (Transition Day)
- **Tutorial HUD disappears.** The player must now rely on Quest Log and Core dialogue.
- **Guidance gap risk:** The player has been hand-held for 3 days. Day 4 is the first "free" day. story_02 ("Defeat 10 enemies") gives direction but doesn't tell the player *how* to find enemies.
- **Proposed solution:** story_02 start dialogue should include a gentle hint: enemies come at night, but the Core can feel their traces during the day (foreshadowing scout tracks / daytime events). This avoids the player feeling abandoned after tutorial ends.

#### Days 4–6 (story_02 Active)
- **Primary guide:** Quest Log ("Defeat 10 enemies, 4/10"). The kill counter provides constant feedback.
- **Secondary guide:** Moonspore drops from enemies. The 3× Moonspore reward on completion reinforces the connection between combat and resources.
- **Dusk Forest gate:** When story_02 completes, the Dusk Forest path should unlock with a clear visual/audio cue. The player needs to understand that new territory is available without being forced to go there immediately.

#### First Dusk Forest Visit
- **No active quest forces the player here.** story_03 ("The Long Road") asks them to reach Ruins of Veld, which is *past* the Dusk Forest. The forest is a waypoint, not a destination.
- **Guidance approach:** Environmental storytelling. The dim-blue CanvasModulate, new resources (Melati, Wijaya Kusuma), and a Core monologue on entry orient the player without objectives.
- **Risk:** If the player never visits, story_03's 4-day time limit creates pressure. The Core's story_02 completion line ("I feel an old road waking beyond the meadow") is the primary push.

---

## 6. Implementation Checklist (Ordered)

When this prompt is approved for implementation, the work should proceed in this order:

1. **Author `dialogic/characters/Pixie.dch`** — Dialogic character for all Pixie internal monologues. Use a named character box `"Pixie" (Thought):` with a distinct name color (soft lavender or muted gold, not the Core's warm white). No portrait image required — the name and thought variant convey interiority. All internal monologue lines in every timeline use this character.
2. **Author `dialogic/timelines/story_interludes.dtl`** — New timeline with labeled sections for:
   - `day_2_dawn` — 2–3 Core lines acknowledging first night survival.
   - `first_plant_monologue` — 1–2 Pixie internal monologue lines.
   - `dusk_forest_entry` — 2 Core lines + 1 Pixie monologue.
   - `dusk_forest_unlocked` — 1-line notification after story_02 completes.
3. **Wire Day 2 dawn interlude** — Add one-shot trigger in [tutorial_manager.gd](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/accessibility/tutorial/tutorial_manager.gd:0:0-0:0) or [quest_manager.gd](cci:7://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/quests/scripts/quest_manager.gd:0:0-0:0) on `phase_changed("DAY")` when `day_count == 2` and Phase 3 is complete.
4. **Fix story_01/tutorial completion sequencing** — Ensure tutorial completion dialogue plays before story_01 completion dialogue when both fire on Day 4 dawn. Add deferred chaining.
5. **Add Dusk Forest unlock flag** — Gate is **Day ≥ 5 AND story_02 complete**. Both conditions must be true simultaneously. Add `unlock_zone_dusk_forest` to `story_02_omen.tres:reward_unlock_flags`. The zone transition system (WORLD-01/WORLD-02) checks this flag before allowing travel. The day-gate prevents the flag from unlocking early if story_02 somehow completes before Day 5. Author the flag constant in `StoryEndingFlags` and the gate check stub now; wire into the actual transition when WORLD-01/WORLD-02 lands.
6. **Wire first-plant-placed monologue** — One-shot flag checked in `plant_placement_manager.gd` on `plant_placed` signal. Triggers `story_interludes.dtl:first_plant_monologue`.
7. **Enhance story_02 start dialogue** — Add a hint about finding enemies (night combat, not daytime hunting) to bridge the tutorial → free-play guidance gap.
8. **Author Dusk Forest entry cutscene** — Wire to `ZoneTracker.enter_zone("dusk_forest")` first-time check. Deferred until WORLD-01/WORLD-02 provides scene transitions.

---

## 7. Design Decisions (Resolved)

1. **Pixie voice in Dialogic:** Named character box — `"Pixie" (Thought):`. Distinct name color from the Core. No portrait. Used for all internal monologues across all timelines.
2. **Dusk Forest unlock trigger:** **Day ≥ 5 AND story_02 complete** (both required). `unlock_zone_dusk_forest` flag set in `story_02_omen.tres:reward_unlock_flags`. Zone transition gate checks both the flag and `DayNightCycle.day_count >= 5`.
3. **story_01 objective count:** **3 nights** is canonical. `story_01_whispers.tres` (`target_count = 3`) is correct. PROMPT_STORY_QUESTS.md's "2 nights" entry is an earlier draft and is superseded. No change needed to the `.tres` file.
4. **Moonspore lore delivery:** Dialogue only. The Codex entry for Moonspore unlocks when the player picks it up (existing Codex system), but the lore text in `story_02_complete.dtl` is the primary narrative delivery. No new Codex text needs to be authored as part of this prompt.

---

## 8. Dialogue Polish Pass (Completed)

All `.dtl` timelines and `opening_cutscene.gd` narration strings have been polished for emotional pacing, cutscene wording, monologue quality, environmental narration, and tone consistency. The following principles were applied:

### Writing Principles Used

- **Ellipsis for vulnerability.** Opening beats use `…` to convey fragile wakefulness or dread (`"…you heard me."`, `"…the dark has found us."`, `"…the Devourer is gone."`). These mirror each other across the arc: the first and last words the Core speaks both begin from a place of trembling.
- **Botanical imagery over abstract exposition.** Metaphors stay grounded in roots, soil, petals, thorns, and seeds. The Void is described through physical sensation ("pressing its mouth", "thicken in the soil", "breathing where breath should not reach") rather than abstract evil.
- **Earned repetition for emotional weight.** Key moments use deliberate repetition: `"And still — still — my light has not gone out"`, `"That is enough. That has to be enough."`, `"Answer with all of it."` These slow the reader and signal that the Core is processing emotion, not just delivering information.
- **Sensory specificity in environmental narration.** The `.gd` cutscene strings now use fragmented rhythm (`"A storm without rain. It carries ash, seeds, and the last breath of a dying light."`) and personification (`"a lantern that has forgotten how to rest"`).
- **The Core's voice arc: wounded mentor → trusting companion → grieving parent → hopeful friend.** Early tutorial lines show the Core explaining and hoping; mid-game lines show it trusting and warning; late-game lines show it giving parts of itself; endings show it either celebrating or learning to accept loss.
- **Failure paths carry grief, not punishment.** Failed quest dialogue shows the Core absorbing the loss personally ("a wound I must learn to carry", "more fragile than I want you to know") while redirecting the player toward stubborn hope. Every failure closing includes a botanical metaphor for persistence.
- **Callback threading.** The final victory (`story_07_complete`) deliberately echoes the opening: "bruised and fading in the dark" calls back to `day_1_movement`'s "bruised, but breathing." The arc closes where it began.

### Files Modified

| File | Changes |
|------|---------|
| `dialogic/timelines/opening_cutscene.dtl` | Expanded Core self-introduction with vulnerability; shadow warning given physicality; tender closing beat |
| `core/cutscenes/opening_cutscene.gd` | 3 environmental narration strings + final narration polished for imagery and rhythm |
| `dialogic/timelines/interactive_tutorial.dtl` | All 9 labeled segments polished: sensory detail, emotional beats, botanical metaphors, Core voice consistency |
| `dialogic/timelines/story_01_complete.dtl` | Repetition emphasis, shadow specificity, Void characterization deepened |
| `dialogic/timelines/story_02_complete.dtl` | Void given agency ("patience"), Dusk Forest named as waypoint, urgency added |
| `dialogic/timelines/story_02_fail.dtl` | Sensory root detail, expanded garden metaphor, grieving but resolute tone |
| `dialogic/timelines/story_03_complete.dtl` | Sensory Veld detail, poetic inversion, Shadow Resin nuance, thematic roots-through-burial closing |
| `dialogic/timelines/story_03_fail.dtl` | "Shallow grave" simile, longing detail, defiant closing |
| `dialogic/timelines/story_04_complete.dtl` | Triplet rhythm, Weaver door imagery, oldest-roots recipe, seal pressure |
| `dialogic/timelines/story_04_fail.dtl` | Core's sensory loss, "regret does not grow roots" aphorism |
| `dialogic/timelines/story_05_complete.dtl` | Devourer weight, binary choice, pollen's hidden history, trust-giving closing |
| `dialogic/timelines/story_05_fail.dtl` | Root-wound imagery, "stubborn thread", seed-hunger metaphor |
| `dialogic/timelines/story_06_complete.dtl` | Pollen gift as intimacy, Blazeblade "remembers dawn", sacrifice acknowledged, crescendo closing |
| `dialogic/timelines/story_07_complete.dtl` | Ellipsis opener, callback to opening, silence named as peace, player agency honored |
| `dialogic/timelines/story_07_fail.dtl` | Core's personal grief, "steals from us", bittersweet "what light felt like" |
| `dialogic/timelines/story_alt_lost_complete.dtl` | "Swallowed whole", grief + redefinition, repeated "enough" for resonance |
| `dialogic/timelines/story_alt_shadow_loss_complete.dtl` | Root channel loss, expanded resistance, territory vs identity line |
| `dialogic/timelines/story_alt_devourer_loss_complete.dtl` | Sleeping Devourer imagery, Core admits fragility, seeds-become-forests hope |