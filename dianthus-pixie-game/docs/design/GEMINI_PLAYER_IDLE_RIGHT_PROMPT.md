# Gemini Image Generation Prompt — Dianthus Pixie Player Sprite (Idle Right)

## Style Rules

```
- Strict pixel art — no anti-aliasing, no gradients, no soft edges, no sub-pixel rendering
- Exactly 32 pixels wide x 48 pixels tall
- Transparent (checkerboard) background — no solid background color
- Limited palette: approximately 8-12 colors total
- Clean, readable silhouette at native 32x48 resolution
- 1-pixel dark outline around the character for readability
- Output: a single PNG image, 32x48 pixels, transparent background, no upscaling, no smoothing, no filtering
- Art direction: 2D pixel art for a fantasy survival crafting game with a Southeast Asian botanical theme
- Right-facing idle pose (profile view), standing upright
- The character must be fully contained within the 32x48 pixel canvas with no cropping
```

---

## Prompt

```
Create a single 32x48 pixel art character sprite on a transparent background. This is the player character for a 2D pixel art survival crafting game, shown in a RIGHT-FACING SIDE VIEW (profile).

The character is a young plant alchemist — a nature-themed adventurer who tends a magical garden and fights creatures at night. They wear a simple hooded cloak over light clothing, with a small satchel or pouch at the hip for carrying herbs and reagents.

This is the same character as the front-facing and back-facing sprites, now shown from the right side (facing right). The silhouette width, height, and proportions must match those existing sprites exactly.

Design details for the right-facing profile:
- Head (top ~8 rows): the hood shown in profile — the front edge of the hood frames the face on the right side. One dot eye visible on the right side of the face. Skin-tone face in profile, with dark brown/black hair peeking out from under the hood on the right. A small pink dianthus flower accent (1-2 pink pixels) visible on the side of the hood.
- Torso (middle ~8 rows): the cloak/vest is visible from the side — forest green outer layer with the cream/off-white tunic peeking through at the front (right side). The brown leather satchel/pouch hangs at the hip, visible on the character's near side. One arm hangs at the side in a relaxed idle pose.
- Legs and feet (bottom ~8 rows): profile view of brown trousers and dark brown boots. Feet should face right, 2-3 pixels long for a grounded stance. Legs slightly overlapping as seen from the side.

The overall silhouette should be compact and readable at 32x48. The character faces right. The body is narrower from the side — approximately 8-10 pixels wide — centered on the 32-pixel canvas.

Color palette (must match front and back sprites exactly):
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

Output: a single PNG image, exactly 32x48 pixels, transparent background, no upscaling, no smoothing.
```

---

## Usage Notes

- Import into Godot as `Texture2D`.
- In the Godot import settings set **Filter** to `Nearest` (no interpolation) so the sprite stays crisp.
- Store at `player/sprites/PNG/player_idle_right.png`.
- The idle-left sprite can be produced by horizontally flipping this sprite in Godot (flip_h = true), so only the right-facing version is needed.

## Troubleshooting — "Model Provider Unreachable"

If Gemini returns a network error or "model provider unreachable":

1. **Retry after 30-60 seconds** — transient TCP resets are common with Google API endpoints.
2. **Shorten the prompt** — use the compact version below if the full prompt times out.
3. **Use Gemini via browser (AI Studio)** — paste the prompt at https://aistudio.google.com instead of API calls.
4. **Switch model** — try `gemini-2.0-flash-exp` or `gemini-2.0-flash` if the default model is overloaded.
5. **Check region** — Google endpoints may be throttled in some regions; a VPN to US/EU can help.

### Compact Fallback Prompt

```
Create a single 32x48 pixel art character sprite, transparent background, strict pixel art, no anti-aliasing.

A young plant alchemist in RIGHT-FACING PROFILE VIEW: green hooded cloak shown from the side with small pink dianthus flower accent, cream tunic visible at front, brown satchel at hip, brown trousers, dark boots facing right. Warm tan skin, one dot eye visible, dark hair under hood. Standing idle pose. Southeast Asian botanical fantasy theme.

Palette: skin #C8956E, cloak #4A7A3A, dianthus pink #FF9EC8, tunic #E8D8B8, leather #8C6030, boots #3D2A18, outline #1A1410.

Output: single PNG, exactly 32x48 pixels, transparent background, no upscaling.
```
