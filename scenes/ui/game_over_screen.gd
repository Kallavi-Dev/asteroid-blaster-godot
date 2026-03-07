extends CanvasLayer
## Game over overlay with final score, high score display, and restart button.

@onready var _final_score_label: Label = $PanelContainer/VBoxContainer/FinalScoreLabel
@onready var _high_score_label: Label = $PanelContainer/VBoxContainer/HighScoreLabel
@onready var _restart_button: Button = $PanelContainer/VBoxContainer/RestartButton


func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.game_started.connect(_on_game_started)
	_restart_button.pressed.connect(_on_restart_pressed)
	visible = false


func _on_game_over() -> void:
	_final_score_label.text = "FINAL SCORE: %d" % GameManager.score
	_high_score_label.text = "HIGH SCORE: %d" % GameManager.get_high_score()
	visible = true


func _on_game_started() -> void:
	visible = false


func _on_restart_pressed() -> void:
	GameManager.reset()
	get_tree().reload_current_scene()
