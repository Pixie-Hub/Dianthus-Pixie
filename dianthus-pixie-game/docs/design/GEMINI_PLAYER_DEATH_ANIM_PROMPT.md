# Gemini Image Generation Prompt — Dianthus Pixie Death Animation Spritesheets

## Overview

Generate **4 death animation spritesheets** (one per direction) from the existing idle and walk spritesheets. Each spritesheet is a single horizontal strip of **6 frames**, each frame 32×48 pixels, producing a **192×48 pixel PNG**.

**This is a ONE-SHOT animation — it does NOT loop.** Frame 6 is the final held death pose.

**Attach the full idle spritesheet, the full walk spritesheet, AND the corresponding single-direction idle frame** when sending each prompt to Gemini.

---

## Style Rules (all directions)

```
- Strict pixel art — no anti-aliasing, no gradients, no soft edges, no sub-pixel rendering
- Each frame is exactly 32 pixels wide × 48 pixels tall
- 6 frames arranged in a single horizontal strip → total image size: 192×48 pixels
- Transparent background — no solid background color
- Limited palette: same 8-12 colors as the reference image (do not introduce new colors)
- 1-pixel dark outline around the character in all frames
- Output: a single PNG image, 192×48 pixels, transparent background, no upscaling, no smoothing, no filtering
- Art direction: 2D pixel art for a fantasy survival crafting game with a Southeast Asian botanical theme
- The character must be fully contained within each 32×48 cell with no cropping
- This animation does NOT loop — Frame 6 is the final static death pose
```

---

## Color Palette (all directions — must match reference exactly)

```
- Skin: warm tan (#C8956E, #A87048)
- Hood/cloak: forest green (#4A7A3A, #3D6430), dark green shadow (#2A4820)
- Dianthus flower accents: pink/magenta (#FF9EC8, #FF6B9D, #E84A7F)
- Tunic: warm cream (#E8D8B8, #D4C4A0)
- Satchel/belt: brown leather (#8C6030, #6B4420)
- Trousers: earthy brown (#7A6040, #5C4830)
- Boots: dark brown (#3D2A18, #2A1C10)
- Hair: dark brown (#2A1810)
- Eyes: dark (#1A1008)
- Outline: near-black (#1A1410)
- Scattered petals: use existing dianthus pink colors only — no new colors
```

---

## Animation Description (all directions)

The death animation is a **6-frame collapse sequence** transitioning from a standing pose into a flat, motionless figure on the ground. Total sprite height decreases progressively.

```
Frame 1 — Reaksi Awal (Initial Reaction):
Still fully upright. Character jolts as if struck. Eyes (two pixel dots) slightly widen.
Shoulders raise (hood lifts ~1 pixel). Knees slightly bend (legs shorten 1 pixel at boot level).
Hood flower accents remain intact and upright. Arms tense at sides.

Frame 2 — Mulai Terjatuh (Beginning to Fall):
Still upright but losing balance. Knees bend deeper (legs shorten 2-3 pixels).
Body tilts slightly forward. The viewer's-right arm raises 1-2 pixels (bracing gesture).
Hood flower accents tilt/sway. No petals yet.

Frame 3 — Tersungkur ke Bawah (Collapsing Downward):
Dramatic collapse. Total visible height reduces by ~8 pixels (feet compress/disappear as
legs fold). Hood covers more of the face. Hair pixels scatter slightly from under the hood edge.
Satchel/belt pouch clearly visible. 2-3 pink/magenta petal pixels scatter near the hood.

Frame 4 — Hampir Terkapar / Knee-Knock (Near-Collapsed Heap):
Body collapses into a small crumpled pile in the lower ~20 pixels of the frame.
Top 28+ pixels are transparent. Hood is at ground level, shape squarish/flat (face-down).
Arms extend outward to catch the fall. Satchel appears beside the hood.
4-6 pink petal pixels scatter around the hood/head area.

Frame 5 — Terkapar Telungkup / Face-Down (Lying Flat):
Character fully prone. Figure occupies only the bottom 12-14 rows of the 32×48 frame.
Top 34-36 rows completely transparent. Character is horizontal across the 32-pixel width.
Face pressed to ground — not visible. Back of hood faces upward. Satchel at the hip.
Back of cloak spread flat. Back-cloak dianthus flowers visible flat on the ground.
5-6 scattered pink petal pixels near the head.

Frame 6 — Posisi Kematian Sempurna (Final Death Pose):
Identical to Frame 5. Back of hood visible, same satchel, same flat back-cloak with dianthus flowers.
Additional petal pixels scattered around head and hood area (8-10 total pink pixels).
Static final frame — no further changes.
```

