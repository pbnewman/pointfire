extends CharacterBody3D
class_name PlayerController
## Main player controller. Handles input and coordinates components.

# Node references
@onready var camera: Camera3D = $Camera3D
@onready var movement: MovementComponent = $MovementComponent
@onready var weapon: WeaponComponent = $WeaponComponent
@onready var health: HealthComponent = $HealthComponent
@onready var armor: ArmorComponent = $ArmorComponent

# Camera settings
@export_group("Camera")
@export var mouse_sensitivity: float = 0.002
@export var camera_height_stand: float = 1.6
@export var camera_height_crouch: float = 1.0
@export var camera_smooth_speed: float = 10.0

# Camera state
var _camera_rotation: Vector2 = Vector2.ZERO  # x = yaw, y = pitch
var _target_camera_height: float = 1.6

# Crouch collision
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
var _stand_height: float = 2.0
var _crouch_height: float = 1.2

# Death state
var is_dead: bool = false

# Original position for round resets
var _original_position: Vector3
var _original_rotation_y: float


func _ready() -> void:
	# Store original position for round resets
	_original_position = global_position
	_original_rotation_y = rotation.y

	# Capture mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Set initial camera height
	_target_camera_height = camera_height_stand
	if camera:
		camera.position.y = camera_height_stand

	# Connect health signals
	if health:
		health.died.connect(_on_died)
		health.damage_taken.connect(_on_damage_taken)

	# Connect to round manager for respawning on new rounds
	_connect_to_round_manager()


func _connect_to_round_manager() -> void:
	await get_tree().process_frame
	var game_controller: Node = get_tree().get_first_node_in_group("game_controller")
	if game_controller and game_controller.has_node("RoundManager"):
		var round_manager: RoundManager = game_controller.get_node("RoundManager")
		round_manager.round_started.connect(_on_round_started)


func _on_round_started(_round_number: int) -> void:
	# Respawn at original position
	respawn_at(_original_position)
	rotation.y = _original_rotation_y
	_camera_rotation.x = _original_rotation_y

	# Reset ammo to full
	if weapon:
		weapon.reset_ammo()

	print("[PlayerController] Respawned for round %d" % _round_number)


func _input(event: InputEvent) -> void:
	if is_dead:
		return

	# Handle mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(event.relative)

	# Toggle mouse capture with Escape
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_handle_movement_input(delta)
	_handle_weapon_input()
	_update_camera_height(delta)

	# Apply velocity from movement component
	velocity = movement.velocity
	move_and_slide()

	# Sync velocity back (for collision response)
	movement.velocity = velocity


func _handle_weapon_input() -> void:
	if not weapon:
		return

	# Handle shooting
	if weapon.current_weapon and weapon.current_weapon.is_automatic:
		# Automatic fire - hold to shoot
		if Input.is_action_pressed("shoot"):
			weapon.try_fire()
	else:
		# Semi-auto - press to shoot
		if Input.is_action_just_pressed("shoot"):
			weapon.try_fire()

	# Handle ADS
	weapon.set_aiming(Input.is_action_pressed("aim"))

	# Handle reload
	if Input.is_action_just_pressed("reload"):
		weapon.start_reload()


func _handle_mouse_look(mouse_delta: Vector2) -> void:
	# Horizontal rotation (yaw) - rotate the body
	_camera_rotation.x -= mouse_delta.x * mouse_sensitivity
	rotation.y = _camera_rotation.x

	# Vertical rotation (pitch) - rotate the camera
	_camera_rotation.y -= mouse_delta.y * mouse_sensitivity
	_camera_rotation.y = clamp(_camera_rotation.y, -PI/2 + 0.1, PI/2 - 0.1)

	if camera:
		camera.rotation.x = _camera_rotation.y


func _handle_movement_input(delta: float) -> void:
	# Get input direction
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_backward", "move_forward")

	# Handle sprint
	movement.set_sprinting(Input.is_action_pressed("sprint"))

	# Handle crouch
	var wants_crouch: bool = Input.is_action_pressed("crouch")
	_handle_crouch(wants_crouch)

	# Handle jump
	if Input.is_action_just_pressed("jump"):
		movement.jump()

	# Process movement
	movement.process_movement(input_dir, delta)


func _handle_crouch(wants_crouch: bool) -> void:
	if wants_crouch:
		movement.set_crouching(true)
		_target_camera_height = camera_height_crouch
		_set_collision_height(_crouch_height)
	else:
		# Check if we can stand up (ceiling check)
		if _can_stand_up():
			movement.set_crouching(false)
			_target_camera_height = camera_height_stand
			_set_collision_height(_stand_height)


func _can_stand_up() -> bool:
	# Raycast upward to check for ceiling
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, _crouch_height, 0),
		global_position + Vector3(0, _stand_height + 0.1, 0)
	)
	query.exclude = [self]
	var result: Dictionary = space_state.intersect_ray(query)
	return result.is_empty()


func _set_collision_height(height: float) -> void:
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = collision_shape.shape
		capsule.height = height
		collision_shape.position.y = height / 2.0


func _update_camera_height(delta: float) -> void:
	if camera:
		camera.position.y = lerp(camera.position.y, _target_camera_height, camera_smooth_speed * delta)


## Called when player dies
func _on_died(_killer: Node) -> void:
	is_dead = true
	velocity = Vector3.ZERO

	# Tilt camera for death effect
	if camera:
		var tween: Tween = create_tween()
		tween.tween_property(camera, "rotation:z", deg_to_rad(45), 0.5)
		tween.parallel().tween_property(camera, "position:y", 0.3, 0.5)

	# Note: Respawning is now handled by SpawnManager/RoundManager


## Called when player takes damage
func _on_damage_taken(_amount: float, _attacker: Node, _hit_location: String) -> void:
	# Screen shake or damage effect could go here
	pass


## Respawn the player at a specific position
func respawn_at(spawn_pos: Vector3) -> void:
	is_dead = false

	# Reset velocity
	velocity = Vector3.ZERO
	if movement:
		movement.velocity = Vector3.ZERO

	# Reset components
	if health:
		health.reset()
	if armor:
		armor.reset()

	# Reset camera (undo death animation)
	if camera:
		camera.rotation.z = 0
		camera.position.y = camera_height_stand
	_target_camera_height = camera_height_stand

	# Ensure mouse is captured
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Move to spawn position
	global_position = spawn_pos

	print("[PlayerController] Respawned at %s" % spawn_pos)


## Respawn the player at default position (legacy)
func respawn() -> void:
	respawn_at(Vector3(-15, 1, -15))
