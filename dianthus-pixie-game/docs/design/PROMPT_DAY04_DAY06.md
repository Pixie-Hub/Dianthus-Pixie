# PROMPT — DAY-04 & DAY-06: Scout Tracks Night Intel + Return Pressure & 3-Minute Tuning

**Task IDs:** DAY-04, DAY-06
**Category:** Core Mechanics
**Priority:** High (DAY-04), Medium (DAY-06)
**Effort:** M + S
**Dependencies (all Done):**
- DAY-01 (Meadow Edge Route Relayout)
- DAY-02 (Bramble Obstacles & Optional Pockets)
- DAY-03 (Rare Harvest Node & QTE Hook)
- DAY-05 (Daytime Resource Placement Rules)
- CORE-07 (Wave Spawner)
- UI-01 (Full HUD — Minimap, Time-of-Day, Wave Counter)
- FOUND-05 (Day-Night Cycle Timer)

**Design Reference:** `docs/design/DAYTIME_PHASE_OVERHAUL_PLAN.md` — §4 (Daytime Actions That Affect Night), §6.6 (Return Pressure), Recommended 3-Minute Flow
**GDD Reference:** §10.3 (wave spawn directions), §11.1 (minimap spawn arrows), §12.3 (audio/visual pressure)

---

## Goal

Add the final two pieces of the daytime phase overhaul:

1. **DAY-04 — Scout Tracks:** An optional in-world interactable that the player can find during the DAY phase. Interacting with it reveals **one likely active night spawn direction** on the HUD minimap, giving the player strategic intelligence at the cost of exploration time.

2. **DAY-06 — Return Pressure & 3-Minute Tuning:** Make the final 30 seconds of the daytime phase feel urgent through audio, visual, and HUD cues, and verify the 180-second (3-minute) DAY phase duration makes it impossible to fully clear all routes in a single run.

---

## Scope — DAY-04: Scout Tracks Night Intel

### Scout Tracks Interactable

Create a new scene `world/obstacles/scout_tracks.gd` + `world/obstacles/scout_tracks.tscn`.

**Scene structure:**
- Root: `Area2D` (named `ScoutTracks`)
- Children: `CollisionShape2D` (CircleShape2D, radius ~12px), `Visual` (ColorRect or Sprite2D placeholder — earthy brown/tan, ~12×12 px), `PromptLabel` (Label, "Press E to Scout", hidden by default)

**Behavior:**
- `collision_layer = 0`, `collision_mask = 4` (player layer) — detects player proximity
- On `body_entered` (player): show `PromptLabel`
- On `body_exited` (player): hide `PromptLabel`
- On `interact` input action (E key) while player is overlapping and `DayNightCycle.is_day()`:
  1. Play an SFX (reuse `"codex_unlocked"` or add a new `"scout_tracks_reveal"` ID — see Audio section)
  2. Call `WaveSpawner.predict_spawn_direction()` to get the scouted direction (see below)
  3. Store the result on a **new signal/var accessible by the minimap** (see HUD section)
  4. Show brief floating text feedback: `"+1 Night Intel"` or `"Spawn direction revealed!"` (tween up + fade, same pattern as resource pickup popup in `resource_pickup.gd`)
  5. Mark this tracks instance as **used for this day** — set `_scouted_today = true`, grey out the visual, change prompt to `"Already scouted"`
  6. Reset `_scouted_today = false` on `DayNightCycle.phase_changed` → `"DAY"` (new day = fresh intel)
- Interaction should cost **real time** — the tracks nodes must be placed far enough from Garden Gate that visiting them competes with a gathering route (see Placement section)
- Add to group `&"scout_tracks"` for easy lookup

### WaveSpawner — Predict Spawn Direction

Add a public method to `enemies/spawner/wave_spawner.gd`:

```gdscript
func predict_spawn_direction() -> Vector2:
```

**Logic:**
1. Pick one random `Marker2D` from `_spawn_point_markers` — this represents a "likely" spawn point for tonight
2. Return its `global_position`
3. This is a **prediction**, not a guarantee — the actual `start_wave()` randomly selects 1–3 of 4 cardinal points. The scouted point has a **high probability** of being active but is not 100%. Acceptable approach: pick one marker at random and return it; alternatively, weight toward a pre-seeded RNG that correlates with tonight's actual roll (designer preference — random pick is simplest and sufficient for MVP)

