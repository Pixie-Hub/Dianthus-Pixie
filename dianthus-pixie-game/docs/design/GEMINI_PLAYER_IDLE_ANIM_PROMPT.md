# Gemini Image Generation Prompt — Dianthus Pixie Idle Animation Spritesheets

## Overview

Generate **4 idle animation spritesheets** (one per direction) from the existing static idle frames. Each spritesheet is a single horizontal strip of **6 frames**, each frame 32×48 pixels, producing a **192×48 pixel PNG**.

**Attach the corresponding idle frame PNG as reference** when sending each prompt to Gemini.

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

The idle animation is a subtle **breathing / gentle sway** cycle. Changes between frames are minimal — only 1-2 pixels shift per frame. The character should feel alive but calm.

```
Frame 1: Base pose (identical to the attached reference idle frame)
Frame 2: Slight chest rise — torso shifts up by 1 pixel (breathing in). Hood and head stay in place.
Frame 3: Full inhale — torso still raised 1 pixel, cloak hem shifts 1 pixel outward (slight sway).
Frame 4: Base pose again (identical to frame 1) — exhale returning to rest.
Frame 5: Slight settle — torso dips 1 pixel lower than base (breathing out). Cloak hem returns.
Frame 6: Returning to base — torso halfway back up. Nearly identical to frame 1.
```

The motion is **only in the torso area (rows ~16-32)**. The head, legs, and feet remain static across all frames. Boots stay planted on the same baseline row.

---

## Prompt 1 — Idle Down (front-facing)

> **Attach:** `player/sprites/PNG/player_idle_down.png`

```
I am attaching a 32x48 pixel art character sprite (front-facing idle pose). Using this exact character as the base, create a 6-frame idle animation spritesheet.

Output: a single 192x48 pixel PNG image — 6 frames of 32x48 each, arranged in a horizontal strip, transparent background.

The animation is a subtle breathing/sway cycle. The changes between frames are tiny — only 1-2 pixels shift in the torso area. The head, legs, and boots stay completely static across all frames.

Frame 1: Identical to the attached reference image.
Frame 2: Torso area shifts up by 1 pixel (gentle inhale). Head and feet unchanged.
Frame 3: Torso still raised 1 pixel, cloak hem shifts 1 pixel outward (subtle sway).
Frame 4: Returns to the base pose (identical to frame 1).
Frame 5: Torso dips 1 pixel below base (gentle exhale). Cloak hem returns.
Frame 6: Torso halfway back to base. Nearly identical to frame 1.

The animation must loop seamlessly (frame 6 → frame 1).

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Use ONLY the exact same colors from the attached reference — do not add new colors
- Keep the 1-pixel dark outline intact on every frame
- The character must remain fully within each 32x48 cell
- Output: single PNG, exactly 192x48 pixels, transparent background, no upscaling, no smoothing
```

---

## Prompt 2 — Idle Up (back-facing)

> **Attach:** `player/sprites/PNG/player_idle_up.png`

```
I am attaching a 32x48 pixel art character sprite (back-facing idle pose, facing away from camera). Using this exact character as the base, create a 6-frame idle animation spritesheet.

Output: a single 192x48 pixel PNG image — 6 frames of 32x48 each, arranged in a horizontal strip, transparent background.

The animation is a subtle breathing/sway cycle. The changes between frames are tiny — only 1-2 pixels shift in the torso area. The head, legs, and boots stay completely static across all frames.

Frame 1: Identical to the attached reference image.
Frame 2: Torso area shifts up by 1 pixel (gentle inhale). Head and feet unchanged.
Frame 3: Torso still raised 1 pixel, cloak/hood hem shifts 1 pixel outward (subtle sway).
Frame 4: Returns to the base pose (identical to frame 1).
Frame 5: Torso dips 1 pixel below base (gentle exhale).
Frame 6: Torso halfway back to base. Nearly identical to frame 1.

The animation must loop seamlessly (frame 6 → frame 1).

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Use ONLY the exact same colors from the attached reference — do not add new colors
- Keep the 1-pixel dark outline intact on every frame
- The character must remain fully within each 32x48 cell
- Output: single PNG, exactly 192x48 pixels, transparent background, no upscaling, no smoothing
```

---

## Prompt 3 — Idle Right (side-facing)

> **Attach:** `player/sprites/PNG/player_idle_right.png`

```
I am attaching a 32x48 pixel art character sprite (right-facing profile idle pose). Using this exact character as the base, create a 6-frame idle animation spritesheet.

Output: a single 192x48 pixel PNG image — 6 frames of 32x48 each, arranged in a horizontal strip, transparent background.

The animation is a subtle breathing/sway cycle. The changes between frames are tiny — only 1-2 pixels shift in the torso area. The head, legs, and boots stay completely static across all frames.

Frame 1: Identical to the attached reference image.
Frame 2: Torso area shifts up by 1 pixel (gentle inhale). Head and feet unchanged.
Frame 3: Torso still raised 1 pixel, cloak back edge shifts 1 pixel outward (subtle sway).
Frame 4: Returns to the base pose (identical to frame 1).
Frame 5: Torso dips 1 pixel below base (gentle exhale). Cloak returns.
Frame 6: Torso halfway back to base. Nearly identical to frame 1.

The animation must loop seamlessly (frame 6 → frame 1).

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Use ONLY the exact same colors from the attached reference — do not add new colors
- Keep the 1-pixel dark outline intact on every frame
- The character must remain fully within each 32x48 cell
- Output: single PNG, exactly 192x48 pixels, transparent background, no upscaling, no smoothing
```

