extends Node
## Singleton that manages overall game state, teams, and scoring.

signal match_started()
signal match_ended(winning_team: int)
signal team_score_changed(team: int, score: int)
signal player_joined_team(player: Node, team: int)

# Teams
enum Team { NONE = -1, TEAM_A = 0, TEAM_B = 1 }

# Match settings
@export var rounds_to_win: int = 5

# Match state
var current_round: int = 0
var team_a_score: int = 0
var team_b_score: int = 0
var match_active: bool = false

# Team rosters - stores player nodes
var team_a_players: Array[Node] = []
var team_b_players: Array[Node] = []

# References
var round_manager: Node = null
var spawn_manager: Node = null


func _ready() -> void:
	pass


## Initialize references after scene is loaded
func initialize(p_round_manager: Node, p_spawn_manager: Node) -> void:
	round_manager = p_round_manager
	spawn_manager = p_spawn_manager

	if round_manager:
		round_manager.round_ended.connect(_on_round_ended)


## Start a new match
func start_match() -> void:
	team_a_score = 0
	team_b_score = 0
	current_round = 0
	match_active = true

	team_score_changed.emit(Team.TEAM_A, team_a_score)
	team_score_changed.emit(Team.TEAM_B, team_b_score)

	print("[GameManager] Match started! First to %d rounds wins." % rounds_to_win)
	match_started.emit()

	if round_manager:
		round_manager.start_round()


## Called when a round ends
func _on_round_ended(winning_team: int, _reason: String) -> void:
	# Award point to winning team
	match winning_team:
		Team.TEAM_A:
			team_a_score += 1
			team_score_changed.emit(Team.TEAM_A, team_a_score)
		Team.TEAM_B:
			team_b_score += 1
			team_score_changed.emit(Team.TEAM_B, team_b_score)

	print("[GameManager] Score: Team A %d - Team B %d" % [team_a_score, team_b_score])

	# Check for match end
	if team_a_score >= rounds_to_win:
		_end_match(Team.TEAM_A)
	elif team_b_score >= rounds_to_win:
		_end_match(Team.TEAM_B)
	else:
		# Continue to next round after delay
		await get_tree().create_timer(3.0).timeout
		if match_active and round_manager:
			round_manager.start_round()


## End the match
func _end_match(winning_team: int) -> void:
	match_active = false
	print("[GameManager] Match ended! Winner: Team %s" % _team_name(winning_team))
	match_ended.emit(winning_team)


## Add a player to a team
func add_player_to_team(player: Node, team: int) -> void:
	# Remove from any existing team first
	remove_player(player)

	match team:
		Team.TEAM_A:
			team_a_players.append(player)
		Team.TEAM_B:
			team_b_players.append(player)

	player_joined_team.emit(player, team)
	print("[GameManager] Player added to Team %s" % _team_name(team))


## Remove a player from their team
func remove_player(player: Node) -> void:
	team_a_players.erase(player)
	team_b_players.erase(player)


## Get which team a player is on
func get_player_team(player: Node) -> int:
	if team_a_players.has(player):
		return Team.TEAM_A
	elif team_b_players.has(player):
		return Team.TEAM_B
	return Team.NONE


## Get all players on a team
func get_team_players(team: int) -> Array[Node]:
	match team:
		Team.TEAM_A:
			return team_a_players.duplicate()
		Team.TEAM_B:
			return team_b_players.duplicate()
	return []


## Get all alive players on a team
func get_alive_players(team: int) -> Array[Node]:
	var players: Array[Node] = []
	var roster: Array[Node] = get_team_players(team)

	for player in roster:
		if is_instance_valid(player) and player.has_node("HealthComponent"):
			var health: HealthComponent = player.get_node("HealthComponent")
			if not health.is_dead:
				players.append(player)

	return players


## Count alive players on a team
func count_alive_players(team: int) -> int:
	return get_alive_players(team).size()


## Get team name as string
func _team_name(team: int) -> String:
	match team:
		Team.TEAM_A: return "A"
		Team.TEAM_B: return "B"
		_: return "None"


## Get current score as formatted string
func get_score_string() -> String:
	return "%d - %d" % [team_a_score, team_b_score]