**Layout notes:**
- Frames 1–2: character fully occupies the 32×48 frame
- Frame 3: ~8 pixels shorter (lower in frame)
- Frame 4: crumpled pile — top 28+ rows transparent
- Frames 5–6: flat figure — top 34+ rows transparent, body in bottom 12-14 rows only

---

## Prompt 1 — Death Down (front-facing)

> **Attach:** `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` AND `player/sprites/PNG/Unarmed_Walk/player_walk_full.png` AND `player/sprites/PNG/player_idle_down.png`

```
I am attaching three reference images:
1. Full idle spritesheet (192x192, 4 rows × 6 cols of 32x48) — overall character design and palette.
2. Full walk spritesheet (192x192, same layout) — character deformation during movement.
3. Single 32x48 sprite (front-facing idle pose) — base standing pose.

Create a 6-frame ONE-SHOT DEATH animation spritesheet, front-facing direction (character falls forward, ends face-down).
Output: 192x48 PNG, 6 frames of 32x48, horizontal strip, transparent background. Does NOT loop.

Frame 1 — Initial Reaction: Fully upright. Jolts as if struck. Shoulders raise (hood lifts 1px), knees
slightly bend (legs 1px shorter), eyes slightly widen. Hood flower accents intact. Arms tense.

Frame 2 — Beginning to Fall: Still upright but losing balance. Knees bend deeper (2-3px shorter). Body
tilts slightly forward. Viewer's-right arm raises 1-2px (bracing toward fall). Hood flower accents tilt/sway.

Frame 3 — Collapsing Downward: ~8px shorter overall. Feet/boots compress upward as legs fold. Hood
covers more of the face. 1-2 stray hair pixels at hood edge. Satchel clearly visible at hip.
2-3 pink/magenta petal pixels scatter near the hood (petals detaching from flower accent).

Frame 4 — Near-Collapsed Heap (Knee-Knock): Small crumpled pile in lower ~20px of frame. Top 28+px
transparent. Hood squarish/flat at ground level, facing downward. Arms extend forward, away from viewer (bracing forward fall).
Satchel appears beside the hood. 4-6 pink petal pixels scattered around hood/head.

Frame 5 — Lying Flat Face-Down (Terkapar Telungkup): Fully prone. Bottom 12-14 rows only; top 34+px
transparent. Horizontal figure centered across 32px — head/hood on one side, boots on the other,
satchel at the hip. Face pressed to ground — not visible. Back of hood faces upward.
Back-cloak dianthus flower arrangement visible spread flat. 5-6 scattered pink petal pixels.

Frame 6 — Final Death Pose: Identical to Frame 5. Back of hood visible, same satchel, same flat
back-cloak with dianthus flowers visible. 8-10 total pink petal pixels scattered on the ground around hood.
Static final frame.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Use ONLY colors from the attached reference — do not add new colors
- Keep the 1-pixel dark outline on every frame
- Character fully within each 32x48 cell
- Satchel, hood flower accents (scattering as petals F3–F6), all clothing details preserved every frame
- Output: single PNG, exactly 192x48 pixels, transparent background, no upscaling, no smoothing
- Does NOT loop — Frame 6 is the final held pose
```

