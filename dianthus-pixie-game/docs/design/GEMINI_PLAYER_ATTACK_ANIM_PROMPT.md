# Gemini Image Generation Prompt — Dianthus Pixie Attack Animation Spritesheets

## Overview

Generate **4 attack animation spritesheets** (one per direction) for the player wielding the **Thorn Sword / Blazeblade** — a short, slightly curved single-handed blade with thorned vines wrapped around the handle and a faint green-pink glow at its edge. Each spritesheet is a single horizontal strip of **6 frames**, each frame 32×48 pixels, producing a **192×48 pixel PNG**.

**This is a ONE-SHOT animation — it does NOT loop.** Frame 6 returns to the idle/ready stance.

**Attach the following reference images** when sending each prompt to Gemini:
- `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` — full 4-direction idle sheet (character design reference)
- `player/sprites/PNG/Sword_Idle/Sword_Idle_full.png` — full 4-direction sword idle sheet (weapon + character equipped reference)
- `player/sprites/PNG/Sword_attack/Sword_attack_full.png` — existing layered sword attack sheet (motion arc reference)
- The single-direction **sword idle** frame for the direction you are generating

---

## Style Rules (all directions)

```
- Strict pixel art — no anti-aliasing, no gradients, no soft edges, no sub-pixel rendering
- Each frame is exactly 32 pixels wide × 48 pixels tall
- 6 frames arranged in a single horizontal strip → total image size: 192×48 pixels
- Transparent background — no solid background color
- Limited palette: same colors as the reference images — do not introduce new colors
- 1-pixel dark outline around the character and weapon on every frame
- Output: a single PNG image, 192×48 pixels, transparent background, no upscaling, no smoothing, no filtering
- Art direction: 2D pixel art for a fantasy survival crafting game with a Southeast Asian botanical theme
- The character and sword must be fully contained within each 32×48 cell with no cropping
- This animation does NOT loop — Frame 6 is a held ready/recovery pose
```

---

## Color Palette (all directions — must match reference exactly)

```
Character:
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

Thorn Sword / Blazeblade:
- Blade: cool steel grey (#A8B8C0, #7898A8) with a faint pink-green edge glow (use existing palette pinks and greens only)
- Thorned vine handle wrap: dark green (#2A4820) with tiny thorn spike highlights (light tan #D4C4A0)
- Guard/crossguard: brown leather tone (#8C6030) with thorn detail
- Blazeblade upgrade: blade edge takes on a warm amber-orange tint (#D87820, #B85A10) — use only if referencing the upgraded form
- No additional colors beyond the established palette
```

---

## Weapon Design Reference

The **Thorn Sword** is a short, single-handed melee weapon:
- **Blade**: slightly curved, ~10-12 pixels long in side profile, thin (2 pixels wide at base, 1 pixel at tip)
- **Handle**: 5-6 pixels long, wrapped in dark thorned vines — visible as alternating dark green and tiny highlight pixels
- **Guard**: small simple crossguard, 3 pixels wide, brown leather tone
- **Tip**: pointed, slightly angled upward on the cutting edge
- **Visual signature**: a faint 1-pixel pink or green glow dot at the blade edge tip (subtle, not glowing dramatically)

When the character swings, the blade should trace a visible arc — the weapon extends beyond the body silhouette on the swing frame.

---

## Animation Description (all directions)

The attack animation is a **6-frame melee sword slash** — a quick windup into a decisive downward-diagonal or horizontal swing, then a brief recovery. The full animation at 10 FPS takes ~0.6 seconds.

