# Dianthus Pixie

A 2D Survival Crafting Action Game built with Godot 4.x

## Project Structure

Organized by **feature** — every folder owns all the scenes, scripts, sprites, and resources that belong to it.

```
dianthus-pixie-game/
├── assets/                          # Raw source assets (not Godot-imported)
│   ├── aseprite/                    # Aseprite source files
│   ├── music/                       # Music source files
│   └── sfx/                         # SFX source files
├── docs/                            # Documentation (ignored by Godot)
│   ├── design/                      # Design docs & task breakdown
│   └── references/                  # Reference materials
├── shared/                          # Cross-feature code and resources
│   ├── autoloads/                   # Godot singletons (GameManager, AudioManager, SaveService, QuestService)
│   ├── components/                  # Reusable scene components (HealthComponent, HitboxComponent)
│   ├── constants/                   # Game-wide constants
│   ├── fonts/                       # Custom fonts
│   └── utils/                       # Utility scripts & helpers
├── core/                            # Game foundation: flow, phases, and the Dianthus Core entity
│   ├── day_night/                   # Day-night cycle timer & phase signals
│   ├── dianthus_core/               # Core plant entity (HP, aura, destruction)
│   ├── endings/                     # Win/lose conditions & ending sequences
│   └── transitions/                 # Scene transitions (fade in/out)
├── player/                          # Player entity and all player mechanics
│   ├── scenes/                      # player.tscn
│   ├── scripts/                     # player_controller.gd, player_state.gd
│   ├── sprites/                     # Player sprite sheets
│   └── animations/                  # Player animation resources
├── combat/                          # Combat mechanics, weapons, and projectiles
│   ├── weapons/
│   │   ├── thorn_sword/             # Thorn Sword + Blazeblade upgrade
│   │   ├── spore_bomb/              # Spore Bomb + Void Grenade upgrade
│   │   ├── vine_whip/               # Vine Whip + Crystal Lash upgrade
│   │   └── petal_shield/            # Petal Shield + Iron Bloom Shield upgrade
│   └── projectiles/                 # Shared projectile scenes
├── enemies/                         # All enemy entities and AI systems
│   ├── shadowling/                  # Shadowling: 40 HP, 8 DMG
│   ├── voidrunner/                  # Voidrunner: 25 HP, 5 DMG
│   ├── stonehusk/                   # Stonehusk: 120 HP, 20 DMG
│   ├── phantom_weaver/              # Phantom Weaver: 60 HP, 12 DMG
│   ├── swarm_larva/                 # Swarm Larva: 15 HP, 3 DMG
│   ├── devourer/                    # The Devourer boss: 1200 HP
│   ├── fsm/                         # Base FSM classes for enemy AI
│   └── spawner/                     # Wave spawner
├── plants/                          # Placeable plant entities and placement system
│   ├── entities/                    # One sub-folder per plant type
│   ├── placement/                   # Grid placement logic & effect radius visualization
│   └── sprites/                     # Plant sprite sheets
├── crafting/                        # Crafting system and cross-breeding
│   ├── bench/                       # Breeding bench entity
│   ├── breeding/                    # Cross-breeding UI & algorithm
│   └── data/                        # Recipe & combo .tres resource files
├── inventory/                       # Inventory system and item data
│   ├── scripts/                     # Inventory manager, pickup logic
│   └── data/                        # Item definitions (.tres resource files)
├── world/                           # World zones, garden, and map structures
│   ├── garden/                      # Garden base scenes & expansion
│   ├── zones/
│   │   ├── meadow_edge/             # Warm/vibrant daytime zone (Day 1) — home base, night defense
│   │   ├── dusk_forest/             # Dim-light biome (unlocks Day 3) — includes Blackwater Hollow sub-area
│   │   └── ruins_of_veld/           # Ruined-city biome (unlocks Day 7) — no Core, no night defense
│   └── tilesets/                    # TileSet resources
├── quests/                          # Quest system architecture and quest data
│   ├── scripts/                     # QuestManager, quest logic
│   └── data/                        # Quest .tres resource files
├── save/                            # Save/load system
│   └── scripts/                     # SaveService, schema migration
├── minigames/                       # Standalone minigame scenes and scripts
│   ├── plant_experimentation/       # Rhythm/puzzle breeding minigame
│   ├── crafting_assembly/           # Drag-and-drop crafting minigame
│   └── harvest_qte/                 # Harvest QTE
├── ui/                              # All UI scenes and scripts
│   ├── hud/                         # HP bars, energy meter, hotbar, minimap, wave counter
│   ├── menus/                       # Main menu, pause menu, settings
│   ├── screens/                     # Inventory screen, Quest log, Plant codex
│   └── components/                  # Reusable UI components
├── audio/                           # Audio resources and management
│   ├── music/                       # Music stream resources
│   └── sfx/                         # SFX stream resources
├── vfx/                             # Visual effects, shaders, and animations
│   ├── animations/                  # Shared AnimationLibrary resources
│   ├── particles/                   # Particle effect scenes
│   └── shaders/                     # Shader materials & GLSL files
├── accessibility/                   # Difficulty scaling, colorblind mode, tutorial
│   ├── difficulty/                  # Difficulty system (Normal / Easy / Hard)
│   └── tutorial/                    # Interactive tutorial (Days 1–3)
└── tests/                           # Automated tests
    ├── unit/                        # Unit tests
    └── integration/                 # Integration tests
```

## Core Systems

- **Day-Night Cycle**: 3-phase system (Exploration → Preparation → Defense)
- **Plant Breeding**: Cross-breeding system for creating hybrid plants
- **Combat**: Real-time action combat with plant-based weapons
- **FSM AI**: Enemy behavior using Finite State Machine
- **Defense Phase**: Tower defense-style garden protection

## GDD Reference

See `../Dianthus Pixie GDD.md` for full game design document.