---

## Prompt 2 — Death Up (back-facing)

> **Attach:** `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` AND `player/sprites/PNG/Unarmed_Walk/player_walk_full.png` AND `player/sprites/PNG/player_idle_up.png`

```
I am attaching three reference images:
1. Full idle spritesheet (192x192, 4 rows × 6 cols of 32x48) — overall character design and palette.
2. Full walk spritesheet (192x192, same layout) — character deformation during movement.
3. Single 32x48 sprite (back-facing idle pose, facing away from camera) — base standing pose.

Create a 6-frame ONE-SHOT DEATH animation spritesheet, back-facing direction (character falls forward/face-down).
Output: 192x48 PNG, 6 frames of 32x48, horizontal strip, transparent background. Does NOT loop.

Frame 1 — Initial Reaction: Fully upright, back to camera. Back of hood jolts slightly. Shoulders raise
(hood rises ~1px). Knees slightly bend (1px shorter). Back-cloak flower arrangement intact.

Frame 2 — Beginning to Fall: Knees bend deeper (2-3px shorter). Body tilts forward (away from camera).
Cloak hem shifts. Back-cloak flower accents tilt.

Frame 3 — Collapsing Downward: ~8px shorter. Back of hood fills more of frame. Stray hair pixels at
sides of hood. Satchel strap visible. 2-3 pink petal pixels scatter near back-hood.

Frame 4 — Near-Collapsed Heap: Small pile in lower ~20px. Top 28+px transparent. Back of hood
squarish at ground level, back-cloak flower arrangement partially visible. Arms extend away from viewer.
4-6 petal pixels scattered.

Frame 5 — Lying Flat (Face-Down): Fully prone. Bottom 12-14 rows only; top 34+px transparent.
Back of hood faces upward (character face-down). Back-cloak dianthus flower arrangement spread flat,
clearly visible. Boots at opposite end. Satchel at hip. 5-6 scattered petal pixels.

Frame 6 — Final Death Pose: Identical to Frame 5. 8-10 total pink petal pixels scattered around hood
and back-cloak area. Static final frame.

Rules: Strict pixel art, no anti-aliasing, same colors only, 1px outline every frame, character within
32x48 cells, back-cloak flower arrangement preserved, no upscaling. Does NOT loop.
```

---

## Prompt 3 — Death Right (side-facing)

> **Attach:** `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` AND `player/sprites/PNG/Unarmed_Walk/player_walk_full.png` AND `player/sprites/PNG/player_idle_right.png`

```
I am attaching three reference images:
1. Full idle spritesheet (192x192, 4 rows × 6 cols of 32x48) — overall character design and palette.
2. Full walk spritesheet (192x192, same layout) — character deformation during movement.
3. Single 32x48 sprite (right-facing profile idle pose) — base standing pose.

Create a 6-frame ONE-SHOT DEATH animation spritesheet, right-facing profile (character falls to the right).
Output: 192x48 PNG, 6 frames of 32x48, horizontal strip, transparent background. Does NOT loop.

Frame 1 — Initial Reaction: Fully upright profile. Jolts. Shoulders raise (hood 1px up), knees slightly
bend (1px shorter). Satchel at hip. Hood flower accent intact in profile. Arms tense.

Frame 2 — Beginning to Fall: Knees bend deeper (2-3px shorter). Profile tilts forward/right. Front arm
raises slightly. Hood flower accent tilts. Cloak hem trails slightly.

Frame 3 — Collapsing Downward: Profile compresses ~8px shorter as legs fold. Hood lower in frame.
Satchel clearly at hip in profile. Stray hair pixel at hood edge. 2-3 petal pixels scatter.

Frame 4 — Near-Collapsed Heap (Profile): Crumpled profile pile in lower ~20px. Top 28+px transparent.
Deep crouching profile leaning heavily right. Front arm extends right. 4-6 petal pixels scattered.

Frame 5 — Lying Flat (Profile, Right Side): Fully prone. Bottom 12-14 rows only; top 34+px transparent.
Horizontal profile figure across 32px — head/hood at the left end, boots at the right end.
One eye (visible in profile) replaced with an 'X'. Satchel at hip. 5-6 scattered petal pixels.

Frame 6 — Final Death Pose: Identical to Frame 5. 8-10 total pink petal pixels scattered around head/hood.
Static final frame.

Rules: Strict pixel art, no anti-aliasing, same colors only, 1px outline every frame, character within
32x48 cells, satchel and hood flower accents (petals in F3–F6) preserved, no upscaling. Does NOT loop.
```

