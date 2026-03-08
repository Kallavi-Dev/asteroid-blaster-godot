extends CanvasLayer
## Game over overlay. Mode-aware: shows combined or individual scores.

@onready var _final_score_label: Label = $PanelContainer/VBoxContainer/FinalScoreLabel
@onready var _high_score_label: Label = $PanelContainer/VBoxContainer/HighScoreLabel
@onready var _restart_button: Button = $PanelContainer/VBoxContainer/RestartButton


func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.game_started.connect(_on_game_started)
	_restart_button.pressed.connect(_on_restart_pressed)
	visible = false


func _on_game_over() -> void:
	match GameManager.game_mode:
		Constants.GameMode.SOLO:
			_final_score_label.text = "FINAL SCORE: %d" % GameManager.get_score(1)
		Constants.GameMode.COOP:
			_final_score_label.text = "TEAM SCORE: %d" % GameManager.get_score(1)
		Constants.GameMode.COMPETITIVE:
			var winner_id := GameManager.get_winner_id()
			var winner_label := "P1" if winner_id == 1 else "P2"
			_final_score_label.text = "%s WINS! (%d pts)" % [winner_label, GameManager.get_score(winner_id)]
	_high_score_label.text = "HIGH SCORE: %d" % GameManager.get_high_score()
	visible = true


func _on_game_started() -> void:
	visible = false


func _on_restart_pressed() -> void:
	GameManager.reset()
	if GameManager.game_mode == Constants.GameMode.SOLO:
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn")
