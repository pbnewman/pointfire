extends Control
class_name Scoreboard
## Displays match scores, round info, and player stats.
## Toggle with Tab key.

@onready var panel: PanelContainer = $Panel
@onready var round_label: Label = $Panel/VBox/RoundLabel
@onready var score_label: Label = $Panel/VBox/ScoreLabel
@onready var team_a_header: Label = $Panel/VBox/TeamsContainer/TeamAPanel/TeamAHeader
@onready var team_b_header: Label = $Panel/VBox/TeamsContainer/TeamBPanel/TeamBHeader
@onready var team_a_players: VBoxContainer = $Panel/VBox/TeamsContainer/TeamAPanel/TeamAPlayers
@onready var team_b_players: VBoxContainer = $Panel/VBox/TeamsContainer/TeamBPanel/TeamBPlayers

var is_visible: bool = false


func _ready() -> void:
	# Start hidden
	visible = false

	# Connect to GameManager signals
	if GameManager:
		GameManager.team_score_changed.connect(_on_score_changed)
		GameManager.match_started.connect(_on_match_started)
		GameManager.match_ended.connect(_on_match_ended)

	# Initial update
	_update_display()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("scoreboard"):
		_show()
	elif event.is_action_released("scoreboard"):
		_hide()


func _show() -> void:
	is_visible = true
	visible = true
	_update_display()


func _hide() -> void:
	is_visible = false
	visible = false


func _update_display() -> void:
	if not GameManager:
		return

	# Update round info
	if round_label:
		var round_manager: Node = _get_round_manager()
		if round_manager:
			round_label.text = "Round %d" % round_manager.current_round
		else:
			round_label.text = "Round 0"

	# Update score
	if score_label:
		score_label.text = GameManager.get_score_string()

	# Update team headers with scores
	if team_a_header:
		team_a_header.text = "TEAM A - %d" % GameManager.team_a_score
	if team_b_header:
		team_b_header.text = "TEAM B - %d" % GameManager.team_b_score

	# Update player lists
	_update_player_list(team_a_players, GameManager.Team.TEAM_A)
	_update_player_list(team_b_players, GameManager.Team.TEAM_B)


func _update_player_list(container: VBoxContainer, team: int) -> void:
	if not container or not GameManager:
		return

	# Clear existing entries
	for child in container.get_children():
		child.queue_free()

	# Add player entries
	var players: Array[Node] = GameManager.get_team_players(team)
	for player in players:
		if not is_instance_valid(player):
			continue

		var entry: Label = Label.new()
		var player_name: String = player.name

		# Check if alive
		var status: String = ""
		if player.has_node("HealthComponent"):
			var health: HealthComponent = player.get_node("HealthComponent")
			if health.is_dead:
				status = " [DEAD]"
				entry.modulate = Color(0.5, 0.5, 0.5)

		entry.text = "%s%s" % [player_name, status]
		entry.add_theme_font_size_override("font_size", 14)
		container.add_child(entry)

	# Add placeholder if no players
	if players.size() == 0:
		var empty: Label = Label.new()
		empty.text = "(No players)"
		empty.modulate = Color(0.5, 0.5, 0.5)
		empty.add_theme_font_size_override("font_size", 14)
		container.add_child(empty)


func _get_round_manager() -> Node:
	var game_controller: Node = get_tree().get_first_node_in_group("game_controller")
	if game_controller and game_controller.has_node("RoundManager"):
		return game_controller.get_node("RoundManager")

	# Fallback: search parent
	var parent: Node = get_parent()
	while parent:
		if parent.has_node("RoundManager"):
			return parent.get_node("RoundManager")
		parent = parent.get_parent()

	return null


func _on_score_changed(_team: int, _score: int) -> void:
	_update_display()


func _on_match_started() -> void:
	_update_display()


func _on_match_ended(_winning_team: int) -> void:
	_update_display()
	# Show scoreboard on match end
	_show()
