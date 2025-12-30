# Pointfire

A 5v5 tactical arena shooter built in Godot 4.4, inspired by Tarkov Arena with an emphasis on fun, aesthetic, and skillful gameplay.

## Vision

Pointfire aims to deliver tight, tactical gunplay with weighted movement mechanics in a dark, grimy low-poly aesthetic. The game features round-based elimination matches, meaningful progression through cosmetics and weapon unlocks, and scenario-based game modes.

## Current Status: Phase 2 Complete (Prototype)

### Implemented Features

**Movement System**
- Weighted, tactical movement with acceleration/deceleration
- Sprint, crouch, and jump
- Crouch affects collision height and camera position
- Movement speed affected by equipped weapon weight

**Weapon System**
- Hitscan shooting with spread/accuracy
- Aim Down Sights (ADS) with FOV zoom
- Recoil with recovery
- Magazine system with reload
- Damage falloff over distance
- Headshot/body/limb damage multipliers

**Weapons Available**
| Weapon | Type | Damage | Fire Rate | Weight |
|--------|------|--------|-----------|--------|
| AR-15 | Assault Rifle | 32 | Auto | Medium |
| MP5 | SMG | 24 | Auto (Fast) | Light |
| M24 | Sniper | 85 | Bolt-Action | Heavy |

**UI/HUD**
- Dynamic crosshair (expands with spread)
- Ammo counter
- Hit markers (white body, red headshot)
- Reload indicator

**Visual Effects**
- Muzzle flash
- Bullet impact sparks

## Controls

| Key | Action |
|-----|--------|
| WASD | Move |
| Shift | Sprint |
| Ctrl | Crouch |
| Space | Jump |
| Mouse | Look |
| Left Click | Shoot |
| Right Click | Aim Down Sights |
| R | Reload |
| Escape | Toggle mouse capture |

## Project Structure

```
pointfire/
├── scenes/
│   ├── characters/     # Player and bot scenes
│   ├── weapons/        # Weapon effects (muzzle flash, impacts)
│   ├── maps/           # Game maps
│   ├── ui/             # HUD and menus
│   └── game/           # Game management scenes
├── scripts/
│   ├── components/     # Reusable components (health, movement, weapon)
│   ├── weapons/        # Weapon logic and data
│   ├── player/         # Player controller
│   ├── ai/             # Bot AI (planned)
│   ├── managers/       # Game/round management (planned)
│   └── ui/             # UI scripts
├── resources/
│   └── weapons/        # Weapon stat definitions (.tres)
└── assets/             # Models, textures, audio
```

## Architecture

The project follows a **component-based architecture**:

- **MovementComponent** - Handles all movement logic
- **WeaponComponent** - Manages shooting, reloading, ADS, recoil
- **HealthComponent** - Tracks health and damage (Phase 3)
- **ArmorComponent** - Damage absorption (Phase 3)

Weapon stats are defined as **Resource files** (.tres) for easy balancing without code changes.

## Requirements

- Godot 4.4+
- No external dependencies

## Getting Started

1. Clone the repository
2. Open the project in Godot 4.4+
3. Press F5 to run the game
4. Move around the test arena and shoot at walls/cover

## Development Roadmap

- [x] **Phase 1**: Foundation & Player Movement
- [x] **Phase 2**: Weapons & Shooting
- [ ] **Phase 3**: Health & Damage System
- [ ] **Phase 4**: Game Loop & Teams
- [ ] **Phase 5**: AI & Bots
- [ ] **Phase 6**: Content & Equipment
- [ ] **Phase 7**: Polish & Feel
- [ ] **Phase 8**: Main Menu & Game Flow

### Future Features

- Round-based 5v5 team deathmatch
- Bot AI for single-player matches
- Additional game modes (bomb plant, hostage rescue, heist)
- Weapon attachments system
- Equipment (grenades, flashbangs)
- Progression system with cosmetics and unlocks
- Multiplayer networking
- Advanced movement (inertia, vaulting, leaning)

## Code Style

Following the Godot GDScript style guide:
- PascalCase for classes
- snake_case for functions and variables
- Static typing everywhere
- `_physics_process()` for movement
- Signals with `.connect()` syntax

## Documentation

- `GAME_DESIGN.md` - Full game design document
- `ARCHITECTURE.md` - Technical architecture details
- `MVP_ROADMAP.md` - Development phases and tasks

## License

[Add your license here]
