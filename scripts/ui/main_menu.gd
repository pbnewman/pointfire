extends Control
class_name MainMenu
## Main menu with game mode selection.

@onready var practice_button: Button = $VBoxContainer/PracticeButton
@onready var team_fight_button: Button = $VBoxContainer/TeamFightButton
@onready var quit_button: Button = $VBoxContainer/QuitButton


func _ready() -> void:
	# Show cursor in menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Connect buttons
	practice_button.pressed.connect(_on_practice_pressed)
	team_fight_button.pressed.connect(_on_team_fight_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Focus first button
	practice_button.grab_focus()


func _on_practice_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/maps/test_arena.tscn")


func _on_team_fight_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/maps/team_fight_arena.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
