extends Node
class_name GameController
## Scene-level controller that initializes and coordinates game systems.
## Place this node in your map scene.

@export_group("Spawn Points")
@export var team_a_spawns: Node
@export var team_b_spawns: Node

@export_group("Settings")
@export var auto_start_match: bool = true
@export var rounds_to_win: int = 5

# Child managers
@onready var round_manager: RoundManager = $RoundManager
@onready var spawn_manager: SpawnManager = $SpawnManager

# References
var player: Node = null


func _ready() -> void:
	# Wait a frame for everything to initialize
	await get_tree().process_frame

	_setup_managers()
	_setup_spawn_points()
	_find_and_register_player()
	_connect_signals()

	if auto_start_match:
		# Small delay before starting
		await get_tree().create_timer(1.0).timeout
		start_match()


func _setup_managers() -> void:
	# Initialize GameManager (autoload)
	if GameManager:
		GameManager.rounds_to_win = rounds_to_win
		GameManager.initialize(round_manager, spawn_manager)

	# Initialize RoundManager
	if round_manager:
		round_manager.initialize(GameManager, spawn_manager)

	# Initialize SpawnManager
	if spawn_manager:
		spawn_manager.initialize(GameManager)


func _setup_spawn_points() -> void:
	if not spawn_manager:
		return

	# Add Team A spawn points
	if team_a_spawns:
		for child in team_a_spawns.get_children():
			if child is Node3D:
				spawn_manager.add_spawn_point(child, GameManager.Team.TEAM_A)

	# Add Team B spawn points
	if team_b_spawns:
		for child in team_b_spawns.get_children():
			if child is Node3D:
				spawn_manager.add_spawn_point(child, GameManager.Team.TEAM_B)


func _find_and_register_player() -> void:
	# Find the player in the scene
	player = get_tree().get_first_node_in_group("player")

	# Fallback: find by class name
	if not player:
		for node in get_tree().get_nodes_in_group(""):
			if node is PlayerController:
				player = node
				break

	# Another fallback: search children of parent
	if not player:
		var parent: Node = get_parent()
		if parent:
			player = parent.get_node_or_null("Player")

	if player:
		# Add player to Team A for now (will be selectable later)
		GameManager.add_player_to_team(player, GameManager.Team.TEAM_A)

		# Connect player death to round manager
		if player.has_node("HealthComponent"):
			var health: HealthComponent = player.get_node("HealthComponent")
			health.died.connect(_on_player_died.bind(player))

		print("[GameController] Player registered to Team A")
	else:
		push_warning("[GameController] No player found in scene!")


func _connect_signals() -> void:
	if round_manager:
		round_manager.round_started.connect(_on_round_started)
		round_manager.round_ended.connect(_on_round_ended)

	if GameManager:
		GameManager.match_ended.connect(_on_match_ended)


func _on_player_died(killer: Node, player_node: Node) -> void:
	if round_manager:
		round_manager.on_player_died(player_node, killer)


func _on_round_started(round_number: int) -> void:
	print("[GameController] Round %d starting!" % round_number)


func _on_round_ended(winning_team: int, reason: String) -> void:
	var team_name: String = "A" if winning_team == 0 else ("B" if winning_team == 1 else "Draw")
	print("[GameController] Round ended - Team %s wins (%s)" % [team_name, reason])


func _on_match_ended(winning_team: int) -> void:
	var team_name: String = "A" if winning_team == 0 else ("B" if winning_team == 1 else "Draw")
	print("[GameController] MATCH OVER - Team %s wins!" % team_name)


## Manually start a match
func start_match() -> void:
	if GameManager:
		GameManager.start_match()