```
Frame 1 — Ready / Windup Start:
Character shifts weight to the weapon side. Sword raises to shoulder height (held vertically or at ~45° upward).
Knees slightly bent (legs 1 pixel shorter — weight loading). Free arm pulls back for balance.
Cloak shifts with the lean. Eyes/face focused forward.

Frame 2 — Full Windup:
Sword at maximum raised position — hilt near shoulder, blade pointing upward-back.
Body coiled — torso rotates toward weapon side (1-2 pixel lean). Weight loaded on back foot.
Free arm raised to balance. Cloak/hood hem shifts from momentum.

Frame 3 — Swing Release (Action Frame):
The main attack frame — the sword sweeps through its arc.
Blade extends to full reach, now horizontal or diagonally downward. Arm extended forward or to the side.
A 3-5 pixel motion blur arc of pixels trails behind the blade tip (same blade color, 50% faded — 
use dithered pixels or a lighter version of the blade grey).
Body weight transfers — torso lunges forward 1-2 pixels. Back foot begins lifting.
This frame should show the blade at maximum extension — it may visually break the character silhouette edge.

Frame 4 — Follow-Through:
Sword continues past the swing — now angled downward or behind the character.
Arm follows through, partially behind or below the body.
Body slightly overextended from the lunge momentum. Front foot now planted.
Small motion trail pixels fading (1-2 faded blade pixels remaining).

Frame 5 — Recovery Start:
Sword draws back toward the body — returning to a guard position.
Stance begins resetting — weight shifting back to both feet.
Body uprighting from the lunge. Hood/cloak settles.

Frame 6 — Recovery / Ready Pose:
Character back in combat-ready stance — sword held at mid-guard (diagonal, blade forward).
Feet at normal width. Body upright. Cloak settled.
This is the held final frame — identical to or slightly distinct from the Sword Idle pose.
```

---

## Prompt 1 — Attack Down (front-facing)

> **Attach:** `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` AND `player/sprites/PNG/Sword_Idle/Sword_Idle_full.png` AND `player/sprites/PNG/Sword_attack/Sword_attack_full.png` AND the single front-facing Sword Idle frame

```
I am attaching four reference images:
1. Full unarmed idle spritesheet (192x192, 4 rows × 6 cols of 32x48) — overall character design, proportions, and color palette.
2. Full sword idle spritesheet (192x192, same layout) — how the character looks while holding the Thorn Sword in all 4 directions.
3. Full sword attack spritesheet (192x192, same layout) — existing motion arc reference for how the character swings.
4. A single 32x48 pixel art sprite (front-facing sword idle pose) — use this as the base starting pose.

Create a 6-frame ONE-SHOT ATTACK animation spritesheet, front-facing direction (character faces the camera, swings sword toward/downward at the viewer).
Output: 192x48 PNG, 6 frames of 32x48, horizontal strip, transparent background. Does NOT loop.

The Thorn Sword / Blazeblade: short curved single-handed blade (~10-12px long), vine-wrapped dark handle (~5-6px), small leather crossguard. Faint pink-green glow pixel at blade tip.

Frame 1 — Windup Start: Upright front-facing stance. Sword rises to shoulder height on the right side, blade angled upward-right at ~45°. Left arm pulls back slightly for balance. Knees slightly bent (1px shorter). Cloak shifts right.

Frame 2 — Full Windup: Sword raised to maximum — hilt near right shoulder, blade angled upward-backward. Body leans/coils right. Left arm raised left for balance. Weight on back/right foot.

Frame 3 — Swing (Action Frame): Sword sweeps downward-forward in a wide arc. Blade tip extends toward the camera at full reach — blade now nearly horizontal or angled downward-left at the viewer. 3-5 faded grey pixels trail the blade tip in an arc. Body lunges forward 1-2px, torso dips. The sword may extend past the left edge of the character silhouette.

Frame 4 — Follow-Through: Sword past center, now angled down-left or below center. Arm follows through. Body slightly overextended. 1-2 faint trail pixels remain. Front foot planted.

Frame 5 — Recovery Start: Sword draws back to mid-guard. Stance resetting. Body uprighting. Cloak settling.

Frame 6 — Recovery / Ready: Back to combat-ready stance. Sword at mid-guard diagonal (blade angled forward-up). Both feet planted, body upright. Final held frame.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Use ONLY the colors from the attached references — do not add new colors
- Keep the 1-pixel dark outline on the character AND the sword every frame
- Character and sword must remain within each 32x48 cell — only the swing arc of the blade tip may visually extend to the cell edge
- Satchel, hood flower accents, all clothing details preserved every frame
- The sword design (vine handle, curved blade, tip glow pixel) must be consistent across all frames
- Output: single PNG, exactly 192x48 pixels, transparent background, no upscaling, no smoothing
- Does NOT loop — Frame 6 is the final held pose
```

---

## Prompt 2 — Attack Up (back-facing)

> **Attach:** `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` AND `player/sprites/PNG/Sword_Idle/Sword_Idle_full.png` AND `player/sprites/PNG/Sword_attack/Sword_attack_full.png` AND the single back-facing Sword Idle frame

