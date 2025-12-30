extends CanvasLayer
class_name HUD
## Heads-up display showing crosshair, ammo, health, etc.

# Node references
@onready var crosshair: Control = $Crosshair
@onready var ammo_label: Label = $AmmoContainer/AmmoLabel
@onready var weapon_label: Label = $AmmoContainer/WeaponLabel
@onready var hit_marker: Control = $HitMarker
@onready var reload_indicator: Label = $ReloadIndicator

# Health/Armor UI
@onready var health_bar: ProgressBar = $HealthContainer/HealthBar
@onready var health_label: Label = $HealthContainer/HealthLabel
@onready var armor_bar: ProgressBar = $HealthContainer/ArmorBar
@onready var armor_label: Label = $HealthContainer/ArmorLabel
@onready var damage_overlay: ColorRect = $DamageOverlay
@onready var death_screen: Control = $DeathScreen

# Round info UI
@onready var round_info: Control = $RoundInfo
@onready var round_label: Label = $RoundInfo/RoundLabel
@onready var timer_label: Label = $RoundInfo/TimerLabel
@onready var score_label: Label = $RoundInfo/ScoreLabel
@onready var round_announcement: Label = $RoundAnnouncement

# Crosshair lines
@onready var crosshair_top: ColorRect = $Crosshair/Top
@onready var crosshair_bottom: ColorRect = $Crosshair/Bottom
@onready var crosshair_left: ColorRect = $Crosshair/Left
@onready var crosshair_right: ColorRect = $Crosshair/Right

# Crosshair settings
@export_group("Crosshair")
@export var crosshair_size: float = 8.0
@export var crosshair_gap: float = 4.0
@export var crosshair_thickness: float = 2.0
@export var crosshair_color: Color = Color.WHITE
@export var crosshair_spread_multiplier: float = 3.0

# Hit marker settings
@export_group("Hit Marker")
@export var hit_marker_duration: float = 0.15
@export var hit_marker_color: Color = Color.WHITE
@export var headshot_color: Color = Color.RED

# State
var _current_spread: float = 0.0
var _hit_marker_timer: float = 0.0
var _damage_overlay_timer: float = 0.0
var _announcement_timer: float = 0.0
var _player: Node = null
var _weapon_component: WeaponComponent = null
var _health_component: HealthComponent = null
var _armor_component: ArmorComponent = null
var _round_manager: RoundManager = null


func _ready() -> void:
	# Find player
	await get_tree().process_frame
	_find_player()
	_connect_game_signals()

	# Initial setup
	_update_crosshair_style()
	if hit_marker:
		hit_marker.visible = false
	if reload_indicator:
		reload_indicator.visible = false
	if damage_overlay:
		damage_overlay.visible = false
	if death_screen:
		death_screen.visible = false
	if round_announcement:
		round_announcement.visible = false


func _process(delta: float) -> void:
	_update_crosshair_spread(delta)
	_update_hit_marker(delta)
	_update_damage_overlay(delta)
	_update_announcement(delta)


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if not _player:
		# Try to find by class
		for node in get_tree().get_nodes_in_group(""):
			if node is PlayerController:
				_player = node
				break

	# Also try finding directly
	if not _player:
		_player = get_node_or_null("/root/TestArena/Player")

	if _player:
		# Connect weapon component
		_weapon_component = _player.get_node_or_null("WeaponComponent")
		if _weapon_component:
			_weapon_component.ammo_changed.connect(_on_ammo_changed)
			_weapon_component.weapon_equipped.connect(_on_weapon_equipped)
			_weapon_component.hit_confirmed.connect(_on_hit_confirmed)
			_weapon_component.reload_started.connect(_on_reload_started)
			_weapon_component.reload_finished.connect(_on_reload_finished)

			# Initial update
			if _weapon_component.current_weapon:
				_on_weapon_equipped(_weapon_component.current_weapon)
				_on_ammo_changed(_weapon_component.current_ammo, _weapon_component.reserve_ammo)

		# Connect health component
		_health_component = _player.get_node_or_null("HealthComponent")
		if _health_component:
			_health_component.health_changed.connect(_on_health_changed)
			_health_component.damage_taken.connect(_on_player_damage_taken)
			_health_component.died.connect(_on_player_died)
			# Initial update
			_on_health_changed(_health_component.current_health, _health_component.max_health)

		# Connect armor component
		_armor_component = _player.get_node_or_null("ArmorComponent")
		if _armor_component:
			_armor_component.armor_changed.connect(_on_armor_changed)
			# Initial update
			_on_armor_changed(_armor_component.current_armor, _armor_component.max_armor)


func _update_crosshair_style() -> void:
	if not crosshair_top:
		return

	# Set sizes
	crosshair_top.size = Vector2(crosshair_thickness, crosshair_size)
	crosshair_bottom.size = Vector2(crosshair_thickness, crosshair_size)
	crosshair_left.size = Vector2(crosshair_size, crosshair_thickness)
	crosshair_right.size = Vector2(crosshair_size, crosshair_thickness)

	# Set colors
	crosshair_top.color = crosshair_color
	crosshair_bottom.color = crosshair_color
	crosshair_left.color = crosshair_color
	crosshair_right.color = crosshair_color

	_position_crosshair_lines(crosshair_gap)


func _position_crosshair_lines(gap: float) -> void:
	if not crosshair_top:
		return

	var center: Vector2 = crosshair.size / 2.0

	# Position lines around center with gap
	crosshair_top.position = center + Vector2(-crosshair_thickness/2, -gap - crosshair_size)
	crosshair_bottom.position = center + Vector2(-crosshair_thickness/2, gap)
	crosshair_left.position = center + Vector2(-gap - crosshair_size, -crosshair_thickness/2)
	crosshair_right.position = center + Vector2(gap, -crosshair_thickness/2)


