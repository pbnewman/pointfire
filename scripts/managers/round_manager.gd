extends Node
class_name RoundManager
## Manages round state, timing, and win conditions.

signal round_started(round_number: int)
signal round_ended(winning_team: int, reason: String)
signal round_state_changed(state: String)
signal timer_updated(seconds_remaining: int)
signal player_eliminated(player: Node, killer: Node)

# Round states
enum State { INACTIVE, PRE_ROUND, ACTIVE, POST_ROUND }

# Settings
@export var pre_round_time: float = 5.0  # Countdown before round starts
@export var round_time: float = 120.0    # 2 minutes per round
@export var post_round_time: float = 5.0 # Time after round ends

# State
var current_state: State = State.INACTIVE
var current_round: int = 0
var time_remaining: float = 0.0

# References
var game_manager: Node = null
var spawn_manager: Node = null


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if current_state == State.INACTIVE:
		return

	time_remaining -= delta

	if current_state == State.PRE_ROUND:
		timer_updated.emit(ceili(time_remaining))
		if time_remaining <= 0:
			_begin_active_round()
	elif current_state == State.ACTIVE:
		timer_updated.emit(ceili(time_remaining))
		if time_remaining <= 0:
			# Time ran out - determine winner by alive players
			_end_round_timeout()


## Initialize with references
func initialize(p_game_manager: Node, p_spawn_manager: Node) -> void:
	game_manager = p_game_manager
	spawn_manager = p_spawn_manager


## Start a new round
func start_round() -> void:
	current_round += 1
	print("[RoundManager] Starting Round %d" % current_round)

	# Emit round_started first so entities can respawn themselves
	round_started.emit(current_round)

	# Start pre-round countdown
	_set_state(State.PRE_ROUND)
	time_remaining = pre_round_time
	set_process(true)


## Begin the active round (after pre-round countdown)
func _begin_active_round() -> void:
	print("[RoundManager] Round %d FIGHT!" % current_round)
	_set_state(State.ACTIVE)
	time_remaining = round_time

	# Enable player controls here if needed
	_set_players_can_move(true)


## Called when a player dies during an active round
func on_player_died(player: Node, killer: Node) -> void:
	print("[RoundManager] on_player_died called, current_state: %s" % _state_to_string(current_state))
	if current_state != State.ACTIVE:
		print("[RoundManager] Ignoring death - round not active")
		return

	player_eliminated.emit(player, killer)

	# Check win condition
	_check_elimination_win()


## Check if one team has been eliminated
func _check_elimination_win() -> void:
	if not game_manager:
		print("[RoundManager] No game_manager reference!")
		return

	var team_a_alive: int = game_manager.count_alive_players(GameManager.Team.TEAM_A)
	var team_b_alive: int = game_manager.count_alive_players(GameManager.Team.TEAM_B)

	print("[RoundManager] Checking elimination - Team A alive: %d, Team B alive: %d" % [team_a_alive, team_b_alive])

	if team_a_alive == 0 and team_b_alive == 0:
		# Draw - both teams eliminated (shouldn't happen often)
		print("[RoundManager] Both teams eliminated - DRAW")
		_end_round(GameManager.Team.NONE, "draw")
	elif team_a_alive == 0:
		print("[RoundManager] Team A eliminated - Team B wins!")
		_end_round(GameManager.Team.TEAM_B, "elimination")
	elif team_b_alive == 0:
		print("[RoundManager] Team B eliminated - Team A wins!")
		_end_round(GameManager.Team.TEAM_A, "elimination")
	else:
		print("[RoundManager] Both teams still have players alive")


## End round due to timeout
func _end_round_timeout() -> void:
	if not game_manager:
		_end_round(GameManager.Team.NONE, "timeout")
		return

	var team_a_alive: int = game_manager.count_alive_players(GameManager.Team.TEAM_A)
	var team_b_alive: int = game_manager.count_alive_players(GameManager.Team.TEAM_B)

	if team_a_alive > team_b_alive:
		_end_round(GameManager.Team.TEAM_A, "timeout")
	elif team_b_alive > team_a_alive:
		_end_round(GameManager.Team.TEAM_B, "timeout")
	else:
		_end_round(GameManager.Team.NONE, "timeout_draw")


## End the current round
func _end_round(winning_team: int, reason: String) -> void:
	print("[RoundManager] Round %d ended - Team %s wins (%s)" % [
		current_round,
		"A" if winning_team == GameManager.Team.TEAM_A else ("B" if winning_team == GameManager.Team.TEAM_B else "None"),
		reason
	])

	_set_state(State.POST_ROUND)
	time_remaining = post_round_time
	set_process(false)

	# Disable player movement during post-round
	_set_players_can_move(false)

	round_ended.emit(winning_team, reason)


## Set round state
func _set_state(new_state: State) -> void:
	current_state = new_state
	var state_name: String = _state_to_string(new_state)
	round_state_changed.emit(state_name)


## Convert state to string
func _state_to_string(state: State) -> String:
	match state:
		State.INACTIVE: return "inactive"
		State.PRE_ROUND: return "pre_round"
		State.ACTIVE: return "active"
		State.POST_ROUND: return "post_round"
	return "unknown"


## Enable/disable player movement
func _set_players_can_move(can_move: bool) -> void:
	# This would disable input during pre-round
	# For now, we allow movement always for testing
	pass


## Get current state as string
func get_state_string() -> String:
	return _state_to_string(current_state)


## Check if round is active
func is_round_active() -> bool:
	return current_state == State.ACTIVE
