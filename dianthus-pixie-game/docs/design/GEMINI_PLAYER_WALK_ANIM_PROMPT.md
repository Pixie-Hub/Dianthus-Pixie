# Gemini Image Generation Prompt — Dianthus Pixie Walk Animation Spritesheets

## Overview

Generate **4 walking animation spritesheets** (one per direction) from the existing idle spritesheet. Each spritesheet is a single horizontal strip of **6 frames**, each frame 32×48 pixels, producing a **192×48 pixel PNG**.

**Attach the full idle spritesheet** (`player/sprites/PNG/Unarmed_Idle/player_idle_full.png`) **and the corresponding single-direction idle frame** when sending each prompt to Gemini.

---

## Style Rules (all directions)

```
- Strict pixel art — no anti-aliasing, no gradients, no soft edges, no sub-pixel rendering
- Each frame is exactly 32 pixels wide × 48 pixels tall
- 6 frames arranged in a single horizontal strip → total image size: 192×48 pixels
- Transparent background — no solid background color
- Limited palette: same 8-12 colors as the reference image (do not introduce new colors)
- 1-pixel dark outline around the character
- Output: a single PNG image, 192×48 pixels, transparent background, no upscaling, no smoothing, no filtering
- Art direction: 2D pixel art for a fantasy survival crafting game with a Southeast Asian botanical theme
- The character must be fully contained within each 32×48 cell with no cropping
- Animation must loop seamlessly (frame 6 transitions smoothly back to frame 1)
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
```

---

## Animation Description (all directions)

The walk animation is a **standard 6-frame walk cycle** with a natural stepping motion. The character should feel like they are walking at a steady, moderate pace. Key motion principles:

- **Legs** alternate stepping forward — this is the primary motion driver
- **Body bobs** up and down by 1 pixel (up on the passing position, down on the contact position)
- **Arms** swing subtly opposite to the legs (1-2 pixels of movement)
- **Hood/cloak** sways gently with the movement (1 pixel trailing motion)
- **Head** stays mostly stable, only shifting with the body bob

```
Frame 1: Contact pose — left foot forward, right foot back. Body at lowest point (contact).
         Arms in opposite position to legs. Cloak neutral.
Frame 2: Recoil/Down — weight shifts onto left foot, right foot lifts off ground.
         Body still at low point. Rear arm swings slightly forward.
Frame 3: Passing — right leg passes under body moving forward. Body rises 1 pixel (highest point).
         Arms near center. Cloak trails slightly behind.
Frame 4: Contact pose — right foot forward, left foot back (mirror of frame 1).
         Body at lowest point again. Arms swapped from frame 1.
Frame 5: Recoil/Down — weight shifts onto right foot, left foot lifts off ground.
         Body still at low point. Rear arm swings slightly forward.
Frame 6: Passing — left leg passes under body moving forward. Body rises 1 pixel (highest point).
         Arms near center. Cloak trails slightly behind.
```

The feet should show clear stepping motion (2-3 pixels of stride). Boots stay grounded on the same baseline row during contact frames.

---

## Prompt 1 — Walk Down (front-facing)

> **Attach:** `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` (full idle spritesheet for overall character reference) AND `player/sprites/PNG/Unarmed_Idle/player_idle_down.png` (front-facing idle frame as the base pose)

```
I am attaching two reference images:
1. A full idle animation spritesheet (192x192, 4 rows × 6 columns of 32x48 frames) showing the character in all 4 directions — use this to understand the character's overall design, proportions, and color palette.
2. A single 32x48 pixel art character sprite (front-facing idle pose) — use this as the base design for the walk animation.

Create a 6-frame WALKING animation spritesheet for the front-facing (walking downward/toward camera) direction.

Output: a single 192x48 pixel PNG image — 6 frames of 32x48 each, arranged in a horizontal strip, transparent background.

The animation is a standard walk cycle with clear leg movement, subtle body bob, and gentle arm swing:

Frame 1: Contact pose — left foot steps forward (2-3 pixels ahead of base), right foot back. Body at base height. Left arm back, right arm slightly forward. Cloak neutral.
Frame 2: Weight shifts onto front foot, back foot begins lifting. Body stays at base height. Arms begin swapping.
Frame 3: Passing position — back leg swings forward passing under body. Body rises 1 pixel (highest point). Arms near center position. Hood/cloak sways 1 pixel.
Frame 4: Contact pose — right foot steps forward (mirror of frame 1). Body returns to base height. Right arm back, left arm slightly forward.
Frame 5: Weight shifts onto front foot, back foot begins lifting. Body stays at base height. Arms begin swapping.
Frame 6: Passing position — back leg swings forward passing under body. Body rises 1 pixel. Arms near center. Hood/cloak sways 1 pixel opposite to frame 3.

The animation must loop seamlessly (frame 6 → frame 1). The walk should look natural and rhythmic.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Use ONLY the exact same colors from the attached reference — do not add new colors
- Keep the 1-pixel dark outline intact on every frame
- The character must remain fully within each 32x48 cell
- Maintain the same character proportions, clothing details, and design as the reference
- The satchel, hood flower accents, and all clothing details must be preserved in every frame
- Output: single PNG, exactly 192x48 pixels, transparent background, no upscaling, no smoothing
```