```
I am attaching four reference images:
1. Full unarmed idle spritesheet (192x192, 4 rows × 6 cols of 32x48) — overall character design, proportions, and color palette.
2. Full sword idle spritesheet (192x192, same layout) — how the character holds the Thorn Sword in all 4 directions.
3. Full sword attack spritesheet (192x192, same layout) — motion arc reference.
4. A single 32x48 pixel art sprite (back-facing sword idle pose, facing away from camera) — base starting pose.

Create a 6-frame ONE-SHOT ATTACK animation spritesheet, back-facing direction (character faces away, swings sword upward/forward away from camera).
Output: 192x48 PNG, 6 frames of 32x48, horizontal strip, transparent background. Does NOT loop.

The Thorn Sword: short curved single-handed blade (~10-12px), vine-wrapped dark handle, small leather crossguard, faint glow pixel at tip.

Frame 1 — Windup Start: Upright back-facing stance. Sword raises on the right side — from the back, the blade appears on the right, angling upward-right. Cloak visible. Left arm pulls back.

Frame 2 — Full Windup: Sword at maximum raise — hilt near right shoulder, blade points upward-right from behind. Body coils right. Back-cloak shifts. Left arm raised for balance.

Frame 3 — Swing (Action Frame): Sword sweeps upward-forward (away from camera) in a wide arc. Blade extends forward-right at full reach. 3-5 faded blade pixels trail in arc. Body leans forward (away from camera) 1-2px. Sword tip may extend past the right edge of the character's body silhouette.

Frame 4 — Follow-Through: Sword continues past center — now angled forward-left or across the back. Body slightly overextended forward. 1-2 faint blade trail pixels remain.

Frame 5 — Recovery Start: Sword draws back to mid-guard position (behind-right from this view). Stance resetting, body uprighting. Back-cloak settling.

Frame 6 — Recovery / Ready: Back to combat-ready stance, back-facing. Sword at mid-guard. Back-cloak with dianthus flower detail settled. Final held frame.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, same colors only, 1px outline on character and sword every frame
- Character and sword within each 32x48 cell
- Back-cloak dianthus flower arrangement preserved every frame
- Sword design consistent across all frames
- Output: single PNG, exactly 192x48 pixels, transparent background, no upscaling, no smoothing
- Does NOT loop — Frame 6 is the final held pose
```

---

## Prompt 3 — Attack Right (side-facing)

> **Attach:** `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` AND `player/sprites/PNG/Sword_Idle/Sword_Idle_full.png` AND `player/sprites/PNG/Sword_attack/Sword_attack_full.png` AND the single right-facing Sword Idle frame

```
I am attaching four reference images:
1. Full unarmed idle spritesheet (192x192, 4 rows × 6 cols of 32x48) — character design, proportions, palette.
2. Full sword idle spritesheet (192x192, same layout) — character with Thorn Sword in all 4 directions.
3. Full sword attack spritesheet (192x192, same layout) — motion arc reference.
4. A single 32x48 pixel art sprite (right-facing profile sword idle pose) — base starting pose.

Create a 6-frame ONE-SHOT ATTACK animation spritesheet, right-facing profile direction (character faces right, swings sword rightward).
Output: 192x48 PNG, 6 frames of 32x48, horizontal strip, transparent background. Does NOT loop.

In this profile view the sword arc is most visually dramatic — the blade extends clearly to the right.
The Thorn Sword: short curved blade (~10-12px long in profile), vine-wrapped handle (~5-6px), small crossguard. Blade tip with faint glow pixel.

Frame 1 — Windup Start: Right-facing profile. Sword raises upward-right — blade angled up and back at ~135° (pointing backward-upward from a right-facing view). Arm pulls back. Front leg slightly bent. Cloak trails left. Satchel at hip.

Frame 2 — Full Windup: Sword at maximum raised-back position — blade pointing upward-left (fully coiled behind). Torso rotates back slightly. Weight shifts to back foot. Cloak hem lifts slightly from the wind-up.

Frame 3 — Swing (Action Frame): THE KEY FRAME. Sword sweeps forward-right in a wide horizontal or diagonal arc. Blade at full extension — tip pointing right, clearly past the character's right edge (the blade tip extends to or near the right edge of the 32px wide cell). Arm fully extended right. 3-5 faded grey/blade-colored pixels arc behind the blade tip showing the slash trail. Body lunges right 1-2px. Front foot forward.

Frame 4 — Follow-Through: Sword past center, now angled downward-right or forward-down. Arm still extended but dropping. Body slightly forward from lunge momentum. 1-2 faint trail pixels. Front foot planted.

Frame 5 — Recovery Start: Sword draws back toward mid-guard, arm returning. Stance resetting. Cloak settling back.

Frame 6 — Recovery / Ready: Right-facing combat-ready stance. Sword at mid-guard — blade angled forward-up at ~45° from a right profile view. Feet at normal stance width. Satchel at hip. Cloak settled. Final held frame.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Same colors only, 1px outline on character and sword every frame
- Character within each 32x48 cell; blade tip may reach the right cell edge in Frame 3 only
- Satchel and hood flower accents preserved every frame
- Sword design (vine handle, curved blade, tip glow) consistent across all frames
- Output: single PNG, exactly 192x48 pixels, transparent background, no upscaling, no smoothing
- Does NOT loop — Frame 6 is the final held pose
```

