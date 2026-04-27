# Gemini Image Generation Prompt — Dianthus Pixie Sword Attack Animation Spritesheets

## Overview

Generate **4 sword attack animation spritesheets** (one per direction) for the Dianthus Pixie player character wielding the **Thorn Sword / Blazeblade**. Each spritesheet is a single horizontal strip of **8 frames**, each frame **64×64 pixels**, producing a **512×64 pixel PNG**.

**This is a ONE-SHOT animation — it does NOT loop.** Frame 8 is the end of the recovery pose, which should transition cleanly back to the idle stance.

**Attach the reference spritesheet** (`player/sprites/PNG/Sword_attack/Sword_attack_full.png`) **AND the full idle spritesheet** (`player/sprites/PNG/Unarmed_Idle/player_idle_full.png`) when sending each prompt to Gemini.

---

## Reference Spritesheet Analysis

The attached `Sword_attack_full.png` is a **512×256 pixel** composite reference (4 rows × 8 columns, each cell 64×64 pixels). It uses a generic placeholder character. You must **replace the generic character with the Dianthus Pixie character** (hooded cloak, green hood with pink/magenta Dianthus flower accents, cream tunic, leather satchel, earthy trousers, dark boots) while **replicating the exact same motion arc, body lean, sword angle, and swing path in each corresponding frame**.

### Motion arc summary (applies to ALL directions):

```
Frame 1: Neutral stance — character holds sword at rest, facing the attack direction. Slight alert posture.
Frame 2: Windup — sword arm pulls back/up. Body leans into the wind-up. Opposite arm stabilizes.
Frame 3: Windup peak — sword is fully raised/drawn back at maximum pull. Body coiled. Feet planted.
Frame 4: Attack release — sword begins sweeping forward in a wide arc. Body lunges into the strike.
          ** HITBOX ACTIVE (frames 4–7) **
Frame 5: Mid-swing — sword at the midpoint of the arc. Body fully extended into the swing.
          The sword's sweep trail/arc flash is most prominent here. ** HITBOX ACTIVE **
Frame 6: Swing continues — sword past center, nearing the end of the arc. ** HITBOX ACTIVE **
Frame 7: Swing completion — sword reaches end of arc. Body still extended. ** HITBOX ACTIVE **
Frame 8: Recovery — body returns toward neutral. Sword lowers back to rest. Momentum settling.
```

**Sword arc flash (frames 4–7):** A white/light-grey semi-transparent arc trail should be visible sweeping in a wide radius around the character — matching the white circular slash effect visible in the reference sheet on frames 4–7. The arc is broadest on frame 5.

---

## Style Rules (all directions)

```
- Strict pixel art — no anti-aliasing, no gradients, no soft edges, no sub-pixel rendering
- Each frame is exactly 64 pixels wide × 64 pixels tall
- 8 frames arranged in a single horizontal strip → total image size: 512×64 pixels
- Transparent background — no solid background color
- Limited palette: same colors as the idle reference image + steel/silver for the sword blade
- 1-pixel dark outline around the character and sword
- Output: a single PNG image, 512×64 pixels, transparent background, no upscaling, no smoothing, no filtering
- Art direction: 2D pixel art for a fantasy survival crafting game with a Southeast Asian botanical theme
- The character must be fully contained within each 64×64 cell with no cropping
- This animation does NOT loop — Frame 8 transitions back to idle
```

---

