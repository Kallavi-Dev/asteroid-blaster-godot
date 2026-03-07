extends Control
## Main menu: entry point with Solo and Multiplayer options.

@onready var _solo_button: Button = $CenterContainer/VBoxContainer/SoloButton
@onready var _multi_button: Button = $CenterContainer/VBoxContainer/MultiButton
@onready var _quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	_solo_button.pressed.connect(_on_solo_pressed)
	_multi_button.pressed.connect(_on_multi_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_solo_pressed() -> void:
	GameManager.game_mode = Constants.GameMode.SOLO
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_multi_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