---

## Prompt 4 — Idle Left (side-facing)

> **Attach:** `player/sprites/PNG/player_idle_left.png`

```
I am attaching a 32x48 pixel art character sprite (left-facing profile idle pose). Using this exact character as the base, create a 6-frame idle animation spritesheet.

Output: a single 192x48 pixel PNG image — 6 frames of 32x48 each, arranged in a horizontal strip, transparent background.

The animation is a subtle breathing/sway cycle. The changes between frames are tiny — only 1-2 pixels shift in the torso area. The head, legs, and boots stay completely static across all frames.

Frame 1: Identical to the attached reference image.
Frame 2: Torso area shifts up by 1 pixel (gentle inhale). Head and feet unchanged.
Frame 3: Torso still raised 1 pixel, cloak back edge shifts 1 pixel outward (subtle sway).
Frame 4: Returns to the base pose (identical to frame 1).
Frame 5: Torso dips 1 pixel below base (gentle exhale). Cloak returns.
Frame 6: Torso halfway back to base. Nearly identical to frame 1.

The animation must loop seamlessly (frame 6 → frame 1).

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Use ONLY the exact same colors from the attached reference — do not add new colors
- Keep the 1-pixel dark outline intact on every frame
- The character must remain fully within each 32x48 cell
- Output: single PNG, exactly 192x48 pixels, transparent background, no upscaling, no smoothing
```

---

## Compact Fallback Prompts

If Gemini times out, use these shorter versions (still attach the reference image):

### Compact — Idle Down
```
Using the attached 32x48 pixel art sprite as the exact base, create a 6-frame idle breathing animation spritesheet. 192x48 PNG (6 cells of 32x48), horizontal strip, transparent background, strict pixel art, no anti-aliasing. Only 1-2 pixel shifts in the torso area per frame — head and feet stay static. Seamless loop. Same colors only. No upscaling.
```

### Compact — Idle Up
```
Using the attached 32x48 pixel art sprite (back-facing) as the exact base, create a 6-frame idle breathing animation spritesheet. 192x48 PNG (6 cells of 32x48), horizontal strip, transparent background, strict pixel art, no anti-aliasing. Only 1-2 pixel shifts in the torso area per frame — head and feet stay static. Seamless loop. Same colors only. No upscaling.
```

### Compact — Idle Right
```
Using the attached 32x48 pixel art sprite (right-facing profile) as the exact base, create a 6-frame idle breathing animation spritesheet. 192x48 PNG (6 cells of 32x48), horizontal strip, transparent background, strict pixel art, no anti-aliasing. Only 1-2 pixel shifts in the torso area per frame — head and feet stay static. Seamless loop. Same colors only. No upscaling.
```

### Compact — Idle Left
```
Using the attached 32x48 pixel art sprite (left-facing profile) as the exact base, create a 6-frame idle breathing animation spritesheet. 192x48 PNG (6 cells of 32x48), horizontal strip, transparent background, strict pixel art, no anti-aliasing. Only 1-2 pixel shifts in the torso area per frame — head and feet stay static. Seamless loop. Same colors only. No upscaling.
```

---

## Usage Notes

- Save output spritesheets as:
  - `player/sprites/PNG/player_idle_down_sheet.png`
  - `player/sprites/PNG/player_idle_up_sheet.png`
  - `player/sprites/PNG/player_idle_right_sheet.png`
  - `player/sprites/PNG/player_idle_left_sheet.png`
- Import into Godot with **Filter = Nearest** (no interpolation).
- In `SpriteFrames`, configure each animation with **6 frames** from the horizontal strip.
- Recommended playback speed: **6 FPS** (each full breathing cycle = 1 second).
- The idle-left sheet can alternatively be produced by horizontally flipping the idle-right sheet frame-by-frame, if Gemini struggles with left-facing consistency.

## Troubleshooting

1. **Retry after 30-60 seconds** — transient TCP resets are common with Google API endpoints.
2. **Shorten the prompt** — use the compact version if the full prompt times out.
3. **Use Gemini via browser (AI Studio)** — paste the prompt at https://aistudio.google.com instead of API calls.
4. **Switch model** — try `gemini-2.0-flash-exp` or `gemini-2.0-flash` if the default model is overloaded.
5. **If frames look too different from reference** — re-emphasize "Frame 1 must be pixel-identical to the attached image" and "only 1-2 pixel changes per frame in the torso region".
6. **If output is wrong size** — add "Do NOT upscale. The final PNG must be exactly 192 pixels wide and 48 pixels tall." at the end of the prompt.