---

## Prompt 2 — Walk Up (back-facing)

> **Attach:** `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` (full idle spritesheet) AND `player/sprites/PNG/Unarmed_Idle/player_idle_up.png` (back-facing idle frame)

```
I am attaching two reference images:
1. A full idle animation spritesheet (192x192, 4 rows × 6 columns of 32x48 frames) showing the character in all 4 directions — use this to understand the character's overall design, proportions, and color palette.
2. A single 32x48 pixel art character sprite (back-facing idle pose, facing away from camera) — use this as the base design for the walk animation.

Create a 6-frame WALKING animation spritesheet for the back-facing (walking upward/away from camera) direction.

Output: a single 192x48 pixel PNG image — 6 frames of 32x48 each, arranged in a horizontal strip, transparent background.

The animation is a standard walk cycle with clear leg movement, subtle body bob, and gentle arm swing:

Frame 1: Contact pose — left foot steps forward (2-3 pixels ahead of base), right foot back. Body at base height. Arms in opposite position to legs. Cloak hangs naturally.
Frame 2: Weight shifts onto front foot, back foot begins lifting. Body stays at base height. Arms begin swapping.
Frame 3: Passing position — back leg swings forward passing under body. Body rises 1 pixel (highest point). Arms near center position. Cloak/hood hem sways 1 pixel.
Frame 4: Contact pose — right foot steps forward (mirror of frame 1). Body returns to base height. Arms swapped from frame 1.
Frame 5: Weight shifts onto front foot, back foot begins lifting. Body stays at base height. Arms begin swapping.
Frame 6: Passing position — back leg swings forward passing under body. Body rises 1 pixel. Arms near center. Cloak/hood sways 1 pixel opposite to frame 3.

The animation must loop seamlessly (frame 6 → frame 1). Since this is the back view, the cloak and hood are the most visible elements — ensure the cloak's trailing motion is clear.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Use ONLY the exact same colors from the attached reference — do not add new colors
- Keep the 1-pixel dark outline intact on every frame
- The character must remain fully within each 32x48 cell
- Maintain the same character proportions, clothing details, and design as the reference
- The hood, cloak back, and all clothing details must be preserved in every frame
- Output: single PNG, exactly 192x48 pixels, transparent background, no upscaling, no smoothing
```

---

## Prompt 3 — Walk Right (side-facing)

> **Attach:** `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` (full idle spritesheet) AND `player/sprites/PNG/Unarmed_Idle/player_idle_right.png` (right-facing idle frame)

```
I am attaching two reference images:
1. A full idle animation spritesheet (192x192, 4 rows × 6 columns of 32x48 frames) showing the character in all 4 directions — use this to understand the character's overall design, proportions, and color palette.
2. A single 32x48 pixel art character sprite (right-facing profile idle pose) — use this as the base design for the walk animation.

Create a 6-frame WALKING animation spritesheet for the right-facing (walking rightward) direction.

Output: a single 192x48 pixel PNG image — 6 frames of 32x48 each, arranged in a horizontal strip, transparent background.

The animation is a standard walk cycle with clear leg movement, subtle body bob, and arm swing. In profile view, the stride and arm swing are most visible:

Frame 1: Contact pose — front foot (right) extended forward 2-3 pixels, back foot (left) extended behind. Body at base height. Front arm swings back, back arm swings forward. Cloak trails behind naturally.
Frame 2: Weight shifts onto front foot, back foot lifts. Body at base height. Arms begin returning toward center.
Frame 3: Passing position — back leg swings forward passing under body. Body rises 1 pixel (highest point). Both arms near center. Cloak billows slightly behind (1 pixel).
Frame 4: Contact pose — feet swap (left foot forward, right foot back — mirror of frame 1). Body at base height. Arms swapped from frame 1. Cloak settles.
Frame 5: Weight shifts onto front foot, back foot lifts. Body at base height. Arms begin returning toward center.
Frame 6: Passing position — back leg swings forward. Body rises 1 pixel. Arms near center. Cloak billows slightly behind (1 pixel).

The animation must loop seamlessly (frame 6 → frame 1). The side profile should show the most visible stride — feet clearly stepping forward and back. The satchel at the hip should bounce subtly with the walk.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Use ONLY the exact same colors from the attached reference — do not add new colors
- Keep the 1-pixel dark outline intact on every frame
- The character must remain fully within each 32x48 cell
- Maintain the same character proportions, clothing details, and design as the reference
- The satchel, hood flower accents, cloak profile, and all clothing details must be preserved in every frame
- Output: single PNG, exactly 192x48 pixels, transparent background, no upscaling, no smoothing
```

