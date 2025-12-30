extends Node
class_name WeaponComponent
## Handles weapon mechanics: shooting, reloading, ADS, recoil.
## Attach to a player/character node.

# Signals
signal weapon_fired(hit_position: Vector3, hit_normal: Vector3, hit_target: Node)
signal weapon_dry_fired()
signal reload_started()
signal reload_finished()
signal ammo_changed(current: int, reserve: int)
signal ads_changed(is_aiming: bool)
signal weapon_equipped(weapon_data: WeaponData)
signal hit_confirmed(damage: float, is_headshot: bool)

# Node references
var camera: Camera3D
var movement_component: MovementComponent

# Current weapon
@export var current_weapon: WeaponData
var current_ammo: int = 0
var reserve_ammo: int = 0

# State
var is_aiming: bool = false
var is_reloading: bool = false
var can_fire: bool = true
var _fire_timer: float = 0.0
var _ads_progress: float = 0.0  # 0 = hip, 1 = fully ADS

# Recoil state
var _current_recoil: Vector2 = Vector2.ZERO  # Accumulated recoil (pitch, yaw)
var _recoil_recovery_target: Vector2 = Vector2.ZERO

# Original FOV for ADS
var _base_fov: float = 90.0

# Raycast settings
const MAX_RANGE: float = 500.0

# Effect scenes (loaded at ready)
var _muzzle_flash_scene: PackedScene
var _impact_effect_scene: PackedScene


func _ready() -> void:
	# Find camera in parent hierarchy
	var parent: Node = get_parent()
	if parent:
		camera = parent.get_node_or_null("Camera3D")
		movement_component = parent.get_node_or_null("MovementComponent")

	if camera:
		_base_fov = camera.fov

	# Load effect scenes
	_muzzle_flash_scene = load("res://scenes/weapons/muzzle_flash.tscn")
	_impact_effect_scene = load("res://scenes/weapons/bullet_impact.tscn")

	# Equip initial weapon if set
	if current_weapon:
		equip_weapon(current_weapon)


func _process(delta: float) -> void:
	_update_fire_timer(delta)
	_update_ads(delta)
	_recover_recoil(delta)


## Equip a weapon from WeaponData resource
func equip_weapon(weapon_data: WeaponData) -> void:
	current_weapon = weapon_data
	current_ammo = weapon_data.magazine_size
	reserve_ammo = weapon_data.reserve_ammo
	is_reloading = false
	_current_recoil = Vector2.ZERO

	# Update movement weight
	if movement_component:
		movement_component.set_weight(weapon_data.weapon_weight)

	weapon_equipped.emit(weapon_data)
	ammo_changed.emit(current_ammo, reserve_ammo)


## Attempt to fire the weapon
func try_fire() -> void:
	if not current_weapon:
		return

	if is_reloading:
		return

	if not can_fire:
		return

	if current_ammo <= 0:
		weapon_dry_fired.emit()
		# Auto-reload on empty
		if reserve_ammo > 0:
			start_reload()
		return

	_fire()


## Internal fire logic
func _fire() -> void:
	current_ammo -= 1
	can_fire = false
	_fire_timer = current_weapon.fire_rate

	# Calculate spread
	var spread: float = _calculate_spread()

	# Perform hitscan
	var result: Dictionary = _perform_hitscan(spread)

	# Apply recoil
	_apply_recoil()

	# Spawn muzzle flash
	_spawn_muzzle_flash()

	# Emit signals and spawn impact
	if result.has("position"):
		weapon_fired.emit(result.get("position", Vector3.ZERO),
						  result.get("normal", Vector3.UP),
						  result.get("collider", null))

		# Spawn impact effect
		_spawn_impact_effect(result.get("position"), result.get("normal", Vector3.UP))

		# Calculate and apply damage if we hit something with a health component
		if result.has("collider"):
			_apply_damage(result)

	ammo_changed.emit(current_ammo, reserve_ammo)


## Spawn muzzle flash at camera position
func _spawn_muzzle_flash() -> void:
	if not _muzzle_flash_scene or not camera:
		return

	var flash: Node3D = _muzzle_flash_scene.instantiate()
	camera.add_child(flash)
	# Position slightly in front and below camera center
	flash.position = Vector3(0.3, -0.2, -0.5)


