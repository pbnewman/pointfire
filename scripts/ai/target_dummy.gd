extends StaticBody3D
class_name TargetDummy
## A simple target for testing weapon damage.

@export var auto_respawn: bool = true  ## If false, stays dead until manually respawned
@export var team: int = -1  ## Set to 0 or 1 to register with GameManager

@onready var health: HealthComponent = $HealthComponent
@onready var mesh: MeshInstance3D = $MeshInstance3D

var _original_color: Color
var _hit_color: Color = Color(1.0, 1.0, 1.0)
var _original_position: Vector3
var _original_rotation: Vector3


func _ready() -> void:
	# Store original position for round resets
	_original_position = global_position
	_original_rotation = rotation

	# Create a unique copy of the material so color changes don't affect other dummies
	if mesh and mesh.get_surface_override_material(0):
		var original_mat: StandardMaterial3D = mesh.get_surface_override_material(0) as StandardMaterial3D
		if original_mat:
			var unique_mat: StandardMaterial3D = original_mat.duplicate() as StandardMaterial3D
			mesh.set_surface_override_material(0, unique_mat)
			_original_color = unique_mat.albedo_color
	else:
		_original_color = Color(0.6, 0.3, 0.3)  # Default red

	if health:
		health.damage_taken.connect(_on_damage_taken)
		health.died.connect(_on_died)
		health.health_changed.connect(_on_health_changed)

	# Register with GameManager if team is set
	if team >= 0 and GameManager:
		GameManager.add_player_to_team(self, team)
		print("[TargetDummy] %s registered to Team %d" % [name, team])

	# Connect to round manager for respawning on new rounds
	_connect_to_round_manager()


func _connect_to_round_manager() -> void:
	# Wait a frame for everything to be set up
	await get_tree().process_frame
	var game_controller: Node = get_tree().get_first_node_in_group("game_controller")
	if game_controller and game_controller.has_node("RoundManager"):
		var round_manager: RoundManager = game_controller.get_node("RoundManager")
		round_manager.round_started.connect(_on_round_started)


func _on_round_started(_round_number: int) -> void:
	# Respawn at original position
	global_position = _original_position
	rotation = _original_rotation
	_respawn()
	print("[TargetDummy] %s respawned for new round" % name)


func _on_damage_taken(amount: float, _attacker: Node, hit_location: String) -> void:
	# Flash on hit
	var mat: StandardMaterial3D = _get_material()
	if mat:
		mat.albedo_color = _hit_color
		await get_tree().create_timer(0.1).timeout
		if health and not health.is_dead:
			mat = _get_material()
			if mat:
				mat.albedo_color = _original_color

	print("Target hit! Damage: %.1f, Location: %s, Health: %.1f" % [amount, hit_location, health.current_health])


func _on_died(killer: Node) -> void:
	print("[TargetDummy] %s destroyed! Team: %d" % [name, team])

	# Fall over animation
	var tween: Tween = create_tween()
	tween.tween_property(self, "rotation:x", deg_to_rad(90), 0.5)

	# Notify round manager if in a team game
	if team >= 0:
		var game_controller: Node = get_tree().get_first_node_in_group("game_controller")
		if game_controller and game_controller.has_node("RoundManager"):
			var round_manager: RoundManager = game_controller.get_node("RoundManager")
			print("[TargetDummy] Notifying RoundManager of death, state: %s" % round_manager.get_state_string())
			round_manager.on_player_died(self, killer)
		else:
			print("[TargetDummy] Could not find RoundManager!")

	# Only respawn if auto_respawn is enabled
	if auto_respawn:
		await get_tree().create_timer(3.0).timeout
		_respawn()


func _on_health_changed(current: float, max_health: float) -> void:
	# Update color based on health
	if not health.is_dead:
		var mat: StandardMaterial3D = _get_material()
		if mat:
			var health_ratio: float = current / max_health
			mat.albedo_color = _original_color.lerp(Color(0.2, 0.1, 0.1), 1.0 - health_ratio)


func _respawn() -> void:
	rotation.x = 0
	if health:
		health.reset()
	var mat: StandardMaterial3D = _get_material()
	if mat:
		mat.albedo_color = _original_color


## Called by SpawnManager to respawn at a specific position
func respawn_at(spawn_pos: Vector3) -> void:
	global_position = spawn_pos
	_respawn()


## Helper to get the mesh material
func _get_material() -> StandardMaterial3D:
	if mesh:
		return mesh.get_surface_override_material(0) as StandardMaterial3D
	return null