**Important:** Do NOT pre-roll the actual wave spawn points during daytime. `start_wave()` must remain the single source of truth for `_active_spawn_points`. The scout prediction is an *informed guess*, not a spoiler.

### HUD — Scouted Direction on Minimap

Extend the minimap (`ui/hud/map_view.gd`) to show scouted intel:

1. Add a new public API accessible from the scene or via a signal:
   ```gdscript
   var _scouted_spawn_point: Vector2 = Vector2.ZERO
   var _has_scouted_intel: bool = false

   func set_scouted_intel(world_pos: Vector2) -> void:
       _scouted_spawn_point = world_pos
       _has_scouted_intel = true

   func clear_scouted_intel() -> void:
       _scouted_spawn_point = Vector2.ZERO
       _has_scouted_intel = false
   ```

2. In `_draw()`, **during DAY phase only** (when normal spawn arrows are hidden), draw a **yellow/gold pulsing arrow** at the minimap edge pointing toward `_scouted_spawn_point` if `_has_scouted_intel` is true
   - Use a distinct color from the red night-active spawn arrows: `Color(1.0, 0.85, 0.2, 1)` (gold)
   - Pulse the alpha (0.5–1.0 sinusoidal) to make it noticeable but not overwhelming
   - During NIGHT phase, the scouted arrow should remain visible (gold) alongside the real red spawn arrows so the player can compare prediction vs reality

3. Clear scouted intel on `DayNightCycle.phase_changed` → `"DAY"` (new day = stale intel)

### ScoutTracks → Minimap Wiring

The scout_tracks node needs to reach the minimap. Recommended approach:
- `ScoutTracks` calls a method on a **scene-local** reference (find `MapView` via `get_tree().current_scene.find_child()`) or emit a signal that the HUD listens to
- Simplest: `ScoutTracks` finds the minimap node and calls `set_scouted_intel(predicted_pos)` directly after getting the prediction from WaveSpawner
- The `MapView.clear_scouted_intel()` call should be connected to `DayNightCycle.phase_changed` inside `map_view.gd` `_ready()`

### Placement in Meadow Edge

Place **2 ScoutTracks instances** in `world/zones/meadow_edge/meadow_edge.tscn`:
- One at the far end of the **Sap Grove route arm** (forces a long detour from Garden Gate)
- One near **Old Root Hollow or Ruin Glimmer** (far from base, competing with rare resource gathering)

Both should be children of `YSortLayer` so they Y-sort with other world objects.

The positions should be far enough from the Garden Gate that scouting costs 15–25 seconds of round-trip travel time — enough to feel like a meaningful daytime decision.

### Save/Load

Scout tracks state is **transient** (per-day, resets each morning). No save schema change needed. The `_scouted_today` flag and `_has_scouted_intel` both reset on phase change.

---

## Scope — DAY-06: Return Pressure & 3-Minute Tuning

### Final 30-Second Warning System

The `DayNightCycle` DAY phase is already 180 seconds. The music system already crossfades from `exploration_day` to `preparation_phase` at 30 seconds remaining (`MusicManager.PREPARATION_THRESHOLD = 30.0`). Build on this existing behavior:

#### 1. Time-of-Day Indicator Warning Enhancement

In `ui/hud/time_of_day_indicator.gd`:
- The track already turns red at `NIGHT_WARNING_THRESHOLD = 0.75` progress (i.e., 45 seconds remaining)
- **Add a stronger urgency at ≤30 seconds remaining:** pulse the Time-of-Day track background between `TRACK_WARNING_COLOR` and a brighter red/orange at ~1 Hz
- **Add a countdown flash** on the `_label` text: when ≤15 seconds remain, make the time text pulse between normal and bright red/white

#### 2. World Tint Shift

In `core/day_night/day_night_cycle.gd`:
- Add a **pre-night tint shift** in the final 30 seconds of DAY phase
- In `_process()`, when `current_phase == Phase.DAY` and `_phase_timer <= 30.0`:
  - Lerp `_canvas_modulate.color` from the DAY tint toward a **dusk/orange tint** `Color(0.85, 0.65, 0.45)` based on how deep into the final 30 seconds the timer is
  - This should be a smooth progressive shift, not a sudden change
  - The existing `_apply_tint()` call on `_advance_phase()` will handle the actual DAY→NIGHT transition