## Spawn impact effect at hit position
func _spawn_impact_effect(position: Vector3, normal: Vector3) -> void:
	if not _impact_effect_scene:
		return

	var impact: Node3D = _impact_effect_scene.instantiate()
	get_tree().current_scene.add_child(impact)
	impact.global_position = position + normal * 0.01  # Slight offset to avoid z-fighting

	# Rotate to face along the normal
	if normal != Vector3.UP and normal != Vector3.DOWN:
		impact.look_at(position + normal, Vector3.UP)
	else:
		impact.look_at(position + normal, Vector3.FORWARD)


## Calculate current spread based on state
func _calculate_spread() -> float:
	if not current_weapon:
		return 0.0

	var spread: float = current_weapon.ads_spread if is_aiming else current_weapon.hipfire_spread

	# Add movement penalty
	if movement_component and movement_component.is_moving():
		var move_penalty: float = current_weapon.movement_spread_penalty
		# Reduce penalty when ADS
		if is_aiming:
			move_penalty *= 0.5
		spread += move_penalty

	# Apply crouch bonus
	if movement_component and movement_component.is_crouching:
		spread *= current_weapon.crouch_spread_bonus

	return spread


## Perform hitscan raycast from camera center with spread
func _perform_hitscan(spread_degrees: float) -> Dictionary:
	if not camera:
		return {}

	var space_state: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state

	# Get camera transform
	var cam_transform: Transform3D = camera.global_transform

	# Calculate spread
	var spread_rad: float = deg_to_rad(spread_degrees)
	var random_spread: Vector2 = Vector2(
		randf_range(-spread_rad, spread_rad),
		randf_range(-spread_rad, spread_rad)
	)

	# Apply spread to direction
	var direction: Vector3 = -cam_transform.basis.z
	direction = direction.rotated(cam_transform.basis.x, random_spread.y)
	direction = direction.rotated(cam_transform.basis.y, random_spread.x)

	# Raycast
	var from: Vector3 = cam_transform.origin
	var to: Vector3 = from + direction * MAX_RANGE

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_parent()]  # Exclude self
	query.collide_with_bodies = true

	var result: Dictionary = space_state.intersect_ray(query)

	if result:
		result["distance"] = from.distance_to(result.position)

	return result


## Apply damage to hit target
func _apply_damage(hit_result: Dictionary) -> void:
	var target: Node = hit_result.get("collider")
	if not target:
		return

	# Determine hit location based on collision shape name or position
	var hit_location: String = _determine_hit_location(hit_result)

	# Calculate damage
	var distance: float = hit_result.get("distance", 0.0)
	var damage: float = current_weapon.calculate_damage(distance, hit_location)

	# Find health component on target or its parent
	var health_comp: Node = _find_health_component(target)
	if health_comp and health_comp.has_method("take_damage"):
		health_comp.take_damage(damage, get_parent(), hit_location)
		hit_confirmed.emit(damage, hit_location == "head")


## Determine hit location from raycast result
func _determine_hit_location(hit_result: Dictionary) -> String:
	var collider: Node = hit_result.get("collider")
	var position: Vector3 = hit_result.get("position", Vector3.ZERO)

	# Check collider name for hints
	if collider:
		var name_lower: String = collider.name.to_lower()
		if "head" in name_lower:
			return "head"
		elif "arm" in name_lower or "leg" in name_lower or "limb" in name_lower:
			return "limb"

	# Fallback: check hit height relative to target
	if collider and collider is Node3D:
		var target_pos: Vector3 = collider.global_position
		var relative_height: float = position.y - target_pos.y

		# Rough estimation based on height
		if relative_height > 1.5:
			return "head"
		elif relative_height < 0.5:
			return "limb"

	return "body"


## Find health component on node or parent
func _find_health_component(node: Node) -> Node:
	# Check node itself
	var health: Node = node.get_node_or_null("HealthComponent")
	if health:
		return health

	# Check parent
	if node.get_parent():
		health = node.get_parent().get_node_or_null("HealthComponent")
		if health:
			return health

	return null


