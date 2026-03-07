extends CanvasLayer
## In-game heads-up display showing score, lives, and kill count.

@onready var _score_label: Label = $MarginContainer/HBoxContainer/ScoreLabel
@onready var _lives_label: Label = $MarginContainer/HBoxContainer/LivesLabel


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	_update_display()


func _update_display() -> void:
	_score_label.text = "SCORE: %d" % GameManager.score
	_lives_label.text = "LIVES: %d" % GameManager.lives


func _on_score_changed(new_score: int) -> void:
	_score_label.text = "SCORE: %d" % new_score


func _on_lives_changed(new_lives: int) -> void:
	_lives_label.text = "LIVES: %d" % new_lives