---

## Prompt 4 — Walk Left (side-facing)

> **Attach:** `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` (full idle spritesheet) AND `player/sprites/PNG/Unarmed_Idle/player_idle_left.png` (left-facing idle frame)

```
I am attaching two reference images:
1. A full idle animation spritesheet (192x192, 4 rows × 6 columns of 32x48 frames) showing the character in all 4 directions — use this to understand the character's overall design, proportions, and color palette.
2. A single 32x48 pixel art character sprite (left-facing profile idle pose) — use this as the base design for the walk animation.

Create a 6-frame WALKING animation spritesheet for the left-facing (walking leftward) direction.

Output: a single 192x48 pixel PNG image — 6 frames of 32x48 each, arranged in a horizontal strip, transparent background.

The animation is a standard walk cycle with clear leg movement, subtle body bob, and arm swing. In profile view, the stride and arm swing are most visible:

Frame 1: Contact pose — front foot (left) extended forward 2-3 pixels, back foot (right) extended behind. Body at base height. Front arm swings back, back arm swings forward. Cloak trails behind naturally.
Frame 2: Weight shifts onto front foot, back foot lifts. Body at base height. Arms begin returning toward center.
Frame 3: Passing position — back leg swings forward passing under body. Body rises 1 pixel (highest point). Both arms near center. Cloak billows slightly behind (1 pixel).
Frame 4: Contact pose — feet swap (right foot forward, left foot back — mirror of frame 1). Body at base height. Arms swapped from frame 1. Cloak settles.
Frame 5: Weight shifts onto front foot, back foot lifts. Body at base height. Arms begin returning toward center.
Frame 6: Passing position — back leg swings forward. Body rises 1 pixel. Arms near center. Cloak billows slightly behind (1 pixel).

The animation must loop seamlessly (frame 6 → frame 1). This is a horizontally mirrored version of the right-facing walk — the satchel should now appear on the opposite hip side.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Use ONLY the exact same colors from the attached reference — do not add new colors
- Keep the 1-pixel dark outline intact on every frame
- The character must remain fully within each 32x48 cell
- Maintain the same character proportions, clothing details, and design as the reference
- The satchel, hood flower accents, cloak profile, and all clothing details must be preserved in every frame
- Output: single PNG, exactly 192x48 pixels, transparent background, no upscaling, no smoothing
```

---

## Bonus — Full Walk Spritesheet (all 4 directions)

If you want to generate all 4 directions in a single image (matching the layout of `player_idle_full.png`):

> **Attach:** `player/sprites/PNG/Unarmed_Idle/player_idle_full.png`

```
I am attaching a 192x192 pixel art idle animation spritesheet. It contains 4 rows × 6 columns of 32x48 pixel frames showing a character in 4 directions (Row 1: facing down, Row 2: facing right, Row 3: facing up, Row 4: facing left). Each row has 6 idle animation frames.

Using this exact character design, colors, proportions, and style, create a WALKING animation spritesheet with the same layout: 192x192 pixels, 4 rows × 6 columns, each cell 32x48 pixels, transparent background.

Each row should be a 6-frame walk cycle for that direction:
- Row 1 (Down/front-facing walk): clear forward leg stepping toward camera, body bob, subtle arm swing
- Row 2 (Right/profile walk): visible stride with legs stepping right, arm swing, cloak trailing left
- Row 3 (Up/back-facing walk): legs stepping away from camera, cloak sway visible from behind
- Row 4 (Left/profile walk): visible stride with legs stepping left, arm swing, cloak trailing right

Walk cycle per row:
Frame 1: Contact — left foot forward, right foot back, body at base height
Frame 2: Recoil — weight on front foot, back foot lifts, body at base height
Frame 3: Passing — back leg swings forward, body rises 1 pixel (highest), arms center
Frame 4: Contact — right foot forward (mirror of frame 1), body at base height
Frame 5: Recoil — weight on front foot, back foot lifts, body at base height
Frame 6: Passing — back leg swings forward, body rises 1 pixel, arms center

Each row must loop seamlessly (frame 6 → frame 1). The walk should look natural — clear leg stride of 2-3 pixels, 1-pixel body bob, subtle arm swing and cloak sway.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Use ONLY the exact same colors from the attached reference — do not add new colors
- Keep the 1-pixel dark outline intact on every frame
- Each character must remain fully within its 32x48 cell
- Maintain identical character design, proportions, and details across all directions and frames
- The satchel, hood flower accents, and all clothing details must be preserved
- Output: single PNG, exactly 192x192 pixels, transparent background, no upscaling, no smoothing
```