## Apply recoil to camera
func _apply_recoil() -> void:
	if not current_weapon or not camera:
		return

	var vertical: float = current_weapon.recoil_vertical
	var horizontal: float = randf_range(
		-current_weapon.recoil_horizontal_range,
		current_weapon.recoil_horizontal_range
	)

	# Reduce recoil when ADS
	if is_aiming:
		vertical *= current_weapon.ads_recoil_multiplier
		horizontal *= current_weapon.ads_recoil_multiplier

	# Add to current recoil
	_current_recoil.x += vertical
	_current_recoil.y += horizontal

	# Apply to camera immediately
	camera.rotation.x -= deg_to_rad(vertical)
	camera.rotation.x = clamp(camera.rotation.x, -PI/2 + 0.1, PI/2 - 0.1)

	# Apply horizontal recoil to parent body
	var parent: Node3D = get_parent() as Node3D
	if parent:
		parent.rotation.y -= deg_to_rad(horizontal)


## Recover from recoil over time
func _recover_recoil(delta: float) -> void:
	if not current_weapon or not camera:
		return

	if _current_recoil.length() < 0.01:
		_current_recoil = Vector2.ZERO
		return

	# Use exponential decay for snappy recovery
	var recovery_rate: float = current_weapon.recoil_recovery_speed * delta

	# Recover vertical recoil
	var recover_amount: float = _current_recoil.x * recovery_rate
	# Ensure minimum recovery to prevent endless tiny adjustments
	if abs(_current_recoil.x) > 0.01:
		recover_amount = max(recover_amount, 0.5 * delta)
	_current_recoil.x -= recover_amount
	camera.rotation.x += deg_to_rad(recover_amount)
	camera.rotation.x = clamp(camera.rotation.x, -PI/2 + 0.1, PI/2 - 0.1)

	# Horizontal recoil recovers similarly
	var h_recover: float = _current_recoil.y * recovery_rate
	if abs(_current_recoil.y) > 0.01:
		h_recover = sign(_current_recoil.y) * max(abs(h_recover), 0.3 * delta)
	_current_recoil.y -= h_recover


## Start reload process
func start_reload() -> void:
	if not current_weapon:
		return

	if is_reloading:
		return

	if current_ammo >= current_weapon.magazine_size:
		return

	if reserve_ammo <= 0:
		return

	is_reloading = true
	reload_started.emit()

	# Wait for reload time
	await get_tree().create_timer(current_weapon.reload_time).timeout

	_finish_reload()


## Complete reload
func _finish_reload() -> void:
	if not current_weapon:
		return

	var ammo_needed: int = current_weapon.magazine_size - current_ammo
	var ammo_to_add: int = min(ammo_needed, reserve_ammo)

	current_ammo += ammo_to_add
	reserve_ammo -= ammo_to_add

	is_reloading = false
	reload_finished.emit()
	ammo_changed.emit(current_ammo, reserve_ammo)


## Set ADS state
func set_aiming(aiming: bool) -> void:
	if is_aiming == aiming:
		return

	is_aiming = aiming
	ads_changed.emit(is_aiming)


## Toggle ADS
func toggle_ads() -> void:
	set_aiming(not is_aiming)


## Update ADS progress and FOV
func _update_ads(delta: float) -> void:
	if not current_weapon or not camera:
		return

	var target: float = 1.0 if is_aiming else 0.0
	var speed: float = 1.0 / current_weapon.ads_time

	_ads_progress = move_toward(_ads_progress, target, speed * delta)

	# Interpolate FOV
	var target_fov: float = _base_fov * current_weapon.ads_fov_multiplier
	camera.fov = lerp(_base_fov, target_fov, _ads_progress)


## Update fire timer
func _update_fire_timer(delta: float) -> void:
	if not can_fire:
		_fire_timer -= delta
		if _fire_timer <= 0:
			can_fire = true
			_fire_timer = 0.0


## Get current ADS progress (0-1)
func get_ads_progress() -> float:
	return _ads_progress


## Check if weapon is ready to fire
func can_shoot() -> bool:
	return can_fire and not is_reloading and current_ammo > 0
