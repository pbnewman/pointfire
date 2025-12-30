# Pointfire - Technical Architecture

## Overview
Component-based architecture following Godot 4.4 best practices. Emphasis on modularity, reusability, and future multiplayer compatibility.

---

## Core Architecture Principles

### 1. Component-Based Design
- Keep scripts small and focused on single responsibilities
- Use composition over inheritance
- Example: `HealthComponent.gd`, `MovementComponent.gd`, `WeaponComponent.gd`

### 2. Data-Driven Design
- Use `.tres` Resource files for game data
- Weapon stats, player stats, round settings all defined in Resources
- Easy to balance and extend without code changes

### 3. Signal-Driven Communication
- Components communicate via signals
- Reduces coupling between systems
- Use `signal_name.connect(_on_callback)` syntax

### 4. Future-Proof for Networking
- Even in single-player prototype, structure code for multiplayer
- Separate client-side (visuals, input) from server-side (game logic)
- Validate inputs, use authoritative patterns

---

## Project Structure

```
pointfire/
├── scenes/
│   ├── characters/
│   │   ├── player.tscn
│   │   └── bot.tscn
│   ├── weapons/
│   │   ├── weapon_base.tscn
│   │   ├── assault_rifle.tscn
│   │   └── ...
│   ├── maps/
│   │   └── test_arena.tscn
│   ├── ui/
│   │   ├── hud.tscn
│   │   ├── main_menu.tscn
│   │   └── scoreboard.tscn
│   └── game/
│       └── game_manager.tscn
│
├── scripts/
│   ├── components/
│   │   ├── health_component.gd
│   │   ├── movement_component.gd
│   │   ├── weapon_component.gd
│   │   ├── armor_component.gd
│   │   └── inventory_component.gd
│   ├── weapons/
│   │   ├── weapon_base.gd
│   │   └── projectile.gd
│   ├── player/
│   │   ├── player_controller.gd
│   │   └── player_input.gd
│   ├── ai/
│   │   ├── bot_controller.gd
│   │   └── bot_behavior.gd
│   ├── managers/
│   │   ├── game_manager.gd
│   │   ├── round_manager.gd
│   │   └── spawn_manager.gd
│   └── ui/
│       ├── hud.gd
│       └── main_menu.gd
│
├── resources/
│   ├── weapons/
│   │   ├── weapon_data_base.gd (base Resource class)
│   │   ├── ak47_data.tres
│   │   ├── m4_data.tres
│   │   └── ...
│   ├── characters/
│   │   └── character_stats.tres
│   └── game/
│       └── round_settings.tres
│
├── assets/
│   ├── models/
│   ├── textures/
│   ├── audio/
│   └── ui/
│
└── GAME_DESIGN.md
└── ARCHITECTURE.md
└── CLAUDE.md
```

---

## Core Systems

### 1. Player System

#### Player Controller (`player_controller.gd`)
- Orchestrates player components
- Manages state (alive, dead, spectating)
- Team assignment

**Node Structure:**
```
Player (CharacterBody3D)
├── PlayerController (script)
├── HealthComponent
├── MovementComponent
├── WeaponComponent
├── ArmorComponent
├── Camera3D
├── CollisionShape3D
└── MeshInstance3D
```

#### Movement Component (`movement_component.gd`)
- Handles all movement logic in `_physics_process(delta)`
- Weighted movement with acceleration/deceleration
- Movement states: walk, sprint, crouch, jump
- Weapon weight affects speed
- **Properties:**
  - `base_speed: float`
  - `sprint_multiplier: float`
  - `crouch_multiplier: float`
  - `acceleration: float`
  - `deceleration: float`
  - `current_weight: float` (affected by weapon/gear)
- **Signals:**
  - `movement_state_changed(state: String)`
  - `footstep(surface_type: String, volume: float)`

#### Health Component (`health_component.gd`)
- Manages health value
- Damage calculation
- Death handling
- **Properties:**
  - `max_health: float = 100.0`
  - `current_health: float`
