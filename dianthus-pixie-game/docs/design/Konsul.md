# Dianthus Pixie — Giga Lab Admin Consultation Brief

## Project Overview
- **Engine:** Godot 4.x | **Style:** 2D Pixel Art | **Genre:** Survival Crafting Action
- **State:** Core systems are largely complete (save v10, 11 plants, 4 weapons, 5 enemy types, quest/ending systems, HUD, SFX wiring). Major content layers and polish are still open.

---

## 1. Highest-Risk Design Gaps (Need Admin Input)

### A. The Devourer Boss — `ENEMY-05` (Blocker for True Ending)
**This is the #1 unresolved design problem.** The GDD names a 3-phase boss with minion summoning but defines **zero** of the following:
- HP phase thresholds (e.g., Phase 1 → 2 at 70%, Phase 2 → 3 at 30%)
- Each phase's unique attack pattern or movement behavior
- Minion types summoned (existing enemies? new type?)
- Trigger condition for the final story night

> **Consult on:** Can we get a Devourer sub-document or a whiteboard session before any code is written? Without it, `ENEMY-05` is unimplementable and `END-01` (True Ending) can't fully fire.

---

### B. All 24 Cross-Breed Combinations — `PLANT-12`
Only **4 of 24** combos are defined in the GDD. The remaining 20 have no names, no effect descriptions, and no balance data. This blocks:
- `MINI-01` (Plant Experimentation minigame integration)
- `QUEST-04` (Discovery Quest rewards)
- Codex completion (UI-04)

> **Consult on:** Can the team author a combo spreadsheet? What plant pairs should produce what hybrid, and what failure state looks like (Wilted Plant at <30% score)?

---

### C. Plant Experimentation Minigame — `MINI-01` (High Priority, 0 files exist)
GDD §17 only says *"ritme sederhana / puzzle singkat"* — no input scheme, no scoring formula, no visual mockup. The [minigames/plant_experimentation/](cci:9://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/minigames/plant_experimentation:0:0-0:0) folder is **empty**.

> **Consult on:** Two candidates to prototype — (1) rhythm-tap (press button on beat), (2) node-connection puzzle (drag roots to slots). Which fits the plant-alchemy theme better? What's the minimum viable scoring function?

---

### D. Obsidian Bog Terrain Hazard — `WORLD-03`
GDD §10.1 says "terrain sulit" but doesn't define the mechanic. Movement penalty? Periodic damage? Sink mechanic?

> **Consult on:** What is the intended hazard? This determines whether it's a simple speed-modifier or a full damage-over-time system.

---

## 2. Content Gaps That Block Zone Progression

All 4 new zones are **empty folders**:

| Zone | Task | Blocker |
|---|---|---|
| [dusk_forest/](cci:9://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/world/zones/dusk_forest:0:0-0:0) | WORLD-01 | No tilemap, no resource pickups placed |
| [ruins_of_veld/](cci:9://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/world/zones/ruins_of_veld:0:0-0:0) | WORLD-02 | No tilemap, story-required landmark undefined |
| [obsidian_bog/](cci:9://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/world/zones/obsidian_bog:0:0-0:0) | WORLD-03 | Terrain hazard mechanic undefined |
| [core_sanctum/](cci:9://file:///c:/Users/Indra/Programming/GIGA/Dianthus%20Pixie/dianthus-pixie-game/world/zones/core_sanctum:0:0-0:0) | WORLD-04 | Gated behind QUEST-05 + ENEMY-05 completion |

Also: `WORLD-05` (garden expansion 12×10 → 20×16) and `WORLD-06` (Storage/Watchtower structures) are not started — these directly affect late-game strategy depth.

> **Consult on:** Is zone art/tilemap creation in scope for the Giga Lab sprint? If so, the Sprout Lands tileset is already in the project (`world/tilesets/`) and can be reused.

---

## 3. Open Audio Tasks (Music System is Fully Missing)

All music tracks are **Not Started** (`AUDIO-01` through `AUDIO-03`). The SFX system (83 sounds) is wired, but:
- No exploration music
- No preparation phase underscore
- No dynamic night combat layer (which requires a `MusicManager` autoload with bus routing)

> **Consult on:** Does Giga Lab have access to royalty-free music assets, or should these be sourced externally? The dynamic layer system (`AUDIO-03`) needs early Godot bus-routing prototyping — can a programmer sprint on it in parallel?

---

## 4. Open Animation / VFX (All Placeholders)

All combat VFX (`VFX-01` through `VFX-05`) use `ColorRect` tween placeholders with `TODO: VFX-05` stubs in code. Specifically missing:
- Player attack/dodge/respawn animations
- Dianthus Core idle glow + destruction animation
- Enemy walk/attack/death animations for all 6 types
- Plant bloom/wither animations
- Weapon swing arc particles

> **Consult on:** Is Aseprite sprite work planned for this sprint? The character size is 16×24px. Coordinate art priority: player and Shadowling animations are the most visible.

---

## 5. Remaining "Not Started" Tasks Summary

| Category | Open Tasks | Notes |
|---|---|---|
| Enemies | ENEMY-04 (Swarm Larva), ENEMY-05 (Devourer) | ENEMY-04 FSM unclear (shared vs. independent) |
| Worlds | WORLD-01 through WORLD-06 | All zones are empty |
| Difficulty | DIFF-02 (Surge Night), DIFF-03 (Night 21 Surge Escalation) | DIFF-02 affects spawn logic; DIFF-03 no longer adds a named boss |
| Minigames | MINI-01, MINI-02, MINI-03 | All folders empty |
| Audio | AUDIO-01, 02, 03 | No music system exists yet |
| VFX | VFX-01 through VFX-05 | All placeholders |
| Tutorial | ACCESS-03 (Interactive Tutorial Days 1–3) | Dialogic is installed but only In Progress |
| Content | PLANT-12 (20 undefined combos), RES-01 (resource scarcity) | Design debt |
| QA | QA-01 | Gated on everything above |

---

## Suggested Consultation Priorities (Ranked)

1. **Devourer boss design doc** — unblocks True Ending and the final content milestone
2. **Full 24-combo cross-breed table** — unblocks minigame + Discovery quests
3. **MINI-01 mechanic decision** — rhythm vs. puzzle; needs a prototype call
4. **Zone content plan** — which zones are in scope for this sprint, who makes the tilemaps
5. **Music asset sourcing** — royalty-free tracks or original composition?
6. **Animation/art sprint scope** — Aseprite sprite priority order