---

## Prompt 4 — Attack Left (side-facing)

> **Attach:** `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` AND `player/sprites/PNG/Sword_Idle/Sword_Idle_full.png` AND `player/sprites/PNG/Sword_attack/Sword_attack_full.png` AND the single left-facing Sword Idle frame

```
I am attaching four reference images:
1. Full unarmed idle spritesheet (192x192, 4 rows × 6 cols of 32x48) — character design, proportions, palette.
2. Full sword idle spritesheet (192x192, same layout) — character with Thorn Sword in all 4 directions.
3. Full sword attack spritesheet (192x192, same layout) — motion arc reference.
4. A single 32x48 pixel art sprite (left-facing profile sword idle pose) — base starting pose.

Create a 6-frame ONE-SHOT ATTACK animation spritesheet, left-facing profile direction (character faces left, swings sword leftward).
Output: 192x48 PNG, 6 frames of 32x48, horizontal strip, transparent background. Does NOT loop.

This is the horizontally mirrored counterpart to the right-facing attack. The satchel appears on the opposite hip. The blade arc extends to the LEFT.
The Thorn Sword: short curved blade (~10-12px long in profile), vine-wrapped handle (~5-6px), small crossguard. Blade tip with faint glow pixel.

Frame 1 — Windup Start: Left-facing profile. Sword raises upward-left — blade angled up and back at ~135° from left-facing (pointing backward-upward). Arm pulls back. Front leg slightly bent. Cloak trails right. Satchel at mirrored hip.

Frame 2 — Full Windup: Sword at maximum raised-back position — blade pointing upward-right (fully coiled behind). Torso rotates back slightly. Weight shifts to back foot.

Frame 3 — Swing (Action Frame): Sword sweeps forward-left in a wide horizontal or diagonal arc. Blade at full extension — tip pointing left, clearly reaching or near the left edge of the 32px cell. Arm fully extended left. 3-5 faded arc/trail pixels behind the blade tip. Body lunges left 1-2px.

Frame 4 — Follow-Through: Sword past center, angled downward-left or forward-down. Arm dropping. Body slightly forward from lunge. 1-2 faint trail pixels.

Frame 5 — Recovery Start: Sword draws back to mid-guard. Stance resetting. Cloak settling.

Frame 6 — Recovery / Ready: Left-facing combat-ready stance. Sword at mid-guard diagonal, blade angled forward-up at ~45° from left profile. Feet planted, satchel at mirrored hip, cloak settled. Final held frame.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Same colors only, 1px outline on character and sword every frame
- Character within each 32x48 cell; blade tip may reach the left cell edge in Frame 3 only
- Satchel (mirrored hip) and hood flower accents preserved every frame
- Sword design (vine handle, curved blade, tip glow) consistent across all frames
- Output: single PNG, exactly 192x48 pixels, transparent background, no upscaling, no smoothing
- Does NOT loop — Frame 6 is the final held pose
```

---

## Bonus — Full Attack Spritesheet (all 4 directions)

> **Attach:** `player/sprites/PNG/Unarmed_Idle/player_idle_full.png` AND `player/sprites/PNG/Sword_Idle/Sword_Idle_full.png` AND `player/sprites/PNG/Sword_attack/Sword_attack_full.png`