---

## Compact Fallback Prompts

If Gemini times out, use these shorter versions (still attach both reference images):

### Compact — Walk Down
```
Using the attached 32x48 pixel art sprite (front-facing) and the full idle spritesheet as reference, create a 6-frame walking animation spritesheet. 192x48 PNG (6 cells of 32x48), horizontal strip, transparent background, strict pixel art, no anti-aliasing. Walk cycle: alternating leg steps (2-3 pixel stride), 1-pixel body bob up on passing frames, subtle arm swing, cloak sway. Seamless loop. Same colors only. No upscaling.
```

### Compact — Walk Up
```
Using the attached 32x48 pixel art sprite (back-facing) and the full idle spritesheet as reference, create a 6-frame walking animation spritesheet. 192x48 PNG (6 cells of 32x48), horizontal strip, transparent background, strict pixel art, no anti-aliasing. Walk cycle: alternating leg steps (2-3 pixel stride), 1-pixel body bob up on passing frames, subtle arm swing, cloak/hood sway from behind. Seamless loop. Same colors only. No upscaling.
```

### Compact — Walk Right
```
Using the attached 32x48 pixel art sprite (right-facing profile) and the full idle spritesheet as reference, create a 6-frame walking animation spritesheet. 192x48 PNG (6 cells of 32x48), horizontal strip, transparent background, strict pixel art, no anti-aliasing. Walk cycle: clear stride with legs stepping forward/back (2-3 pixels), 1-pixel body bob, arm swing, cloak trails behind. Seamless loop. Same colors only. No upscaling.
```

### Compact — Walk Left
```
Using the attached 32x48 pixel art sprite (left-facing profile) and the full idle spritesheet as reference, create a 6-frame walking animation spritesheet. 192x48 PNG (6 cells of 32x48), horizontal strip, transparent background, strict pixel art, no anti-aliasing. Walk cycle: clear stride with legs stepping forward/back (2-3 pixels), 1-pixel body bob, arm swing, cloak trails behind. Seamless loop. Same colors only. No upscaling.
```

### Compact — Full Sheet (all 4 directions)
```
Using the attached 192x192 idle spritesheet (4 rows × 6 cols of 32x48 frames) as exact reference, create a WALKING animation spritesheet with same layout: 192x192 PNG, 4 rows × 6 columns, 32x48 cells, transparent background. Row 1=walk down, Row 2=walk right, Row 3=walk up, Row 4=walk left. 6-frame walk cycle per row: alternating leg steps (2-3 pixel stride), 1-pixel body bob, arm swing, cloak sway. Seamless loop per row. Strict pixel art, same colors only, no anti-aliasing, no upscaling.
```

---

## Usage Notes

- Save output spritesheets as:
  - `player/sprites/PNG/Unarmed_Walk/player_walk_down_sheet.png`
  - `player/sprites/PNG/Unarmed_Walk/player_walk_up_sheet.png`
  - `player/sprites/PNG/Unarmed_Walk/player_walk_right_sheet.png`
  - `player/sprites/PNG/Unarmed_Walk/player_walk_left_sheet.png`
  - Or full sheet: `player/sprites/PNG/Unarmed_Walk/player_walk_full.png`
- Import into Godot with **Filter = Nearest** (no interpolation).
- In `SpriteFrames`, configure each animation with **6 frames** from the horizontal strip.
- Recommended playback speed: **8-10 FPS** (slightly faster than idle to convey movement).
- The walk-left sheet can alternatively be produced by **horizontally flipping** the walk-right sheet frame-by-frame, if Gemini struggles with left-facing consistency.

## Troubleshooting

1. **Retry after 30-60 seconds** — transient TCP resets are common with Google API endpoints.
2. **Shorten the prompt** — use the compact version if the full prompt times out.
3. **Use Gemini via browser (AI Studio)** — paste the prompt at https://aistudio.google.com instead of API calls.
4. **Switch model** — try `gemini-2.0-flash-exp` or `gemini-2.0-flash` if the default model is overloaded.
5. **If frames look too different from reference** — re-emphasize "Maintain the exact same character design, proportions, and colors as the reference" and "only the legs, arms, and body height should change between frames".
6. **If output is wrong size** — add "Do NOT upscale. The final PNG must be exactly 192 pixels wide and 48 pixels tall." at the end of the prompt.
7. **If legs don't show clear stepping** — add "The feet MUST show clear forward/backward stepping motion of 2-3 pixels per stride. This is a walk, not an idle."
8. **If character slides instead of walks** — emphasize "Each contact frame should show one foot clearly ahead of the other with a visible gap between them."