---

## Prompt 4 — Death Left (side-facing)

> **Attach:** `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` AND `player/sprites/PNG/Unarmed_Walk/player_walk_full.png` AND `player/sprites/PNG/player_idle_left.png`

```
I am attaching three reference images:
1. Full idle spritesheet (192x192, 4 rows × 6 cols of 32x48) — overall character design and palette.
2. Full walk spritesheet (192x192, same layout) — character deformation during movement.
3. Single 32x48 sprite (left-facing profile idle pose) — base standing pose.

Create a 6-frame ONE-SHOT DEATH animation spritesheet, left-facing profile (character falls to the left).
Output: 192x48 PNG, 6 frames of 32x48, horizontal strip, transparent background. Does NOT loop.

This is the horizontally mirrored counterpart to the right-facing death. The satchel is on the
opposite hip. The character falls to the left.

Frame 1 — Initial Reaction: Fully upright left-profile. Jolts. Shoulders raise (hood 1px up), knees
slightly bend (1px shorter). Satchel at mirrored hip. Hood flower accent intact. Arms tense.

Frame 2 — Beginning to Fall: Knees bend deeper (2-3px shorter). Profile tilts forward/left. Front arm
raises slightly. Hood flower accent tilts.

Frame 3 — Collapsing Downward: Profile compresses ~8px shorter. Hood lower in frame. Satchel at mirrored
hip. Stray hair pixel at hood edge. 2-3 petal pixels scatter.

Frame 4 — Near-Collapsed Heap (Profile, Left): Crumpled left-profile pile in lower ~20px. Top 28+px
transparent. Leaning heavily left. Front arm extends left. 4-6 petal pixels scattered.

Frame 5 — Lying Flat (Profile, Left Side): Fully prone. Bottom 12-14 rows only; top 34+px transparent.
Horizontal profile figure across 32px — head/hood at the right end (mirrored), boots at the left end.
One eye (visible in profile) replaced with an 'X'. Satchel at mirrored hip. 5-6 petal pixels.

Frame 6 — Final Death Pose: Identical to Frame 5. 8-10 total pink petal pixels around head/hood.
Static final frame.

Rules: Strict pixel art, no anti-aliasing, same colors only, 1px outline every frame, character within
32x48 cells, satchel (mirrored hip) and hood flower accents (petals in F3–F6) preserved, no upscaling.
Does NOT loop.
```

---

## Bonus — Full Death Spritesheet (all 4 directions)

> **Attach:** `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` AND `player/sprites/PNG/Unarmed_Walk/player_walk_full.png`

