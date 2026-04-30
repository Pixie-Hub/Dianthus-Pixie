# Dianthus Pixie UI Design Brief

Use this document as the design prompt for Stitch AI. The goal is to create a coherent UI direction for **Dianthus Pixie**, a 2D pixel-art survival-crafting action game about protecting a mystical Dianthus Core through exploration, plant alchemy, crafting, and night defense.

## Product Goal

Design a complete game UI system for a **2D pixel-art survival crafting action game** built in Godot. The UI should feel like a practical adventure overlay made for repeated gameplay, not a marketing landing page.

The player loop is:

1. Explore during the day and gather resources.
2. Return to the garden to craft weapons and cross-breed plants.
3. Prepare defenses around the Dianthus Core.
4. Survive enemy waves at night.
5. Earn resources, progress quests, unlock plants, and continue to the next day.

The UI must support fast reading during combat, calm planning during crafting, and a botanical fantasy identity across every screen.

## Core Theme

**Botanical alchemy under survival pressure.**

The game blends:

- Natural garden materials: wood, vines, leaves, roots, petals, pollen, soil.
- Mystical Dianthus energy: glowing pink-white core light, soft bloom, living aura.
- Day-night survival tension: warm exploration by day, cold dangerous defense at night.
- Crafting and experimentation: plant extracts, recipes, hybrid discoveries, resource grids.

The UI should feel handmade, grounded, and alive. It can be ornate in small details, but primary gameplay information must stay readable.

## Visual Style

- 2D pixel art UI, compatible with a 16x16 tile world and 16x24 character sprites.
- Traditional screen overlay UI, not fully diegetic.
- Natural wood-panel frames with subtle carved or layered edges.
- Rounded corners should be modest, around 2-4 px in pixel-art scale.
- Use crisp pixel borders, small highlights, and shadow separation.
- Avoid glossy mobile-game buttons, sci-fi panels, glassmorphism, large gradients, and generic fantasy parchment.
- Use decorative botanical motifs sparingly: vines, tiny petals, thorn corners, seed icons, leaf separators.
- UI should remain clean at a 640x360 base gameplay resolution.

## Color Direction

Use two mood palettes that can share one component system.

### Day / Exploration

- Warm grass green.
- Soft leaf green.
- Golden yellow.
- Sky blue accent.
- Natural brown wood.
- Cream text.

Suggested feel: safe, readable, vibrant, alive.

### Night / Defense

- Desaturated blue-gray.
- Deep violet.
- Dark cool green.
- Danger red accents.
- Pink-white Dianthus glow.
- Gold highlight for interactable UI.

Suggested feel: tense, colder, protective, urgent.

### Functional Colors

- Player HP: red, with an icon so it is not color-only.
- Dianthus Core HP: glowing green with pink-white core accent.
- Energy: blue/teal.
- Warnings: red-orange.
- Selected / active / confirmed: warm gold.
- Locked / unavailable: muted gray-brown.
- Discovered plant: plant-specific swatch.
- Unknown plant or recipe: dark muted gray with question mark styling.

## Typography

- Use a readable pixel font or pixel-compatible display style.
- Main titles can be expressive, but gameplay values must be simple and clear.
- Avoid overly decorative fonts for inventory counts, quest objectives, timers, HP, or resource costs.
- Font sizes should feel compact because the game targets a low base resolution.
- Use uppercase for major menu titles and small labels where helpful.

## UI Tone

The UI should communicate:

- "This is a living garden that must be protected."
- "Plants, crafting, and survival are connected."
- "Night is dangerous, but the interface stays disciplined."

It should not feel:

- Futuristic.
- Corporate.
- Minimalist to the point of losing theme.
- Overgrown with decoration that fights gameplay readability.
- Like a generic medieval RPG.

## Required Screens To Design

Create a consistent visual system across these screens.

### 1. Main Menu

Purpose: welcome the player into the garden and establish the Dianthus Core as the central identity.

Elements:

- Game title: "Dianthus Pixie".
- Continue.
- New Game.
- Settings.
- Quit.
- Subtle background based on a garden at dusk or the Dianthus Core glowing in darkness.
- Button states: normal, hover/focus, pressed, disabled.

Direction:

- First screen should show the Dianthus Core or garden immediately.
- Use wood and glowing floral accents.
- Keep the layout simple and playable, not a marketing hero page.