```
I am attaching three reference images:
1. Full unarmed idle spritesheet (192x192, 4 rows × 6 cols of 32x48) — character design, proportions, palette.
2. Full sword idle spritesheet (192x192, same layout) — character with Thorn Sword equipped in all 4 directions.
3. Full sword attack spritesheet (192x192, same layout) — existing motion arc reference.

Create a ONE-SHOT ATTACK animation spritesheet: 192x192 PNG, 4 rows × 6 columns, 32x48 cells, transparent background.
Does NOT loop — Column 6 of every row is the final recovery/ready pose.

The Thorn Sword / Blazeblade: short curved single-handed blade (~10-12px), vine-wrapped dark handle (~5-6px), small leather crossguard, faint pink-green glow pixel at blade tip.

Row 1 (Down/front): character faces camera, swings sword downward toward viewer.
Row 2 (Right/profile): character faces right, swings sword in wide rightward horizontal arc.
Row 3 (Up/back): character faces away, swings sword forward-upward away from camera.
Row 4 (Left/profile): character faces left, swings sword in wide leftward horizontal arc (mirror of Row 2).

Per-row attack arc (6 frames):
F1: Windup Start — sword raises to shoulder height (~45° upward), knees slightly bent (1px shorter), free arm pulls back, cloak shifts.
F2: Full Windup — sword at maximum raised position, body coiled toward weapon side, weight on back foot.
F3: Swing/Action — sword at full extension in the swing arc, blade tip at maximum reach (may touch cell edge), 3-5 faded blade-color arc pixels trail behind tip, body lunges 1-2px forward.
F4: Follow-Through — sword past swing center, arm following through, body slightly overextended, 1-2 faint trail pixels.
F5: Recovery Start — sword returns toward mid-guard, stance resetting, cloak settling.
F6: Recovery/Ready — combat-ready stance, sword at mid-guard diagonal, body upright. Final held frame.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Same colors only — do not add new colors
- 1-pixel dark outline on character AND sword every frame
- Character and sword within each 32x48 cell — only blade tip in swing Frame 3 may reach the cell edge
- Satchel, hood flower accents, all clothing details preserved every frame
- Sword design (vine handle, curved blade, crossguard, tip glow) consistent across all directions and frames
- Output: single PNG, exactly 192x192 pixels, transparent background, no upscaling, no smoothing
- Does NOT loop — Column 6 of every row is the final held recovery pose
```

---

## Compact Fallback Prompts

If Gemini times out, use these shorter versions (still attach all reference images):

### Compact — Attack Down
```
Using the attached sword idle and attack reference spritesheets and the single 32x48 front-facing sword idle frame, create a 6-frame ONE-SHOT attack animation. 192x48 PNG (6 cells of 32x48), horizontal strip, transparent background, strict pixel art, no anti-aliasing. Thorn Sword: short curved blade (~12px), vine handle, small crossguard, glow pixel at tip. Arc: F1=sword raised to shoulder windup, F2=full windup blade up-back, F3=swing forward toward viewer + 3-5 faded blade arc pixels, F4=follow-through, F5=recovery start, F6=combat ready mid-guard. NOT looping. Same colors only. No upscaling.
```

### Compact — Attack Up
```
Using the attached sword idle and attack reference spritesheets and the single 32x48 back-facing sword idle frame, create a 6-frame ONE-SHOT attack animation. 192x48 PNG (6 cells of 32x48), horizontal strip, transparent background, strict pixel art, no anti-aliasing. Thorn Sword: short curved blade (~12px), vine handle, small crossguard, glow pixel at tip. Arc: F1=sword raised windup from behind, F2=full windup blade up-back, F3=swing forward-away from camera + 3-5 faded arc pixels, F4=follow-through, F5=recovery, F6=combat ready back-facing. NOT looping. Same colors only. No upscaling.
```

### Compact — Attack Right
```
Using the attached sword idle and attack reference spritesheets and the single 32x48 right-facing sword idle frame, create a 6-frame ONE-SHOT attack animation. 192x48 PNG (6 cells of 32x48), horizontal strip, transparent background, strict pixel art, no anti-aliasing. Thorn Sword: short curved blade (~12px), vine handle, small crossguard, glow pixel at tip. Arc: F1=sword raised up-back windup (right profile), F2=full coiled windup, F3=swing rightward at full reach + blade tip near right cell edge + 3-5 arc trail pixels, F4=follow-through, F5=recovery, F6=mid-guard right-facing ready. NOT looping. Same colors only. No upscaling.
```

