# Gemini Image Generation Prompt — Dianthus Pixie Sword Idle Sprite

## Style Rules

```
- Strict pixel art — no anti-aliasing, no gradients, no soft edges, no sub-pixel rendering
- Exactly 32 pixels wide x 48 pixels tall
- Transparent (checkerboard) background — no solid background color
- Limited palette: approximately 8-12 colors total (use colors from reference + sword blade grey)
- Clean, readable silhouette at native 32x48 resolution
- 1-pixel dark outline around the character and weapon for readability
- Output: a single PNG image, 32x48 pixels, transparent background, no upscaling, no smoothing, no filtering
- Art direction: 2D pixel art for a fantasy survival crafting game with a Southeast Asian botanical theme
- Front-facing idle pose, standing upright, character holds the Thorn Sword in a ready/guard position
- The character must be fully contained within the 32x48 pixel canvas with no cropping
```

---

## Prompt

> **Attach:** `player/sprites/PNG/player_idle_down.png`

```
I am attaching a 32x48 pixel art character sprite (front-facing unarmed idle pose). Using this exact character as the base, create a front-facing sword idle pose sprite.

This is the player character for a 2D pixel art survival crafting game. The character is a young plant alchemist — a nature-themed adventurer who tends a magical garden and fights creatures at night.

Add the Thorn Sword to the character's right hand (viewer's right). The Thorn Sword is a short, slightly curved single-handed blade with thorned vines wrapped around the handle and a faint pink-green glow at its edge.

Design details:
- Head (top ~8 rows): a soft hood or headwrap in muted green with small pink dianthus flower accents (2-3 pink pixels) on the hood's front or sides, with visible face beneath — simple dot eyes and a skin-tone face. Hair peeking out from under the hood in dark brown or black.
- Torso (middle ~8 rows): a layered outfit — inner tunic in warm cream/off-white, outer cloak/vest in forest green with a subtle leaf or vine motif (1-2 accent pixels). A small brown leather satchel or pouch on the hip.
- Legs and feet (bottom ~8 rows): simple brown trousers and darker brown boots. Feet should be 2-3 pixels wide for a grounded stance.
- Weapon: The Thorn Sword is held in the right hand (viewer's right) at a diagonal guard position — hilt near hip level, blade angled outward to the right at ~45 degrees (pointing AWAY from the character's body toward the right edge of the canvas, NOT inward toward the character's center). The blade is short (~10-12 pixels visible in front-facing view), slightly curved, with a faint 1-pixel pink or green glow dot at the blade tip. The handle is wrapped in dark thorned vines (5-6 pixels visible). A small leather crossguard (3 pixels wide) separates handle and blade.

The overall silhouette should be compact and readable. The character should look like a nature-themed adventurer — earthy tones, practical clothing, with small botanical accents, now equipped for combat.

Front-facing idle pose, standing upright, sword held in ready diagonal guard position.

Color palette:
- Skin: warm tan (#C8956E, #A87048)
- Hood/cloak: forest green (#4A7A3A, #3D6430), dark green shadow (#2A4820)
- Dianthus flower accents: pink/magenta (#FF9EC8, #FF6B9D, #E84A7F)
- Tunic: warm cream (#E8D8B8, #D4C4A0)
- Satchel/belt: brown leather (#8C6030, #6B4420)
- Trousers: earthy brown (#7A6040, #5C4830)
- Boots: dark brown (#3D2A18, #2A1C10)
- Hair: dark brown (#2A1810)
- Eyes: dark (#1A1008)
- Thorn Sword blade: cool steel grey (#A8B8C0, #7898A8)
- Thorn Sword handle wrap: dark green (#2A4820) with tiny thorn highlights (#D4C4A0)
- Thorn Sword crossguard: brown leather (#8C6030)
- Sword glow pixel: use existing pink (#FF9EC8) or green (#4A7A3A) from palette
- Outline: near-black (#1A1410)

Output: a single PNG image, exactly 32x48 pixels, transparent background, no upscaling, no smoothing.

Rules:
- Strict pixel art, no anti-aliasing, no gradients, no soft edges
- Use ONLY the colors from the attached reference image — do not add new colors except for the sword blade grey (#A8B8C0, #7898A8)
- Keep the 1-pixel dark outline on the character AND the sword
- Character and sword must remain within the 32x48 canvas
- Satchel, hood flower accents, all clothing details must be identical to the reference
- The sword design (vine handle, curved blade, crossguard, tip glow pixel) must be clearly visible
- Output: single PNG, exactly 32x48 pixels, transparent background, no upscaling, no smoothing
```

---

## Usage Notes

- Import into Godot as `Texture2D`.
- In the Godot import settings set **Filter** to `Nearest` (no interpolation) so the sprite stays crisp.
- Store at `player/sprites/PNG/Sword_Idle/player_sword_idle_down.png`.
- This sprite will be used as the base reference for the sword idle animation frames and sword attack animations.

## Troubleshooting — "Model Provider Unreachable"

If Gemini returns a network error or "model provider unreachable":

1. **Retry after 30-60 seconds** — transient TCP resets are common with Google API endpoints.
2. **Shorten the prompt** — use the compact version below if the full prompt times out.
3. **Use Gemini via browser (AI Studio)** — paste the prompt at https://aistudio.google.com instead of API calls.
4. **Switch model** — try `gemini-2.0-flash-exp` or `gemini-2.0-flash` if the default model is overloaded.
5. **Check region** — Google endpoints may be throttled in some regions; a VPN to US/EU can help.

### Compact Fallback Prompt

> **Attach:** `player/sprites/PNG/player_idle_down.png`

```
Using the attached 32x48 pixel art sprite (front-facing unarmed idle) as the exact base, create a front-facing sword idle pose. Add the Thorn Sword to the right hand at diagonal guard (~45°, pointing OUTWARD to the right edge of the canvas AWAY from the character's center, NOT inward). 32x48 PNG, transparent background, strict pixel art, no anti-aliasing. Thorn Sword: short curved blade (~10-12px), vine-wrapped dark handle (~5-6px), small leather crossguard, faint glow pixel at tip. Same character colors from reference + sword blade grey #A8B8C0. No upscaling.
```