## Color Palette (must match reference exactly, plus sword colors)

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
- Sword blade: steel silver (#C8D8E8, #A0B8C8), edge highlight (#E8F0F8)
- Sword handle/guard: dark brown (#3D2A18), gold accent (#C89030)
- Sword arc trail / swing flash: white (#FFFFFF) or near-white (#F0F4FF), semi-opaque pixels scattered in arc shape
```

---

## Sword Design — Thorn Sword / Blazeblade

```
The sword is a short one-handed sword with a slightly curved blade. The blade features thorn-like serrations along the spine.
- Thorn Sword: steel-silver blade with dark thorn notches along the back edge, brown leather-wrapped handle
- Blazeblade (upgrade): same silhouette but blade has warm orange/amber highlights (#C86020, #E88030) along the edge — like heat shimmer on the steel. Still the same handle.
- The sword fits within the 64×64 cell even when fully extended during the swing arc
- The sword arc trail (frames 4–7) is a sweeping white/light arc of 3–5 scattered pixels along the blade's path, curved in a broad semicircle around the character
```

---

## Prompt 1 — Attack Down (front-facing)

> **Attach:** `player/sprites/PNG/Sword_attack/Sword_attack_full.png` (motion reference — row 1 is attack-down) AND `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` (character design reference)

```
I am attaching two reference images:
1. A sword attack animation spritesheet (512x256, 4 rows × 8 columns of 64x64 frames). Row 1 (top row) shows the attack-down direction. Use this ONLY as a motion/pose reference — the character body pose, sword angle, and arc path in each frame.
2. A full idle spritesheet (192x192, 4 rows × 6 cols of 32x48) showing the Dianthus Pixie character design — hooded cloak with green hood and pink Dianthus flower accents, cream tunic, leather satchel, earthy trousers, dark boots.

Create an 8-frame ONE-SHOT SWORD ATTACK animation spritesheet, front-facing (attacking downward/toward camera).
Output: 512x64 PNG, 8 frames of 64x64, horizontal strip, transparent background. Does NOT loop.

Use EXACTLY the same body poses and sword motion as Row 1 of the reference spritesheet, but draw the Dianthus Pixie character (green hood, pink flower accents, cream tunic, satchel, earthy trousers, dark boots) instead of the generic placeholder character.

The sword is a short one-handed sword with a slightly curved steel-silver blade and thorn notches along the spine. Draw a white pixel arc trail sweeping in a broad semicircle on frames 4–7 (the hitbox-active frames).

Frame 1: Neutral/alert stance facing downward. Sword held at side, ready. Both feet planted.
Frame 2: Wind-up — sword arm raises up and back. Body leans back slightly. Hood flower accents intact.
Frame 3: Wind-up peak — sword pulled fully back overhead or behind. Maximum coil. Body tensed.
Frame 4: Attack release — sword sweeps down-forward in a wide arc. Body lunges forward. Arc trail begins (2-3 white pixels).
Frame 5: Mid-swing — sword at widest point of arc, crossing in front of the body. Arc trail most prominent (4-5 white pixels in curved line). Body fully extended.
Frame 6: Swing continues past center. Arc trail still visible (3-4 white pixels). Body weight shifting.
Frame 7: Swing end — sword reaches the far side of the arc. Trail fading (2-3 white pixels). Body momentum finishing.
Frame 8: Recovery — sword lowers back toward resting position. Body straightening. No arc trail.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Use ONLY colors from the attached idle reference plus steel-silver for the sword and white for the arc trail
- Keep the 1-pixel dark outline intact on every frame
- Character and sword must remain fully within each 64x64 cell
- The Dianthus flower accent on the hood, satchel, and all clothing details must be preserved in every frame
- Output: single PNG, exactly 512x64 pixels, transparent background, no upscaling, no smoothing
- Does NOT loop — Frame 8 ends the attack and returns toward idle
```

---

## Prompt 2 — Attack Up (back-facing)

> **Attach:** `player/sprites/PNG/Sword_attack/Sword_attack_full.png` (motion reference — row 3 is attack-up) AND `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` (character design reference)

```
I am attaching two reference images:
1. A sword attack animation spritesheet (512x256, 4 rows × 8 columns of 64x64 frames). Row 3 shows the attack-up (back-facing) direction. Use this ONLY as a motion/pose reference.
2. A full idle spritesheet (192x192) showing the Dianthus Pixie character — green hood with pink Dianthus flower accents, cream tunic, leather satchel, earthy trousers, dark boots.

Create an 8-frame ONE-SHOT SWORD ATTACK animation spritesheet, back-facing (attacking upward/away from camera).
Output: 512x64 PNG, 8 frames of 64x64, horizontal strip, transparent background. Does NOT loop.

Use EXACTLY the same body poses and sword motion as Row 3 of the reference spritesheet, but draw the Dianthus Pixie character. Since this is back-facing, the cloak and hood back are prominent. The back-cloak Dianthus flower arrangement should be visible.

Frame 1: Neutral/alert stance facing away. Sword held at side. Back of hood facing camera.
Frame 2: Wind-up — sword arm raises. Back of cloak shifts. Back of hood visible.
Frame 3: Wind-up peak — sword fully raised up above the back. Maximum pull. Cloak billows slightly.
Frame 4: Attack release — sword sweeps forward (away from camera) in a wide arc. Arc trail begins.
Frame 5: Mid-swing — sword at widest arc point. Arc trail most prominent. Back of cloak pushed by momentum.
Frame 6: Swing continues. Arc trail still visible. Back of hood tilts with effort.
Frame 7: Swing end. Trail fading. Body straightening from follow-through.
Frame 8: Recovery — sword lowers. Cloak settles. Back of hood returns to neutral.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Same colors only from idle reference + steel-silver sword + white arc trail
- 1-pixel dark outline every frame, character + sword within 64x64 cells
- Back-cloak Dianthus flower arrangement and all clothing details preserved every frame
- Output: 512x64 PNG, transparent background, no upscaling, no smoothing
- Does NOT loop — Frame 8 ends the attack
```

---

## Prompt 3 — Attack Right (side-facing)

> **Attach:** `player/sprites/PNG/Sword_attack/Sword_attack_full.png` (motion reference — row 2 is attack-right) AND `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` (character design reference)

```
I am attaching two reference images:
1. A sword attack animation spritesheet (512x256, 4 rows × 8 columns of 64x64 frames). Row 2 shows the attack-right (right-facing profile) direction. Use this ONLY as a motion/pose reference.
2. A full idle spritesheet (192x192) showing the Dianthus Pixie character — green hood with pink Dianthus flower accents, cream tunic, leather satchel, earthy trousers, dark boots.

Create an 8-frame ONE-SHOT SWORD ATTACK animation spritesheet, right-facing profile (attacking rightward).
Output: 512x64 PNG, 8 frames of 64x64, horizontal strip, transparent background. Does NOT loop.

Use EXACTLY the same body poses and sword motion as Row 2 of the reference spritesheet, but draw the Dianthus Pixie character. In profile view, the satchel is visible at the hip and the sword arm is fully readable through the swing.

Frame 1: Neutral/alert stance facing right. Sword held at side or low. Body in profile.
Frame 2: Wind-up — sword arm swings back (to the left in profile view). Body leans back/left. Hood flower accent visible in profile.
Frame 3: Wind-up peak — sword pulled fully back, arm extended behind. Body coiled ready to strike.
Frame 4: Attack release — sword swings right in a wide horizontal arc. Body lunges right. Arc trail begins. 
Frame 5: Mid-swing — sword at full horizontal extension to the right. Arc trail most prominent (curved line of 4-5 white pixels). Satchel bounces at hip.
Frame 6: Swing continues past center, sword now angled down-right. Arc trail visible. Body weight forward.
Frame 7: Swing end — sword at lowest/furthest point of arc. Trail fading. Body still leaning forward.
Frame 8: Recovery — sword returns toward rest. Body straightens. Cloak settles behind.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Same colors only from idle reference + steel-silver sword + white arc trail
- 1-pixel dark outline every frame, character + sword within 64x64 cells
- Satchel, hood flower accent in profile, and all clothing details preserved every frame
- Output: 512x64 PNG, transparent background, no upscaling, no smoothing
- Does NOT loop — Frame 8 ends the attack
```

---

## Prompt 4 — Attack Left (side-facing)

> **Attach:** `player/sprites/PNG/Sword_attack/Sword_attack_full.png` (motion reference — row 4 is attack-left) AND `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` (character design reference)

```
I am attaching two reference images:
1. A sword attack animation spritesheet (512x256, 4 rows × 8 columns of 64x64 frames). Row 4 shows the attack-left (left-facing profile) direction. Use this ONLY as a motion/pose reference.
2. A full idle spritesheet (192x192) showing the Dianthus Pixie character — green hood with pink Dianthus flower accents, cream tunic, leather satchel, earthy trousers, dark boots.

Create an 8-frame ONE-SHOT SWORD ATTACK animation spritesheet, left-facing profile (attacking leftward).
Output: 512x64 PNG, 8 frames of 64x64, horizontal strip, transparent background. Does NOT loop.

This is the horizontally mirrored counterpart to the right-facing attack. The satchel is on the opposite hip. The sword swings to the left. Use EXACTLY the same body poses and sword motion as Row 4 of the reference spritesheet, but draw the Dianthus Pixie character.

Frame 1: Neutral/alert stance facing left. Sword held at side. Satchel on mirrored hip.
Frame 2: Wind-up — sword arm swings back (to the right in this profile view). Body leans back/right.
Frame 3: Wind-up peak — sword fully pulled back to the right. Maximum coil.
Frame 4: Attack release — sword swings left in a wide arc. Body lunges left. Arc trail begins.
Frame 5: Mid-swing — sword at full left extension. Arc trail most prominent. Satchel bounces at mirrored hip.
Frame 6: Swing continues. Arc trail visible.
Frame 7: Swing end — sword at furthest left point. Trail fading.
Frame 8: Recovery — sword returns toward rest. Cloak settles. Body straightens.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Same colors only from idle reference + steel-silver sword + white arc trail
- 1-pixel dark outline every frame, character + sword within 64x64 cells
- Satchel (mirrored hip), hood flower accent in profile, and all clothing details preserved every frame
- Output: 512x64 PNG, transparent background, no upscaling, no smoothing
- Does NOT loop — Frame 8 ends the attack
```

---

## Bonus — Full Attack Spritesheet (all 4 directions)

> **Attach:** `player/sprites/PNG/Sword_attack/Sword_attack_full.png` AND `player/sprites/PNG/Unarmed_Idle/player_idle_full.png`

```
I am attaching two reference images:
1. A sword attack animation spritesheet (512x256, 4 rows × 8 columns of 64x64 frames) with a generic placeholder character — use this ONLY as a motion reference for body poses, sword angles, and swing arc paths.
2. A 192x192 idle spritesheet showing the Dianthus Pixie character design — green hood with pink Dianthus flower accents, cream tunic, leather satchel, earthy trousers, dark boots.

Create a ONE-SHOT SWORD ATTACK animation spritesheet: 512x256 PNG, 4 rows × 8 columns, each cell 64x64 pixels, transparent background. Does NOT loop.

Layout matches the reference:
- Row 1 (Down/front): attack toward camera — sword sweeps down and across in front of the body
- Row 2 (Right/profile): attack rightward — sword sweeps horizontally right in profile
- Row 3 (Up/back-facing): attack away from camera — sword sweeps forward/upward, back of cloak visible
- Row 4 (Left/profile): attack leftward — mirrored version of Row 2, satchel on opposite hip

Draw the Dianthus Pixie character (green hood, pink Dianthus flower accents, cream tunic, satchel, earthy trousers, dark boots) using the EXACT same body poses and sword motion as the reference's corresponding row.

The sword is a short one-handed slightly-curved steel-silver blade with thorn notches along the spine and a leather-wrapped handle.

Per-row 8-frame arc:
F1: Neutral alert stance — sword at side, facing attack direction
F2: Wind-up — sword arm pulls back, body leans into the coil
F3: Wind-up peak — sword fully drawn back, maximum coil, feet planted
F4: Attack release — sword begins wide sweep forward, body lunges, arc trail starts (2-3 white pixels) — HITBOX ACTIVE
F5: Mid-swing — sword at widest arc point, arc trail most prominent (4-5 white pixels curved), body fully extended — HITBOX ACTIVE
F6: Swing continues, arc trail visible (3-4 white pixels), body weight shifting — HITBOX ACTIVE
F7: Swing end — sword reaches far side of arc, trail fading (2-3 white pixels) — HITBOX ACTIVE
F8: Recovery — sword returns toward rest, body straightening, no arc trail

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Same colors only from idle reference + steel-silver sword (#C8D8E8, #A0B8C8, #E8F0F8) + white arc trail (#FFFFFF, #F0F4FF)
- 1-pixel dark outline every frame, character + sword within each 64x64 cell
- Hood Dianthus flower accents, satchel, and all clothing details preserved in every frame
- Output: single PNG, exactly 512x256 pixels, transparent background, no upscaling, no smoothing
- Does NOT loop — Frame 8 (column 8) of every row is the recovery/end pose
```

---

## Compact Fallback Prompts

### Compact — Attack Down
```
Using the attached sword attack reference spritesheet (row 1 = attack down, 8 frames of 64x64) as motion reference, and the idle spritesheet as character design reference, create an 8-frame ONE-SHOT sword attack animation for the Dianthus Pixie character (green hood with pink flower accents, cream tunic, satchel, earthy trousers) attacking downward. 512x64 PNG, horizontal strip, transparent background, strict pixel art, no anti-aliasing. Motion: F1=neutral stance, F2-F3=wind-up (sword pulled back), F4-F7=wide sweep arc (white arc trail pixels, HITBOX ACTIVE), F8=recovery. Steel-silver thorn sword. Same colors only + silver + white trail. Not looping. No upscaling.
```

### Compact — Attack Up
```
Using the attached sword attack reference spritesheet (row 3 = attack up, 8 frames of 64x64) as motion reference, and the idle spritesheet as character design reference, create an 8-frame ONE-SHOT sword attack animation for the Dianthus Pixie character (green hood with pink flower accents, cream tunic, satchel, earthy trousers) attacking upward/away from camera. 512x64 PNG, horizontal strip, transparent background, strict pixel art, no anti-aliasing. Motion: F1=neutral back-facing, F2-F3=wind-up, F4-F7=wide arc sweep (white arc trail, HITBOX ACTIVE), F8=recovery. Back-cloak Dianthus flowers visible. Steel-silver thorn sword. Same colors + silver + white trail. Not looping. No upscaling.
```

### Compact — Attack Right
```
Using the attached sword attack reference spritesheet (row 2 = attack right, 8 frames of 64x64) as motion reference, and the idle spritesheet as character design reference, create an 8-frame ONE-SHOT sword attack animation for the Dianthus Pixie character (green hood with pink flower accents, cream tunic, satchel, earthy trousers) attacking rightward in profile. 512x64 PNG, horizontal strip, transparent background, strict pixel art, no anti-aliasing. Motion: F1=neutral profile, F2-F3=wind-up (sword pulled left), F4-F7=wide horizontal right sweep (white arc trail, HITBOX ACTIVE), F8=recovery. Satchel at hip. Steel-silver thorn sword. Same colors + silver + white trail. Not looping. No upscaling.
```

### Compact — Attack Left
```
Using the attached sword attack reference spritesheet (row 4 = attack left, 8 frames of 64x64) as motion reference, and the idle spritesheet as character design reference, create an 8-frame ONE-SHOT sword attack animation for the Dianthus Pixie character (green hood with pink flower accents, cream tunic, satchel, earthy trousers) attacking leftward in profile. 512x64 PNG, horizontal strip, transparent background, strict pixel art, no anti-aliasing. Motion: F1=neutral left-profile, F2-F3=wind-up (sword pulled right), F4-F7=wide horizontal left sweep (white arc trail, HITBOX ACTIVE), F8=recovery. Satchel on mirrored hip. Steel-silver thorn sword. Same colors + silver + white trail. Not looping. No upscaling.
```

### Compact — Full Sheet (all 4 directions)
```
Using the attached sword attack reference spritesheet (512x256, 4 rows × 8 cols of 64x64) as motion reference and the idle spritesheet as character design reference, create a ONE-SHOT sword attack spritesheet: 512x256 PNG, 4 rows × 8 cols of 64x64, transparent background. Draw the Dianthus Pixie character (green hood, pink Dianthus flower accents, cream tunic, satchel, earthy trousers, dark boots) with a steel-silver thorn sword. R1=attack down, R2=attack right, R3=attack up, R4=attack left. Per-row: F1=neutral, F2-F3=wind-up, F4-F7=wide arc sweep + white arc trail (HITBOX ACTIVE frames), F8=recovery. Strict pixel art, same colors only + silver + white trail, no anti-aliasing, not looping, no upscaling.
```

---

## Hitbox Notes for Implementation

The attack hitbox in code is active on **frames 4–7** (0-indexed: frames 3–6). This matches the white arc trail being visible. Implement in `player_controller.gd`:
- Enable sword hitbox `CollisionShape2D` at the start of frame 4 in `AnimationPlayer`
- Disable it at the end of frame 7

---

## Usage Notes

- Save output spritesheets as:
  - `player/sprites/PNG/Sword_Attack/player_attack_down_sheet.png`
  - `player/sprites/PNG/Sword_Attack/player_attack_up_sheet.png`
  - `player/sprites/PNG/Sword_Attack/player_attack_right_sheet.png`
  - `player/sprites/PNG/Sword_Attack/player_attack_left_sheet.png`
  - Or full sheet: `player/sprites/PNG/Sword_Attack/player_attack_full.png`
- Import into Godot with **Filter = Nearest** (no interpolation).
- In `SpriteFrames`, configure the `attack` animation with **8 frames** from the horizontal strip, each frame **64×64 pixels**.
- Set the animation as **non-looping** in Godot's SpriteFrames or AnimationPlayer.
- Recommended playback speed: **12 FPS** (total attack duration ~0.67s).
- The attack-left sheet can alternatively be produced by **horizontally flipping** the attack-right sheet frame-by-frame, if Gemini struggles with left-facing consistency.
- The same attack animation applies to both **Thorn Sword** and **Blazeblade** — for Blazeblade, add warm orange/amber edge highlights (#C86020, #E88030) along the blade in a second pass.

---

## Troubleshooting

1. **Retry after 30-60 seconds** — transient TCP resets are common with Google API endpoints.
2. **Shorten the prompt** — use the compact version if the full prompt times out.
3. **Use Gemini via browser (AI Studio)** — paste at https://aistudio.google.com.
4. **Switch model** — try `gemini-2.0-flash-exp` or `gemini-2.0-flash` if overloaded.
5. **If the character doesn't match the reference design** — re-emphasize "Use the idle spritesheet as the ONLY source of truth for the character's appearance. The sword attack reference is for motion ONLY."
6. **If the sword arc trail is missing** — add: "On frames 4–7, draw 3–5 white or near-white (#FFFFFF or #F0F4FF) scattered pixels in a curved arc path tracing where the blade just swept. This is a motion trail, not a glow — individual pixel dots along a curved line."
7. **If the swing is too small** — add: "The sword arc must sweep across at least half the 64-pixel width of the frame. The swing is WIDE and dramatic — this is the primary attack animation."
8. **If the wind-up (frames 2–3) looks wrong** — add: "On frames 2 and 3, the sword arm should be pulled clearly BACK and AWAY from the attack direction, loading energy for the swing. This is the opposite direction to the attack."
9. **If frames 4–7 all look identical** — add: "Each of frames 4, 5, 6, 7 must show the sword at a DIFFERENT angle along the arc. The blade rotates visibly from frame to frame as it sweeps through the air."
10. **If output is wrong size** — add: "Do NOT upscale. The final PNG must be exactly 512 pixels wide and 64 pixels tall."
