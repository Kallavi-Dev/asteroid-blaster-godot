extends CanvasLayer
## Pause overlay. Toggled with ESC key.
## Pauses the scene tree while keeping this UI responsive.

@onready var _resume_button: Button = $PanelContainer/VBoxContainer/ResumeButton
@onready var _quit_button: Button = $PanelContainer/VBoxContainer/QuitButton


func _ready() -> void:
	_resume_button.pressed.connect(_on_resume_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and GameManager.is_playing:
		_toggle_pause()


func _toggle_pause() -> void:
	var is_paused := not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused


func _on_resume_pressed() -> void:
	_toggle_pause()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	GameManager.reset()
	get_tree().reload_current_scene()
