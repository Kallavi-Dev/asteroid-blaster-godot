extends CanvasLayer
## In-game HUD. Shows score/lives per player, adapts to game mode.

@onready var _p1_score_label: Label = $MarginContainer/HBoxContainer/P1Score
@onready var _p1_lives_label: Label = $MarginContainer/HBoxContainer/P1Lives
@onready var _p2_score_label: Label = $MarginContainer/HBoxContainer/P2Score
@onready var _p2_lives_label: Label = $MarginContainer/HBoxContainer/P2Lives


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)

	if GameManager.game_mode == Constants.GameMode.SOLO:
		_p2_score_label.visible = false
		_p2_lives_label.visible = false
		_update_solo_display()
	elif GameManager.game_mode == Constants.GameMode.COOP:
		_p2_score_label.visible = false
		_p2_lives_label.visible = false
		_update_coop_display()
	else:
		_p2_score_label.visible = true
		_p2_lives_label.visible = true
		_update_competitive_display()


func _update_solo_display() -> void:
	_p1_score_label.text = "SCORE: %d" % GameManager.get_score(1)
	_p1_lives_label.text = "LIVES: %d" % GameManager.get_lives(1)


func _update_coop_display() -> void:
	_p1_score_label.text = "TEAM SCORE: %d" % GameManager.get_score(1)
	_p1_lives_label.text = "TEAM LIVES: %d" % GameManager.get_lives(1)


func _update_competitive_display() -> void:
	_p1_score_label.text = "P1: %d" % GameManager.get_score(1)
	_p1_lives_label.text = "P1 LIVES: %d" % GameManager.get_lives(1)
	var p2_ids := NetworkManager.player_ids.filter(func(id): return id != 1)
	if p2_ids.size() > 0:
		var p2_id: int = p2_ids[0]
		_p2_score_label.text = "P2: %d" % GameManager.get_score(p2_id)
		_p2_lives_label.text = "P2 LIVES: %d" % GameManager.get_lives(p2_id)


func _on_score_changed(_new_score: int, _peer_id: int) -> void:
	match GameManager.game_mode:
		Constants.GameMode.SOLO:
			_update_solo_display()
		Constants.GameMode.COOP:
			_update_coop_display()
		Constants.GameMode.COMPETITIVE:
			_update_competitive_display()


func _on_lives_changed(_new_lives: int, _peer_id: int) -> void:
	match GameManager.game_mode:
		Constants.GameMode.SOLO:
			_update_solo_display()
		Constants.GameMode.COOP:
			_update_coop_display()
		Constants.GameMode.COMPETITIVE:
			_update_competitive_display()
