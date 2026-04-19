# Gemini Image Generation Prompt — Dianthus Pixie Player Sprite

## Prompt

```
Create a single 16x24 pixel art character sprite on a transparent background.

The character is a young plant alchemist — a teenager wearing a simple hooded tunic in warm green, with a small satchel bag on one hip. The hood is down, showing short, slightly messy dark hair. The character faces forward (front-facing idle pose), arms relaxed at their sides.

Style rules:
- Strict pixel art — no anti-aliasing, no gradients, no soft edges
- Exactly 16 pixels wide, 24 pixels tall
- Transparent (checkerboard) background — no solid background color
- Limited palette: approximately 8–12 colors
- Warm, vibrant daytime palette — soft greens, warm browns, muted skin tone, small accent of pink (Dianthus flower motif, e.g. a tiny pink pin or brooch on the tunic collar)
- Clean, readable silhouette — the character must be recognizable even at small scale
- No outline style (internal shading only) OR a single dark-brown pixel outline — choose whichever reads more clearly at 16x24

Color palette suggestions:
- Skin: warm beige (#C8956C or similar)
- Hair: dark brown (#3D2B1F)
- Tunic: muted sage green (#6A8C5A) with a slightly darker green shadow (#4F6B42)
- Hood edge / collar: earthy tan (#9C7A4A)
- Satchel: warm brown (#7B5935)
- Dianthus accent: soft pink (#E87BA0)
- Shoes / boots: dark brown (#3D2B1F)

Output: a single PNG image, 16×24 pixels, transparent background, no upscaling, no smoothing.
```

## Usage Notes

- Import into Godot as `Texture2D` on the player's `Sprite2D` node.
- In the Godot import settings set **Filter** to `Nearest` (no interpolation) so the sprite stays crisp at any zoom.
- The sprite is used as a **static placeholder** — animations will be added separately via AnimationTree when a full spritesheet is ready.
- Godot node path: `player/scenes/player.tscn` → `Sprite2D` (`%Sprite2D`)

## Variations to request if needed

| Variant | Change to prompt |
|---|---|
| Side-facing (right) | "faces right, walking stance, weight on left foot" |
| Back-facing | "faces away from camera, hood partially visible" |
| Hurt / flash | Keep same sprite; Godot handles the red modulate tween in code |