#### 3. HUD Return Reminder

In `ui/hud/hud.gd`:
- Add a **"Return to Garden!"** warning label that appears when DAY phase has ≤30 seconds remaining
- Position: top-center or bottom-center, below the Core HP bar
- Style: warm gold/red text, moderate size (~8pt), pulsing opacity
- Hide when phase changes to NIGHT or when timer is >30 seconds
- Connect to `DayNightCycle.phase_changed` to reset visibility

#### 4. Audio Pressure

The music crossfade to `preparation_phase` at 30 seconds is already implemented in `music_manager.gd`. Add one additional audio cue:
- At exactly 30 seconds remaining, play a one-shot SFX: reuse `"night_transition"` at lower volume, or add a new `"return_warning"` SFX ID
- This serves as the "audio sting" that signals "time to head back"
- Do NOT play this during NIGHT phase or if the phase is already NIGHT

#### 5. Tuning Verification

The 3-minute timer combined with the DAY-01 route layout should already make it impossible to visit all 3 route arms and collect everything. Verify by confirming:
- DAY phase duration: `PHASE_DURATIONS[Phase.DAY] = 180.0` (already set)
- No code changes needed for the timer itself
- Add a `print()` in the 30-second warning trigger point that logs: `"[DayNightCycle] Return pressure: %d seconds remaining"` — helps with playtesting validation

### Out of Scope

- Changing the 180-second DAY duration (leave as-is; tuning is a playtest concern)
- Fast-return shortcuts or teleporting (those are WORLD-05/WORLD-06 features)
- Garden path signs or trail markers (future polish)
- Any changes to NIGHT phase timing or wave spawner behavior
- New music tracks (reuse existing `preparation_phase` crossfade)

---

## Audio

### New SFX (optional — can reuse existing)

| SFX ID | Description | Fallback |
|--------|-------------|----------|
| `scout_tracks_reveal` | Short nature/discovery chime when scouting | Reuse `codex_unlocked` |
| `return_warning` | Urgent sting at 30 seconds remaining in DAY | Reuse `night_transition` at -10 dB |

If adding new SFX IDs:
1. Add entries to `SFX` dict in `audio/sfx_manager.gd`
2. Create placeholder `.wav` files or reuse existing ones via path aliasing
3. Add corresponding `AudioStreamPlayer2D` nodes in the SfxManager scene (`audio/sfx_manager.tscn`) under both `GlobalPlayers` and `SpatialPlayers` pools

If reusing existing SFX, just call `SfxManager.play("codex_unlocked")` / `SfxManager.play("night_transition")` directly. No new registrations needed.

---

## Debug Keys

| Key | Action | Task |
|-----|--------|------|
| Shift+8 | Force-scout: call `predict_spawn_direction()` on WaveSpawner + feed result to minimap; prints scouted position | DAY-04 |
| Shift+9 | Set DayNightCycle timer to 35 seconds remaining (test return pressure without waiting 2.5 minutes) | DAY-06 |

Add both to `player/scripts/player_controller.gd` in the existing debug key block.
Update `docs/design/PERSON_TASKS.md` debug key table.

---

## Files to Create

| File | Description |
|------|-------------|
| `world/obstacles/scout_tracks.gd` | ScoutTracks interactable — Area2D with E-key interaction, one-per-day scouting |
| `world/obstacles/scout_tracks.tscn` | ScoutTracks scene — Area2D + collision + visual + prompt label |

## Files to Modify

| File | Change |
|------|--------|
| `enemies/spawner/wave_spawner.gd` | Add `predict_spawn_direction() -> Vector2` method |
| `ui/hud/map_view.gd` | Add `_scouted_spawn_point` / `_has_scouted_intel` / `set_scouted_intel()` / `clear_scouted_intel()`; draw gold arrow during DAY; connect phase_changed to clear intel |
| `ui/hud/time_of_day_indicator.gd` | Add ≤30s track pulse and ≤15s text flash |
| `core/day_night/day_night_cycle.gd` | Add pre-night dusk tint lerp in `_process()` for final 30 seconds |
| `ui/hud/hud.gd` | Add "Return to Garden!" warning label at ≤30 seconds DAY remaining |
| `player/scripts/player_controller.gd` | Add Shift+8 (force-scout) and Shift+9 (set timer to 35s) debug keys |
| `world/zones/meadow_edge/meadow_edge.tscn` | Instance 2 ScoutTracks nodes in YSortLayer at route-arm endpoints |
| `docs/design/PERSON_TASKS.md` | Add Shift+8 and Shift+9 to debug key table |
| `docs/design/TASK_BREAKDOWN.md` | Update DAY-04 and DAY-06 status to Done |

