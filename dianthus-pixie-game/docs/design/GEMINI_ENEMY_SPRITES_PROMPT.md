# Gemini Image Generation Prompt — Dianthus Pixie Enemy Sprites

## Global Style Rules

```
All enemy sprites share these rules:
- Strict pixel art — no anti-aliasing, no gradients, no soft edges, no sub-pixel rendering
- Exactly 32x32 pixels per sprite (small enemies) or 32x48 pixels (large enemies/boss)
- Transparent background — no solid background color
- Limited palette: ~6-10 colors per enemy
- Clean readable silhouette at sprite scale
- 1-pixel dark outline around the enemy body
- Top-down / slightly angled top-down perspective (~30 degrees)
- Output: single PNG, transparent background, no upscaling, no smoothing
- Art direction: 2D pixel art, fantasy survival crafting, Southeast Asian botanical theme
- Enemies should look menacing but readable — avoid overly complex silhouettes
- Small enemies (Shadowling, Voidrunner, Swarm Larva): 32x32 pixels
- Large enemies (Stonehusk, Phantom Weaver): 32x48 pixels
- Boss (The Devourer): 48x48 pixels
```

---

## 1. Shadowling (Basic Enemy)

```
Create a single 32x32 pixel art enemy sprite on a transparent background. Strict pixel art, no anti-aliasing.

Shadowling — small shadow creature that emerges at night. Top-down / slight angle view. Small dark blob-like creature with faint purple-blue glow at edges. 2-3 tiny glowing eyes (1-2 pixels each) arranged horizontally. Wispy tendrils trailing behind (1-2 pixel lines). Formless but menacing.

Colors: body (#1A1028, #2A1840), glow edges (#4A3070, #6B5090), eyes (#B080E0, #D0A0F0), tendrils (#3A2058), outline (#0F0818).
Output: single PNG, 32x32, transparent background, no upscaling.
```

---

## 2. Voidrunner (Fast Enemy)

```
Create a single 32x32 pixel art enemy sprite on a transparent background. Strict pixel art, no anti-aliasing.

Voidrunner — extremely fast shadow creature. Top-down / slight angle view. Elongated sleek shape like a streaking shadow. Head pointed forward, body tapered. Glowing violet eyes (2 pixels) at front. Motion blur effect with trailing pixels behind. Agile and predatory.

Colors: body (#181028, #281840), head highlight (#3A2058), eyes (#C090F0, #E0B0FF), trail (#4A3070, #6B5090 fading), outline (#0A0818).
Output: single PNG, 32x32, transparent background, no upscaling.
```

---

## 3. Stonehusk (Tank Enemy)

```
Create a single 32x48 pixel art enemy sprite on a transparent background. Strict pixel art, no anti-aliasing.

Stonehusk — slow but heavily armored rock creature. Top-down / slight angle view. Bulky rocky body with stone plating. Cracks and fissures visible (1-pixel dark lines). Small glowing core visible through cracks (orange-red). Thick limbs. Imposing and durable.

Colors: body (#4A4038, #6A5848), cracks (#2A2018), core (#FF6030, #FF8040), highlight (#8A7868), outline (#1A1810).
Output: single PNG, 32x48, transparent background, no upscaling.
```

---

## 4. Phantom Weaver (Elite Enemy)

```
Create a single 32x48 pixel art enemy sprite on a transparent background. Strict pixel art, no anti-aliasing.

Phantom Weaver — spectral spider-like creature. Top-down / slight angle view. Central body with 6-8 spindly legs radiating outward. Body semi-transparent with ghostly appearance. Glowing violet patterns on abdomen (web-like). Eyes (4 small dots) on front. Ethereal and eerie.

Colors: body (#382850, #483868), transparency (#584878), patterns (#7058A0, #9078C0), eyes (#E0B0FF), legs (#403060), outline (#181028).
Output: single PNG, 32x48, transparent background, no upscaling.
```

---

## 5. Swarm Larva (Swarm Enemy)

```
Create a single 32x32 pixel art enemy sprite on a transparent background. Strict pixel art, no anti-aliasing.

Swarm Larva — small worm-like creature. Top-down / slight angle view. Segmented body (3-4 segments). Small head with tiny mandibles (2 pixels). Dark green-brown coloration. Squirming pose — body slightly curved. Simple and numerous.

Colors: body (#3A4028, #4A5038), segments (#2A3018), head (#5A6048), mandibles (#1A1810), highlight (#6A7058), outline (#181810).
Output: single PNG, 32x32, transparent background, no upscaling.
```

---

## 6. The Devourer (Final Boss)

```
Create a single 48x48 pixel art boss enemy sprite on a transparent background. Strict pixel art, no anti-aliasing.

The Devourer — massive shadow entity, final boss. Top-down / slight angle view. Large central body with multiple tendrils/limbs radiating outward. Glowing core at center (bright violet-red). Multiple eyes (6-8 small glowing dots) around the core. Shadowy aura with wispy particles. Towering and overwhelming.

Colors: body (#0F0818, #1A1028), core (#FF4080, #FF60A0), eyes (#E0A0FF, #FFC0FF), aura (#4A3070, #6B5090), tendrils (#2A1840), outline (#080510).
Output: single PNG, 48x48, transparent background, no upscaling.
```

---

## Usage Notes

- Import each sprite into Godot as `Texture2D` with **Filter = Nearest**.
- Store at `enemies/<enemy_name>/sprites/<enemy_name>.png`.
- Replace the current placeholder `icon.svg` + `scale` in each `.tscn`.
- Small enemies (Shadowling, Voidrunner, Swarm Larva) use 32x32 sprites.
- Large enemies (Stonehusk, Phantom Weaver) use 32x48 sprites.
- Boss (The Devourer) uses 48x48 sprite.

## Color Reference (Suggested Modulate Colors)

| Enemy | Suggested Modulate | Theme |
|---|---|---|
| Shadowling | `Color(0.3, 0.1, 0.4, 1)` | Purple-black shadow |
| Voidrunner | `Color(0.2, 0.1, 0.5, 1)` | Deep violet streak |
| Stonehusk | `Color(0.4, 0.35, 0.3, 1)` | Rocky brown |
| Phantom Weaver | `Color(0.35, 0.2, 0.5, 1)` | Ghostly purple |
| Swarm Larva | `Color(0.3, 0.4, 0.2, 1)` | Worm-like green-brown |
| The Devourer | `Color(0.2, 0.05, 0.2, 1)` | Dark shadow core |

## Animation Notes (Future Work)

These prompts are for **single idle sprites only**. For future animation spritesheets:
- Follow the pattern in `GEMINI_PLAYER_DEATH_ANIM_PROMPT.md`
- Enemy animations needed: walk, attack, death, retreat
- Walk: 6 frames per direction, horizontal strip
- Attack: 3-4 frames, attack-specific motion
- Death: 4-6 frames, collapse/destroy sequence
- Retreat: 4