### Compact — Attack Left
```
Using the attached sword idle and attack reference spritesheets and the single 32x48 left-facing sword idle frame, create a 6-frame ONE-SHOT attack animation. 192x48 PNG (6 cells of 32x48), horizontal strip, transparent background, strict pixel art, no anti-aliasing. Thorn Sword: short curved blade (~12px), vine handle, small crossguard, glow pixel at tip. Arc: F1=sword raised up-back windup (left profile, satchel mirrored), F2=full coiled windup, F3=swing leftward at full reach + blade tip near left cell edge + 3-5 arc trail pixels, F4=follow-through, F5=recovery, F6=mid-guard left-facing ready. NOT looping. Same colors only. No upscaling.
```

### Compact — Full Sheet (all 4 directions)
```
Using the attached 192x192 sword idle + sword attack spritesheets as reference, create a ONE-SHOT ATTACK animation spritesheet: 192x192 PNG, 4 rows × 6 cols of 32x48, transparent background. R1=attack down (front-facing, sword swings toward viewer), R2=attack right (profile, sword swings right), R3=attack up (back-facing, sword swings away), R4=attack left (profile, sword swings left, mirrored R2). Per-row arc: F1=windup sword raised, F2=full coiled windup, F3=swing at full reach (blade tip to cell edge) + 3-5 faded arc trail pixels, F4=follow-through, F5=recovery start, F6=mid-guard ready. Thorn Sword: short curved blade ~12px, vine handle, small crossguard, glow pixel at tip. NOT looping. Strict pixel art, same colors only, no anti-aliasing, no upscaling.
```

---

## Usage Notes

- Save output spritesheets as:
  - `player/sprites/PNG/Sword_Attack_Anim/player_attack_down_sheet.png`
  - `player/sprites/PNG/Sword_Attack_Anim/player_attack_up_sheet.png`
  - `player/sprites/PNG/Sword_Attack_Anim/player_attack_right_sheet.png`
  - `player/sprites/PNG/Sword_Attack_Anim/player_attack_left_sheet.png`
  - Or full sheet: `player/sprites/PNG/Sword_Attack_Anim/player_attack_full.png`
- Import into Godot with **Filter = Nearest** (no interpolation).
- In `SpriteFrames`, configure the `attack` animation with **6 frames** from the horizontal strip.
- Set the animation as **non-looping** in Godot's SpriteFrames or AnimationPlayer.
- Recommended playback speed: **10-12 FPS** (faster than walk/idle to feel snappy).
- The action frame (Frame 3) is the one where `_start_attack()` / hitbox should activate in `player_controller.gd`.
- The attack-left sheet can alternatively be produced by **horizontally flipping** the attack-right sheet frame-by-frame, if Gemini struggles with left-facing consistency.

---

## Troubleshooting

1. **Retry after 30-60 seconds** — transient TCP resets are common with Google API endpoints.
2. **Shorten the prompt** — use the compact version if the full prompt times out.
3. **Use Gemini via browser (AI Studio)** — paste the prompt at https://aistudio.google.com instead of API calls.
4. **Switch model** — try `gemini-2.0-flash-exp` or `gemini-2.0-flash` if the default model is overloaded.
5. **If sword is missing in some frames** — add: "The Thorn Sword MUST be visible and held in the character's hand in EVERY frame. The sword does not disappear between frames."
6. **If the swing arc is not visible** — add: "Frame 3 MUST show the sword at full extension with the blade tip clearly reaching toward the swing direction. Include 3-5 faded grey pixels trailing behind the blade tip to show the slash motion arc."
7. **If character looks identical to idle** — add: "This is an ATTACK animation. The character's body MUST clearly lean, coil, and lunge during Frames 1–4. Frame 2 should look noticeably different from Frame 1 — the sword is raised high and the body is coiled."
8. **If output is wrong size** — add: "Do NOT upscale. The final PNG must be exactly 192 pixels wide and 48 pixels tall."
9. **If the blade trail looks like a solid shape** — add: "The motion trail behind the blade tip should be 3-5 individual 1-pixel dots or a dithered/faded arc — NOT a solid filled shape. Use a lighter, 50% opacity version of the blade color."
10. **If the sword design is inconsistent across frames** — add: "The sword must look identical in every frame: same blade length (~12px), same vine-wrapped handle (~6px), same small crossguard. Only the ANGLE and POSITION of the sword changes between frames."