- **Signals:**
  - `health_changed(new_health: float)`
  - `damage_taken(amount: float, source: Node)`
  - `died(killer: Node)`
- **Methods:**
  - `take_damage(amount: float, attacker: Node, hit_location: String)`
  - `heal(amount: float)`

#### Armor Component (`armor_component.gd`)
- Absorbs damage before health
- Degrades over time
- Different armor types
- **Properties:**
  - `max_armor: float`
  - `current_armor: float`
  - `damage_reduction: float` (0.0 to 1.0)
- **Signals:**
  - `armor_changed(new_armor: float)`
  - `armor_broken()`
- **Methods:**
  - `absorb_damage(amount: float) -> float` (returns remaining damage)

---

### 2. Weapon System

#### Weapon Data Resource (`weapon_data_base.gd`)
```gdscript
extends Resource
class_name WeaponData

@export var weapon_name: String = "Weapon"
@export var damage: float = 30.0
@export var fire_rate: float = 0.1  # Time between shots
@export var magazine_size: int = 30
@export var reload_time: float = 2.0
@export var recoil_pattern: Array[Vector2] = []
@export var hipfire_spread: float = 5.0
@export var ads_spread: float = 1.0
@export var movement_speed_multiplier: float = 1.0
@export var ads_time: float = 0.25
@export var weapon_weight: float = 1.0
@export var muzzle_velocity: float = 800.0  # m/s
```

#### Weapon Component (`weapon_component.gd`)
- Manages current weapon
- Shooting logic
- Recoil application
- ADS state
- Attachment management
- **Properties:**
  - `current_weapon: WeaponData`
  - `current_ammo: int`
  - `is_aiming: bool`
  - `is_reloading: bool`
- **Signals:**
  - `weapon_fired(position: Vector3, direction: Vector3)`
  - `ammo_changed(current: int, max: int)`
  - `reload_started()`
  - `reload_finished()`
  - `ads_changed(is_ads: bool)`
- **Methods:**
  - `shoot()`
  - `reload()`
  - `toggle_ads()`
  - `equip_weapon(weapon_data: WeaponData)`

#### Projectile System
- Hitscan for bullets (raycast)
- Ballistic projectiles for grenades (RigidBody3D)
- Hit detection with damage falloff
- Surface impact effects

---

### 3. AI System

#### Bot Controller (`bot_controller.gd`)
- Uses same components as player (HealthComponent, WeaponComponent, etc.)
- Different input source (AI instead of player input)
- Shares movement/shooting code

#### Bot Behavior (`bot_behavior.gd`)
- State machine: Patrol, Search, Engage, Take Cover, Retreat
- Navigation using NavigationAgent3D
- Target acquisition and tracking
- Simple decision-making
- **States:**
  - `PATROL`: Move between waypoints
  - `SEARCH`: Look for enemies
  - `ENGAGE`: Shoot at visible enemy
  - `TAKE_COVER`: Move to cover when low health
  - `RETREAT`: Fall back when outnumbered

---

### 4. Game Management

#### Game Manager (`game_manager.gd`)
- Singleton/Autoload
- Overall game state
- Team management
- Score tracking
- **Properties:**
  - `team_a_score: int`
  - `team_b_score: int`
  - `rounds_to_win: int = 5`
  - `current_round: int`
- **Signals:**
  - `round_started(round_number: int)`
  - `round_ended(winning_team: int)`
  - `match_ended(winning_team: int)`
- **Methods:**
  - `start_match()`
  - `end_round(winning_team: int)`
  - `reset_round()`

#### Round Manager (`round_manager.gd`)
- Round timer
- Round state (pre-round, active, post-round)
- Win condition checking
- **Signals:**
  - `round_state_changed(state: String)`
  - `timer_updated(seconds_remaining: int)`

