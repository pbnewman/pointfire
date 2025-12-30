# Godot 4.4 Project Rules
- **Environment**: Godot 4.4+ (GDScript)
- **Style Guide**: Follow official Godot GDScript style guide (PascalCase for classes, snake_case for functions/variables).
- **Node Access**: Use `%UniqueNodeNames` for frequently accessed UI or internal nodes.
- **Signals**: Use the new `signal_name.connect(_on_callback)` syntax.
- **Physics**: Always use `_physics_process(delta)` for movement logic.
- **Typing**: Use static typing everywhere (`var speed: float = 5.0`).
- **Forbidden**: Do not use `yield` (use `await`), `setget` (use properties), or `KinematicBody` (use `CharacterBody3D`).

## Architecture Patterns
- **Component-Based**: Keep logic in small scripts (e.g., `HealthComponent.gd`) rather than one giant `Player.gd`.
- **Resources**: Use `.tres` Resource files for weapon stats (damage, fire_rate) to keep data separate from logic.