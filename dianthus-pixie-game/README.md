# Dianthus Pixie

A 2D Survival Crafting Action Game built with Godot 4.x

## Project Structure

```
dianthus-pixie-game/
├── assets/                    # Game assets (not tracked by Godot VCS)
│   ├── aseprite/source/      # Aseprite source files
│   ├── music/                # Background music
│   ├── sfx/                  # Sound effects
│   └── sprites/              # All game sprites
│       ├── player/           # Player character
│       ├── enemies/          # Enemy characters
│       ├── plants/           # Defense plants
│       ├── weapons/          # Weapons/items
│       ├── items/            # Inventory items
│       ├── environment/      # World tiles/objects
│       └── ui/               # UI elements
├── autoloads/               # Godot autoload/singleton scripts
│   ├── managers/            # Game managers (GameManager, AudioManager)
│   ├── services/            # Service scripts (SaveService, QuestService)
│   └── state/               # Global state (PlayerState, WorldState)
├── docs/                    # Documentation (ignored by Godot)
│   ├── design/              # Design docs
│   └── references/           # Reference materials
├── entities/                # Scene files for game entities
│   ├── dianthus_core/       # The core plant entity
│   ├── enemies/             # Enemy scenes
│   ├── plants/              # Placeable plant scenes
│   ├── player/              # Player scene
│   ├── projectiles/         # Projectile scenes
│   └── world_objects/       # Interactive objects
├── minigames/               # Minigame scenes (breeding, crafting, harvesting)
├── resources/               # Godot resource files
│   ├── textures/            # Texture resources
│   ├── animations/          # Animation resources
│   ├── audio/               # Audio bus/layouts
│   ├── fonts/               # Custom fonts
│   ├── tilesets/            # Tileset resources
│   ├── shaders/             # Shader materials
│   ├── particles/           # Particle effects
│   └── export_presets/      # Export configuration
├── scenes/                  # Main game scenes
│   ├── zones/               # World zones (Meadow Edge, Dusk Forest, etc.)
│   ├── garden/              # Garden/home base scenes
│   ├── transitions/         # Scene transition effects
│   └── ui/                  # UI scene files
├── scripts/                 # Script files
│   ├── utils/               # Utility functions
│   ├── globals/             # Global constants/helpers
│   ├── data/                # Data structures (resources, JSON)
│   ├── components/          # Reusable components
│   └── constants/           # Game constants
├── systems/                 # Core game systems
│   ├── day_night/           # Day-night cycle system
│   ├── crafting/            # Crafting system
│   ├── combat/              # Combat system
│   ├── fsm/                 # Finite State Machine for AI
│   ├── quest/               # Quest system
│   ├── inventory/           # Inventory system
│   ├── save/                # Save/load system
│   ├── breeding/            # Plant breeding system
│   └── planting/            # Plant placement system
├── tests/                   # Test files
│   ├── unit/                # Unit tests
│   └── integration/         # Integration tests
├── ui/                      # UI scripts and scenes
│   ├── hud/                 # HUD elements (HP bars, hotbar, minimap)
│   ├── menus/               # Menus (pause, main menu, settings)
│   ├── components/          # Reusable UI components
│   └── minigames/           # Minigame UI
└── .godot/                  # Godot engine files (auto-generated)
```

## Core Systems

- **Day-Night Cycle**: 3-phase system (Exploration → Preparation → Defense)
- **Plant Breeding**: Cross-breeding system for creating hybrid plants
- **Combat**: Real-time action combat with plant-based weapons
- **FSM AI**: Enemy behavior using Finite State Machine
- **Defense Phase**: Tower defense-style garden protection

## GDD Reference

See `../Dianthus Pixie GDD.md` for full game design document.