---

## Acceptance Criteria

### DAY-04
- [ ] Scout Tracks interactable exists as a placeable scene with E-key interaction
- [ ] Interaction is DAY-only and one-per-day (resets each morning)
- [ ] Scouting reveals a gold arrow on the minimap pointing toward a likely spawn direction
- [ ] The gold arrow persists into NIGHT phase alongside real red spawn arrows
- [ ] Intel clears automatically on the next DAY phase change
- [ ] Scout Tracks are placed far enough from Garden Gate to cost meaningful travel time (15–25 seconds round trip)
- [ ] Shift+8 debug key forces a scout reveal without physically visiting the tracks

### DAY-06
- [ ] Final 30 seconds of DAY phase: world tint shifts toward dusk orange
- [ ] Final 30 seconds of DAY phase: music crossfades to `preparation_phase` (already working)
- [ ] Final 30 seconds of DAY phase: one-shot audio sting plays
- [ ] Final 30 seconds of DAY phase: "Return to Garden!" HUD label appears and pulses
- [ ] Final 15 seconds: time display text flashes urgently
- [ ] All pressure indicators clear on phase transition to NIGHT
- [ ] The 3-minute DAY duration makes it impossible to fully clear all routes in a single run (verify via playtest)
- [ ] Shift+9 debug key sets timer to 35 seconds for quick pressure testing

---

## Implementation Order

1. `wave_spawner.gd` — add `predict_spawn_direction()`
2. `map_view.gd` — add scouted intel drawing + clear on phase change
3. `scout_tracks.gd` + `.tscn` — create the interactable
4. `meadow_edge.tscn` — place 2 ScoutTracks instances
5. `day_night_cycle.gd` — add dusk tint lerp
6. `time_of_day_indicator.gd` — add ≤30s pulse + ≤15s text flash
7. `hud.gd` — add "Return to Garden!" label
8. `player_controller.gd` — add debug keys
9. Update `PERSON_TASKS.md` and `TASK_BREAKDOWN.md`
10. Git commit

---

## Existing Code Reference

### DayNightCycle
- `current_phase: Phase` (DAY/NIGHT enum)
- `_phase_timer: float` — counts down from `PHASE_DURATIONS[phase]` (180.0 for DAY)
- `get_time_remaining() -> float`
- `get_phase_progress() -> float` (0.0 → 1.0)
- `phase_changed` signal emits phase name string ("DAY"/"NIGHT")
- `_canvas_modulate: CanvasModulate` — tint node registered by zone scene

### WaveSpawner
- `_spawn_point_markers: Array[Marker2D]` — 4 cardinal Marker2D children
- `_active_spawn_points: Array[Vector2]` — set in `start_wave()`, cleared in `_cleanup_wave()`
- `get_active_spawn_points() -> Array[Vector2]` — returns current night's active spawn positions

### MapView (minimap base class)
- `_spawner: WaveSpawner` — cached reference found via `find_child("WaveSpawner")`
- `_draw()` renders spawn arrows only during NIGHT + wave_active
- `_draw_arrow(tip, dir)` — draws a triangle at minimap edge
- `_world_to_map(world_pos, player_pos) -> Vector2` — converts world coordinates to minimap coordinates
- `_compute_box_edge(center, dir, draw_size) -> Vector2` — projects direction to minimap edge

### MusicManager
- `PREPARATION_THRESHOLD = 30.0` — crossfades to `preparation_phase` track at this many seconds remaining
- `_update_day_layers()` — called in `_process()` during DAY, checks remaining time
- Already handles exploration→preparation crossfade

### BramblePatch (reference pattern for interactable obstacles)
- `class_name BramblePatch extends StaticBody2D`
- Uses collision layers, groups, SFX, damage flash tween
- Good reference for scene structure

### ScoutTracks interaction pattern
- Follow the same `interact` input action (E key) used by `breeding_bench.gd`
- BreedingBench uses an `InteractionZone` Area2D child to detect player proximity
- Prompt label shown/hidden on enter/exit