```
I am attaching two reference images:
1. A 192x192 pixel art idle spritesheet (4 rows × 6 cols of 32x48 — R1: down, R2: right, R3: up, R4: left).
2. A 192x192 pixel art walk spritesheet (same layout) — for motion deformation reference.

Create a ONE-SHOT DEATH animation spritesheet: 192x192 PNG, 4 rows × 6 columns, 32x48 cells,
transparent background. Does NOT loop. Column 6 (rightmost) of every row is the final death pose.

Row 1 (Down/front): character falls forward → ends face-down (back of hood visible, back-cloak flowers spread flat)
Row 2 (Right/profile): falls right → ends lying on right side (profile, head left, boots right)
Row 3 (Up/back): falls forward → ends face-down (back of cloak and flowers visible flat)
Row 4 (Left/profile): falls left → ends lying on left side (mirrored of Row 2)

Per-row death arc (6 frames):
F1: Jolt upright — shoulders raised (1px), knees bent (1px), eyes widen, hood flower intact
F2: Begin collapse — knees deeper (2-3px shorter), body tilts, viewer's-right arm braces, flower sways
F3: Collapse — ~8px shorter, hood covers face, stray hair, satchel visible, 2-3 petal pixels scatter
F4: Near-ground heap — crumpled pile bottom 20px, top 28+px transparent, hood at floor, arms extend, 4-6 petals
F5: Flat on ground — horizontal figure bottom 12-14px, top 34+px transparent, satchel at hip,
    cloak flat (back-flower arrangement visible in Rows 1 and 3; face hidden/face-down in R1+R3;
    X eye visible in side-profile R2+R4), 5-6 petal pixels
F6: Final death — identical to F5, 8-10 total pink petal pixels around head/hood. Static.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Same colors only — do not add new colors
- 1-pixel dark outline every frame, character within each 32x48 cell
- Satchel, hood flower accents (scattering as petals F3–F6), all clothing details preserved
- Output: single PNG, exactly 192x192 pixels, transparent background, no upscaling, no smoothing
- Does NOT loop — Column 6 of every row is the final held dead pose
```

---

## Compact Fallback Prompts

### Compact — Death Down
```
Using the attached 32x48 pixel art sprite (front-facing idle) and both full spritesheets as reference,
create a 6-frame ONE-SHOT death animation spritesheet. 192x48 PNG (6 cells of 32x48), horizontal strip,
transparent background, strict pixel art, no anti-aliasing. Arc: F1=jolt upright, F2=begin collapse
(knees bend), F3=~8px shorter + satchel visible + 2-3 petal pixels, F4=kneeling heap bottom 20px +
4-6 petals, F5=lying flat face-down bottom 12-14px + back of hood up + back-cloak flowers visible + 5-6 petals,
F6=same + 8-10 total petals. NOT looping. Same colors only. No upscaling.
```

### Compact — Death Up
```
Using the attached 32x48 pixel art sprite (back-facing idle) and both full spritesheets as reference,
create a 6-frame ONE-SHOT death animation spritesheet. 192x48 PNG (6 cells of 32x48), horizontal strip,
transparent background, strict pixel art, no anti-aliasing. Arc: F1=jolt upright back-view, F2=begin
fall forward, F3=~8px shorter + back-cloak visible + 2-3 petals, F4=heap bottom 20px back-of-hood down
+ 4-6 petals, F5=lying face-down bottom 12-14px + back-cloak flowers flat + 5-6 petals, F6=same +
8-10 total petals. NOT looping. Same colors only. No upscaling.
```

### Compact — Death Right
```
Using the attached 32x48 pixel art sprite (right-facing profile idle) and both full spritesheets as
reference, create a 6-frame ONE-SHOT death animation spritesheet. 192x48 PNG (6 cells of 32x48),
horizontal strip, transparent background, strict pixel art, no anti-aliasing. Arc: F1=jolt upright
profile, F2=begin fall right, F3=~8px shorter + satchel + 2-3 petals, F4=crumpled profile heap
bottom 20px + 4-6 petals, F5=lying profile right-side bottom 12-14px (head left, boots right) +
X eye + 5-6 petals, F6=same + 8-10 total petals. NOT looping. Same colors only. No upscaling.
```

### Compact — Death Left
```
Using the attached 32x48 pixel art sprite (left-facing profile idle) and both full spritesheets as
reference, create a 6-frame ONE-SHOT death animation spritesheet. 192x48 PNG (6 cells of 32x48),
horizontal strip, transparent background, strict pixel art, no anti-aliasing. Arc: F1=jolt upright
left-profile, F2=begin fall left, F3=~8px shorter + satchel mirrored + 2-3 petals, F4=crumpled
profile heap bottom 20px + 4-6 petals, F5=lying profile left-side bottom 12-14px (head right,
boots left) + X eye + 5-6 petals, F6=same + 8-10 total petals. NOT looping. Same colors only.
No upscaling.
```