### 2. Gameplay HUD

Purpose: fast combat and exploration readability.

Required HUD elements:

- Player HP bar, top-left.
- Energy meter below player HP.
- Dianthus Core HP bar, larger and top-center.
- Time-of-day indicator, top-right.
- Hotbar, bottom-right: two weapon slots and one active skill slot.
- Minimap, bottom-left.
- Wave counter above minimap during night.
- Tracked quest or tutorial objective panel.

Direction:

- Use small wood-panel clusters.
- Core HP should feel special and more important than player HP.
- Night wave information must become more urgent without covering combat.
- Hotbar selection should be obvious through border, glow, and slot number.
- Colorblind support: add icons or symbols for HP, Core, and Energy. Do not rely on color alone.

### 3. Inventory Screen

Purpose: manage resources clearly.

Elements:

- 30-slot grid.
- Stack counts.
- Item icon / swatch.
- Item name and description panel.
- Rarity labels: Common, Uncommon, Rare.
- Close hint.

Direction:

- Centered overlay with darkened background.
- Wood or garden-storage styling.
- Resource icons should read as plant materials, sap, pollen, resin, spores, petals.
- Counts must be readable at small sizes.

### 4. Crafting Screen

Purpose: craft weapons and upgrades from plant materials.

Elements:

- Recipe list.
- Selected recipe details.
- Required materials with have/need counts.
- Result preview.
- Craft button.
- Locked/unavailable recipe state.

Direction:

- Should feel like a garden workbench or alchemist bench.
- Use gold for craftable/selected, muted gray for unavailable, red only for shortage or warning.
- Keep material requirements scan-friendly.

### 5. Cross-Breeding Screen

Purpose: combine plants and discover hybrids.

Elements:

- Input Slot A.
- Input Slot B.
- Output preview.
- Unknown result state with question mark.
- Confirm / breed button.
- Known combo display.
- Failure or success feedback state.

Direction:

- Lean into botanical alchemy: seed trays, pollen lines, living-vine connectors.
- Unknown combos should feel mysterious but readable.
- Use plant color swatches and small icons to support recognition.

### 6. Loadout Screen

Purpose: equip two weapons and one active skill.

Elements:

- Weapon slot 1.
- Weapon slot 2.
- Skill slot.
- Available weapons list.
- Equipped state.
- Locked-at-night warning.

Direction:

- Compact and functional.
- Clear distinction between weapon and skill.
- Night lock state should feel urgent but not hostile.

### 7. Quest Log

Purpose: track active, completed, and failed quests.

Elements:

- Tabs: Active, Completed, Failed.
- Quest type badge: Daily, Progress, Discovery, Story.
- Quest title.
- Objective rows with progress bars.
- Countdown for time-limited quests.
- Reward summary.

Direction:

- Use journal-like structure without becoming parchment-heavy.
- Progress bars should be clear and compact.
- Story quests can receive a pink Dianthus accent.
- Daily quests can use warm yellow.
- Discovery quests can use green.

### 8. Plant Codex

Purpose: show discovered plants and breeding knowledge.

Elements:

- Plant list.
- Discovered / undiscovered states.
- Plant role: Offensive, Defensive, Support, Hybrid.
- Effect summary.
- Radius value.
- Breeding recipe or unknown combo.
- Plant color swatch.

Direction:

- This is the most botanical screen.
- Make discovered plants feel collectible and alive.
- Undiscovered entries should use silhouettes or question marks, not blank space.
- Hybrid plants should feel more magical than base plants.

### 9. Pause Menu

Purpose: pause gameplay and navigate settings/save/main menu.

Elements:

- Resume.
- Settings.
- Save / Load.
- Main Menu.
- Quit.

Direction:

- Calm, compact overlay.
- Should preserve gameplay visibility behind a dark transparent layer.
- Keep visual style consistent with settings and difficulty selection.

### 10. Settings Screen

Purpose: practical configuration.

Elements:

- Music volume.
- SFX volume.
- Difficulty selection.
- Colorblind mode toggle.
- Tutorial toggle.
- Text speed setting.
- Back button.

Direction:

- Highly readable.
- Avoid decorative overload.
- Sliders and toggles should have clear active/inactive states.

### 11. Tutorial / Dialog UI

Purpose: guide the player without blocking the real gameplay path.

Elements:

- Tutorial callout bubble.
- Highlighted input prompt.
- Objective checklist.
- Dialog textbox style.
- Skippable tutorial notice.

Direction:

- Tutorial UI can use a brighter Dianthus pink/gold accent.
- It should sit above gameplay without hiding the action target.
- Make key prompts compact and clear.
- Dialog should support a gameplay bubble style and a larger cutscene style.

### 12. Night Survived Screen

Purpose: reward and transition after defense.

Elements:

- "Night Survived".
- Day count.
- Rewards earned.
- Continue button.

Direction:

- Relief after tension.
- Use warm sunrise accents returning over the night palette.
- Reward rows should be clear and satisfying.

### 13. Game Over / Ending Screens

Purpose: clearly communicate failure or story conclusion.

Elements:

- Game Over with days survived.
- Restart.
- Main Menu.
- Ending title.
- Ending description.
- Endless mode or leaderboard entry when relevant.

Direction:

- Game Over should feel like the Core has gone dark.
- True Ending should restore the Dianthus glow and feel hopeful.
- Survival Ending should feel unresolved but not empty.
- Discovery Ending should emphasize the living evolution of Dianthus.

## Component System

Design reusable components:

- Wood panel container.
- Compact modal panel.
- Button: normal, hover/focus, pressed, disabled.
- Icon button.
- Resource slot.
- Inventory slot.
- Hotbar slot.
- Progress bar.
- HP bar.
- Energy bar.
- Core HP bar.
- Quest objective row.
- Quest type badge.
- Plant codex row.
- Plant swatch.
- Tooltip.
- Toggle.
- Slider.
- Tab button.
- Warning banner.
- Tutorial callout.

## Layout Requirements

- Base target: 640x360 gameplay viewport.
- HUD must not cover the player, Core, enemy spawn paths, or interaction prompts.
- Menus may use centered overlays with a dark transparent backdrop.
- Touch/mobile layout is not required.
- Keyboard/controller readability matters.
- Use consistent spacing in pixel increments.
- Avoid dense text blocks in gameplay HUD.
- Keep important values visible without opening menus.

## Interaction States

For Stitch output, include visual states for:

- Button normal.
- Button hover/focus.
- Button pressed.
- Button disabled.
- Selected hotbar slot.
- Locked hotbar slot during night.
- Craftable recipe.
- Uncraftable recipe.
- Unknown recipe.
- Quest completed.
- Quest failed.
- Low player HP.
- Low Dianthus Core HP.
- Night wave active.
- Colorblind mode indicator variants.

## Icon Direction

Use simple readable pixel icons:

- Heart or body icon for player HP.
- Dianthus flower/core icon for Core HP.
- Teal spark/drop for energy.
- Sun and moon for time of day.
- Sword, bomb, whip, shield for weapon categories.
- Leaf, thorn, sap drop, spore, resin shard, pollen for resources.
- Scroll/list for quests.
- Book/flower for codex.
- Gear for settings.
- Door/arrow for exit.

Icons should support color but remain identifiable in silhouette.

## Screen-Specific Mood Notes

- Exploration UI: warm, stable, resource-forward.
- Preparation UI: focused on crafting, loadout, placement, and choices.
- Night UI: colder, stronger warning contrast, wave information visible.
- Discovery UI: richer plant colors and magical accents.
- Story UI: more Dianthus pink-white glow, less clutter.

## Accessibility Requirements

- Do not communicate critical information through color alone.
- Add icons or labels alongside HP, Energy, Core HP, status warnings, and phase indicators.
- Keep text high contrast against panels.
- Avoid tiny body text in menus.
- Ensure selected/focused UI elements are visually obvious.
- Avoid red/green-only comparisons for availability.

## Stitch AI Output Request

Generate a cohesive UI design system for Dianthus Pixie with:

1. A style guide covering palette, typography, icon style, panels, buttons, bars, slots, tabs, and overlays.
2. High-fidelity mockups for the required screens listed above.
3. HUD variants for day/exploration, preparation, and night defense.
4. Component states for normal, selected, disabled, warning, locked, and colorblind-friendly variants.
5. Pixel-art-friendly proportions suitable for a Godot game at 640x360 base resolution.
6. A short implementation note for each major screen explaining layout hierarchy and important visual states.

Prioritize readability and consistent interaction patterns over decorative complexity. The UI must feel like it belongs to a living botanical survival game centered on the Dianthus Core.