#### Spawn Manager (`spawn_manager.gd`)
- Manages spawn points
- Team-based spawning
- Respawn logic (for future modes)
- **Methods:**
  - `get_spawn_point(team: int) -> Vector3`
  - `spawn_player(player: Node, team: int)`

---

### 5. UI System

#### HUD (`hud.gd`)
- Health/armor display
- Ammo counter
- Round timer
- Teammate status
- Crosshair
- Use `%UniqueNodeNames` for UI elements

#### Scoreboard (`scoreboard.gd`)
- Team scores
- Round count
- Player stats (K/D/A)
- Toggle visibility (Tab key)

---

## Coding Standards (Per CLAUDE.md)

### GDScript Style
- **Classes**: PascalCase (`WeaponData`, `HealthComponent`)
- **Functions**: snake_case (`take_damage()`, `_physics_process()`)
- **Variables**: snake_case (`current_health`, `fire_rate`)
- **Constants**: SCREAMING_SNAKE_CASE (`MAX_HEALTH`, `TEAM_A`)

### Static Typing
Always use static typing:
```gdscript
var speed: float = 5.0
var player: CharacterBody3D
func take_damage(amount: float) -> void:
```

### Physics
- Use `_physics_process(delta)` for movement
- Use `CharacterBody3D` for characters (not KinematicBody)
- Use `move_and_slide()` for movement

### Signals
New signal syntax:
```gdscript
signal health_changed(new_health: float)

# Connect:
health_component.health_changed.connect(_on_health_changed)
```

### Async
- Use `await` instead of `yield`
- Example: `await get_tree().create_timer(1.0).timeout`

### Properties
Use properties instead of setget:
```gdscript
var health: float = 100.0:
    set(value):
        health = clamp(value, 0.0, max_health)
        health_changed.emit(health)
```

---

## Networking Preparation (Future)

Even in single-player prototype, structure for multiplayer:

### Separation of Concerns
- **Client**: Handles input, visuals, sounds
- **Server**: Game logic, validation, physics
- Keep these conceptually separate even in single-player

### Authority
- Game logic in authoritative scripts (future server)
- Visual/audio in client scripts
- Example: Damage calculation on server, blood effects on client

### Input Handling
- Player inputs captured separately
- Passed to movement/weapon components
- Easy to swap to network inputs later

---

## Development Phases

### Phase 1: Core Movement & Shooting (Week 1-2)
- Basic player CharacterBody3D
- Movement component with weighted movement
- Camera controller
- Simple weapon component
- Hitscan shooting
- Test environment

### Phase 2: Combat Systems (Week 2-3)
- Health/armor components
- Damage calculation
- Hit markers
- Death/respawn
- Weapon data resources
- Recoil patterns

### Phase 3: Game Loop (Week 3-4)
- Game manager
- Round manager
- Spawn system
- Team assignment
- Win conditions
- Basic UI (HUD, scoreboard)

### Phase 4: AI & Bots (Week 4-5)
- Bot controller
- Navigation setup
- Basic AI behaviors
- 5v5 bot matches

### Phase 5: Polish & Content (Week 5+)
- Multiple weapons
- Attachments
- Equipment (grenades)
- Map design
- Balance tweaking
- Sound integration

---

## Testing Strategy

### Unit Testing
- Test individual components in isolation
- Example: HealthComponent damage calculations
- Use Godot's built-in testing or GUT addon

### Integration Testing
- Test systems working together
- Example: Weapon firing triggers HealthComponent damage

### Playtesting
- Bot matches to test game feel
- Balance tweaking based on data
- Iteration on movement/shooting feel

---

## Performance Considerations

### Optimization Targets
- 60 FPS minimum on mid-range hardware
- Low-poly art helps immensely
- Efficient AI (limit raycasts, use timers for decisions)

### Profiling
- Use Godot profiler regularly
- Watch for performance spikes
- Optimize hot paths (movement, shooting)

### Best Practices
- Object pooling for projectiles/effects
- Frustum culling for large maps
- LOD for distant objects (future)
- Efficient collision shapes