func _update_crosshair_spread(_delta: float) -> void:
	if not _weapon_component or not crosshair_top:
		return

	# Get current spread from weapon
	var spread: float = 0.0
	if _weapon_component.current_weapon:
		if _weapon_component.is_aiming:
			spread = _weapon_component.current_weapon.ads_spread
		else:
			spread = _weapon_component.current_weapon.hipfire_spread

	# Smooth interpolation
	_current_spread = lerp(_current_spread, spread, 0.2)

	# Apply to crosshair gap
	var dynamic_gap: float = crosshair_gap + (_current_spread * crosshair_spread_multiplier)
	_position_crosshair_lines(dynamic_gap)


func _update_hit_marker(delta: float) -> void:
	if _hit_marker_timer > 0:
		_hit_marker_timer -= delta
		if _hit_marker_timer <= 0 and hit_marker:
			hit_marker.visible = false


func _on_ammo_changed(current: int, reserve: int) -> void:
	if ammo_label:
		ammo_label.text = "%d / %d" % [current, reserve]


func _on_weapon_equipped(weapon_data: WeaponData) -> void:
	if weapon_label:
		weapon_label.text = weapon_data.weapon_name


func _on_hit_confirmed(damage: float, is_headshot: bool) -> void:
	if hit_marker:
		hit_marker.visible = true
		hit_marker.modulate = headshot_color if is_headshot else hit_marker_color
		_hit_marker_timer = hit_marker_duration


func _on_reload_started() -> void:
	if reload_indicator:
		reload_indicator.visible = true


func _on_reload_finished() -> void:
	if reload_indicator:
		reload_indicator.visible = false


func _on_health_changed(current: float, max_health: float) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current
	if health_label:
		health_label.text = str(int(current))


func _on_armor_changed(current: float, max_armor: float) -> void:
	if armor_bar:
		armor_bar.max_value = max_armor
		armor_bar.value = current
	if armor_label:
		armor_label.text = str(int(current))


func _on_player_damage_taken(amount: float, _attacker: Node, _hit_location: String) -> void:
	# Show damage overlay
	if damage_overlay:
		damage_overlay.visible = true
		damage_overlay.modulate.a = clamp(amount / 50.0, 0.2, 0.6)
		_damage_overlay_timer = 0.3


func _on_player_died(_killer: Node) -> void:
	# Show death screen
	if death_screen:
		death_screen.visible = true
	if crosshair:
		crosshair.visible = false

	# Hide death screen after respawn delay
	await get_tree().create_timer(2.8).timeout
	if death_screen:
		death_screen.visible = false
	if crosshair:
		crosshair.visible = true


func _update_damage_overlay(delta: float) -> void:
	if _damage_overlay_timer > 0:
		_damage_overlay_timer -= delta
		if _damage_overlay_timer <= 0 and damage_overlay:
			damage_overlay.visible = false


func _update_announcement(delta: float) -> void:
	if _announcement_timer > 0:
		_announcement_timer -= delta
		if _announcement_timer <= 0 and round_announcement:
			round_announcement.visible = false


## Connect to game manager and round manager signals
func _connect_game_signals() -> void:
	# Connect to GameManager (if available)
	if GameManager:
		if GameManager.has_signal("team_score_changed"):
			GameManager.team_score_changed.connect(_on_team_score_changed)
		if GameManager.has_signal("match_ended"):
			GameManager.match_ended.connect(_on_match_ended)

	# Find and connect to RoundManager (if available)
	await get_tree().process_frame
	var game_controller: Node = get_parent().get_node_or_null("GameController")
	if game_controller:
		_round_manager = game_controller.get_node_or_null("RoundManager")

	if _round_manager:
		_round_manager.round_started.connect(_on_round_started)
		_round_manager.round_ended.connect(_on_round_ended_game)
		_round_manager.timer_updated.connect(_on_timer_updated)
		_round_manager.round_state_changed.connect(_on_round_state_changed)
	else:
		# Hide round info UI when not in a match
		if round_info:
			round_info.visible = false


func _on_team_score_changed(_team: int, _new_score: int) -> void:
	_update_score_display()


func _on_round_started(round_number: int) -> void:
	if round_label:
		round_label.text = "Round %d" % round_number
	_show_announcement("ROUND %d" % round_number, 2.0)


func _on_round_ended_game(winning_team: int, reason: String) -> void:
	var team_name: String = "TEAM A" if winning_team == 0 else ("TEAM B" if winning_team == 1 else "DRAW")
	var msg: String = "%s WINS" % team_name
	if reason == "timeout":
		msg += " (Time)"
	_show_announcement(msg, 3.0)


func _on_timer_updated(seconds: int) -> void:
	if timer_label:
		var minutes: int = seconds / 60
		var secs: int = seconds % 60
		timer_label.text = "%d:%02d" % [minutes, secs]


func _on_round_state_changed(state: String) -> void:
	if state == "pre_round":
		_show_announcement("GET READY", 1.0)
	elif state == "active":
		_show_announcement("FIGHT!", 1.5)


func _on_match_ended(winning_team: int) -> void:
	var team_name: String = "TEAM A" if winning_team == 0 else ("TEAM B" if winning_team == 1 else "DRAW")
	_show_announcement("%s WINS THE MATCH!" % team_name, 5.0)


func _update_score_display() -> void:
	if score_label and GameManager:
		score_label.text = GameManager.get_score_string()


func _show_announcement(text: String, duration: float) -> void:
	if round_announcement:
		round_announcement.text = text
		round_announcement.visible = true
		_announcement_timer = duration