### Compact — Full Sheet (all 4 directions)
```
Using the attached 192x192 idle + walk spritesheets as reference, create a ONE-SHOT DEATH animation
spritesheet: 192x192 PNG, 4 rows × 6 cols of 32x48, transparent background. R1=death down (falls forward,
face-down, back of hood up, back-cloak flowers flat), R2=death right (falls right, lying right-side profile),
R3=death up (falls forward, face-down, back-cloak flowers flat), R4=death left (falls left, lying
left-side profile, mirrored R2). Per-row arc: F1=jolt, F2=begin collapse, F3=~8px shorter + 2-3 petals,
F4=heap bottom 20px + 4-6 petals, F5=flat bottom 12-14px + X eyes + 5-6 petals, F6=same + 8-10 petals.
NOT looping. Strict pixel art, same colors only, no anti-aliasing, no upscaling.
```

---

## Usage Notes

- Save output spritesheets as:
  - `player/sprites/PNG/Unarmed_Death/player_death_down_sheet.png`
  - `player/sprites/PNG/Unarmed_Death/player_death_up_sheet.png`
  - `player/sprites/PNG/Unarmed_Death/player_death_right_sheet.png`
  - `player/sprites/PNG/Unarmed_Death/player_death_left_sheet.png`
  - Or full sheet: `player/sprites/PNG/Unarmed_Death/player_death_full.png`
- Import into Godot with **Filter = Nearest** (no interpolation).
- In `SpriteFrames`, configure the `death` animation with **6 frames** from the horizontal strip.
- Set the animation as **non-looping** in Godot's SpriteFrames or AnimationPlayer.
- Recommended playback speed: **8-10 FPS**.
- After Frame 6, trigger respawn/game-over logic in `player_controller.gd`.
- The death-left sheet can alternatively be produced by **horizontally flipping** the death-right sheet frame-by-frame, if Gemini struggles with left-facing consistency.

---

## Troubleshooting

1. **Retry after 30-60 seconds** — transient TCP resets are common with Google API endpoints.
2. **Shorten the prompt** — use the compact version if the full prompt times out.
3. **Use Gemini via browser (AI Studio)** — paste at https://aistudio.google.com.
4. **Switch model** — try `gemini-2.0-flash-exp` or `gemini-2.0-flash` if overloaded.
5. **If character doesn't collapse fully** — add: "By Frame 5, the character MUST be a HORIZONTAL figure in only the BOTTOM 12-14 pixels of the 32x48 frame. The top 34+ pixels of Frame 5 and Frame 6 must be completely transparent."
6. **If face/eyes visible in Death Down F5–F6** — add: "In Frames 5 and 6, the character is face-DOWN — the face and eyes are COMPLETELY hidden against the ground. The back of the hood faces upward. NO face, eyes, or expression should be visible." For side-profile (Death Right/Left): "The one visible profile eye MUST be replaced with a small 'X' mark in Frames 5 and 6."
7. **If no petal scatter** — add: "Pink/magenta pixels (#FF9EC8, #FF6B9D, or #E84A7F) from the hood flower MUST scatter as individual 1-2 pixel clusters in Frames 3–6. By Frame 6 there should be 8-10 pink pixels scattered around the head area."
8. **If output is wrong size** — add: "Do NOT upscale. The final PNG must be exactly 192 pixels wide and 48 pixels tall."
9. **If character is still standing in later frames** — add: "This is a DEATH animation. The character MUST end up completely horizontal (lying flat) by Frame 5. Do not keep the character standing or sitting in Frame 4, 5, or 6."
