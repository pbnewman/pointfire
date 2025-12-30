extends Node
class_name SpawnManager
## Manages spawn points and player spawning by team.

signal player_spawned(player: Node, spawn_point: Vector3)

# Spawn point containers
@export var team_a_spawns_path: NodePath
@export var team_b_spawns_path: NodePath

var team_a_spawns: Array[Node3D] = []
var team_b_spawns: Array[Node3D] = []

# Track which spawns are used (for round-robin or random selection)
var _team_a_spawn_index: int = 0
var _team_b_spawn_index: int = 0

# References
var game_manager: Node = null


func _ready() -> void:
	# Get spawn points from paths if set
	_collect_spawn_points()


## Initialize with game manager reference
func initialize(p_game_manager: Node) -> void:
	game_manager = p_game_manager


## Collect spawn points from the scene
func _collect_spawn_points() -> void:
	# Try to get from exported paths
	if team_a_spawns_path:
		var container: Node = get_node_or_null(team_a_spawns_path)
		if container:
			for child in container.get_children():
				if child is Node3D:
					team_a_spawns.append(child)

	if team_b_spawns_path:
		var container: Node = get_node_or_null(team_b_spawns_path)
		if container:
			for child in container.get_children():
				if child is Node3D:
					team_b_spawns.append(child)

	print("[SpawnManager] Found %d Team A spawns, %d Team B spawns" % [team_a_spawns.size(), team_b_spawns.size()])


## Manually add spawn points (called from scene setup)
func add_spawn_point(spawn: Node3D, team: int) -> void:
	match team:
		GameManager.Team.TEAM_A:
			if not team_a_spawns.has(spawn):
				team_a_spawns.append(spawn)
		GameManager.Team.TEAM_B:
			if not team_b_spawns.has(spawn):
				team_b_spawns.append(spawn)


## Get next spawn point for a team (round-robin)
func get_spawn_point(team: int) -> Vector3:
	var spawns: Array[Node3D]
	var index: int

	match team:
		GameManager.Team.TEAM_A:
			spawns = team_a_spawns
			index = _team_a_spawn_index
			_team_a_spawn_index = (_team_a_spawn_index + 1) % max(1, spawns.size())
		GameManager.Team.TEAM_B:
			spawns = team_b_spawns
			index = _team_b_spawn_index
			_team_b_spawn_index = (_team_b_spawn_index + 1) % max(1, spawns.size())
		_:
			return Vector3.ZERO

	if spawns.size() == 0:
		push_warning("[SpawnManager] No spawn points for team %d" % team)
		return Vector3.ZERO

	return spawns[index].global_position


## Get spawn rotation for a team
func get_spawn_rotation(team: int) -> Vector3:
	var spawns: Array[Node3D]
	var index: int

	match team:
		GameManager.Team.TEAM_A:
			spawns = team_a_spawns
			index = max(0, _team_a_spawn_index - 1) % max(1, spawns.size())
		GameManager.Team.TEAM_B:
			spawns = team_b_spawns
			index = max(0, _team_b_spawn_index - 1) % max(1, spawns.size())
		_:
			return Vector3.ZERO

	if spawns.size() == 0:
		return Vector3.ZERO

	return spawns[index].rotation


## Spawn a specific player at their team's spawn point
func spawn_player(player: Node) -> void:
	if not game_manager:
		push_warning("[SpawnManager] No game manager reference")
		return

	var team: int = game_manager.get_player_team(player)
	if team == GameManager.Team.NONE:
		push_warning("[SpawnManager] Player not on a team")
		return

	var spawn_pos: Vector3 = get_spawn_point(team)

	# Reset player via their respawn_at method if available
	if player.has_method("respawn_at"):
		player.respawn_at(spawn_pos)
	else:
		# Fallback for non-PlayerController entities
		if player is Node3D:
			player.global_position = spawn_pos

		if player.has_node("HealthComponent"):
			var health: HealthComponent = player.get_node("HealthComponent")
			health.reset()

		if player.has_node("ArmorComponent"):
			var armor: ArmorComponent = player.get_node("ArmorComponent")
			armor.reset()

	player_spawned.emit(player, spawn_pos)
	print("[SpawnManager] Spawned player at %s" % spawn_pos)


## Respawn all players on both teams
func respawn_all_players() -> void:
	if not game_manager:
		return

	# Reset spawn indices
	_team_a_spawn_index = 0
	_team_b_spawn_index = 0

	# Spawn Team A
	for player in game_manager.get_team_players(GameManager.Team.TEAM_A):
		if is_instance_valid(player):
			spawn_player(player)

	# Spawn Team B
	for player in game_manager.get_team_players(GameManager.Team.TEAM_B):
		if is_instance_valid(player):
			spawn_player(player)


## Get a random spawn point for a team
func get_random_spawn_point(team: int) -> Vector3:
	var spawns: Array[Node3D]

	match team:
		GameManager.Team.TEAM_A:
			spawns = team_a_spawns
		GameManager.Team.TEAM_B:
			spawns = team_b_spawns
		_:
			return Vector3.ZERO

	if spawns.size() == 0:
		return Vector3.ZERO

	return spawns[randi() % spawns.size()].global_position
