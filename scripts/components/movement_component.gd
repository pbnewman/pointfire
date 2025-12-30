extends Node
class_name MovementComponent
## Handles weighted tactical movement for characters.
## Attach to a CharacterBody3D parent.

signal movement_state_changed(state: String)
signal footstep(is_sprinting: bool)

# Movement states
enum State { IDLE, WALKING, SPRINTING, CROUCHING, AIRBORNE }

# Node references
var body: CharacterBody3D

# Configuration - Base values
@export_group("Base Movement")
@export var base_speed: float = 5.0
@export var sprint_multiplier: float = 1.6
@export var crouch_multiplier: float = 0.5
@export var jump_velocity: float = 4.5

@export_group("Weighted Movement")
@export var acceleration: float = 8.0  # How fast we reach target speed
@export var deceleration: float = 10.0  # How fast we stop
@export var air_control: float = 0.3  # Movement control while airborne

@export_group("Weight System")
@export var current_weight: float = 1.0  # Affects movement speed (1.0 = normal)
@export var weight_speed_penalty: float = 0.1  # Speed reduction per weight unit above 1.0

# State tracking
var current_state: State = State.IDLE
var _previous_state: State = State.IDLE
var velocity: Vector3 = Vector3.ZERO
var is_sprinting: bool = false
var is_crouching: bool = false

# Footstep timing
var _footstep_timer: float = 0.0
var _footstep_interval_walk: float = 0.5
var _footstep_interval_sprint: float = 0.35

# Gravity
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	# Get parent CharacterBody3D
	body = get_parent() as CharacterBody3D
	if not body:
		push_error("MovementComponent must be a child of CharacterBody3D")


func _physics_process(delta: float) -> void:
	if not body:
		return

	_apply_gravity(delta)
	_update_state()
	_emit_footsteps(delta)


## Process movement input and return the resulting velocity.
## Call this from the player controller with input direction.
func process_movement(input_dir: Vector2, delta: float) -> Vector3:
	if not body:
		return Vector3.ZERO

	var target_speed: float = _calculate_target_speed()
	var direction: Vector3 = _get_movement_direction(input_dir)

	# Calculate target velocity
	var target_velocity: Vector3 = direction * target_speed

	# Apply acceleration/deceleration (weighted movement feel)
	var accel: float = acceleration if direction.length() > 0 else deceleration

	# Reduce control in air
	if not body.is_on_floor():
		accel *= air_control

	# Interpolate velocity for weighted feel
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta * 10.0)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta * 10.0)

	return velocity


## Apply gravity to vertical velocity
func _apply_gravity(delta: float) -> void:
	if not body.is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0


## Attempt to jump. Returns true if jump was successful.
func jump() -> bool:
	if body and body.is_on_floor() and not is_crouching:
		velocity.y = jump_velocity
		return true
	return false


## Set sprint state
func set_sprinting(sprinting: bool) -> void:
	# Can't sprint while crouching
	if sprinting and is_crouching:
		return
	is_sprinting = sprinting


## Set crouch state
func set_crouching(crouching: bool) -> void:
	is_crouching = crouching
	# Stop sprinting when crouching
	if crouching:
		is_sprinting = false


## Set weight (affects movement speed)
func set_weight(weight: float) -> void:
	current_weight = max(0.1, weight)


## Calculate current target speed based on state and weight
func _calculate_target_speed() -> float:
	var speed: float = base_speed

	# Apply state multipliers
	if is_sprinting:
		speed *= sprint_multiplier
	elif is_crouching:
		speed *= crouch_multiplier

	# Apply weight penalty (heavier = slower)
	if current_weight > 1.0:
		var penalty: float = (current_weight - 1.0) * weight_speed_penalty
		speed *= max(0.5, 1.0 - penalty)

	return speed


## Get movement direction from input, relative to body's facing direction
func _get_movement_direction(input_dir: Vector2) -> Vector3:
	if not body:
		return Vector3.ZERO

	# Get forward and right vectors from body's rotation
	var forward: Vector3 = -body.global_transform.basis.z
	var right: Vector3 = body.global_transform.basis.x

	# Flatten to horizontal plane
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	# Calculate direction
	var direction: Vector3 = (forward * input_dir.y + right * input_dir.x).normalized()
	return direction


## Update current movement state
func _update_state() -> void:
	_previous_state = current_state

	if not body.is_on_floor():
		current_state = State.AIRBORNE
	elif velocity.length() < 0.1:
		current_state = State.IDLE
	elif is_crouching:
		current_state = State.CROUCHING
	elif is_sprinting:
		current_state = State.SPRINTING
	else:
		current_state = State.WALKING

	# Emit signal on state change
	if current_state != _previous_state:
		movement_state_changed.emit(_state_to_string(current_state))


## Emit footstep signals at appropriate intervals
func _emit_footsteps(delta: float) -> void:
	if not body.is_on_floor():
		return

	if current_state == State.IDLE:
		_footstep_timer = 0.0
		return

	var interval: float = _footstep_interval_sprint if is_sprinting else _footstep_interval_walk
	if is_crouching:
		interval *= 1.5  # Slower footsteps when crouching

	_footstep_timer += delta
	if _footstep_timer >= interval:
		_footstep_timer = 0.0
		footstep.emit(is_sprinting)


## Convert state enum to string
func _state_to_string(state: State) -> String:
	match state:
		State.IDLE: return "idle"
		State.WALKING: return "walking"
		State.SPRINTING: return "sprinting"
		State.CROUCHING: return "crouching"
		State.AIRBORNE: return "airborne"
	return "unknown"


## Get current horizontal speed
func get_current_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


## Check if currently moving
func is_moving() -> bool:
	return current_state != State.IDLE and current_state != State.AIRBORNE
