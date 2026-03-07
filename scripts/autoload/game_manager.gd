extends Node
## Global game state manager (autoload singleton).
## Tracks score, lives, difficulty, high score persistence, and game flow.

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal game_over
signal game_started
signal boss_incoming

var score: int = 0
var lives: int = Constants.PLAYER_INITIAL_LIVES
var is_playing: bool = false
var high_score: int = 0
var total_kills: int = 0
var _boss_spawned_at_threshold: int = 0


func _ready() -> void:
	_load_high_score()


func start_game() -> void:
	score = 0
	lives = Constants.PLAYER_INITIAL_LIVES
	total_kills = 0
	_boss_spawned_at_threshold = 0
	is_playing = true
	score_changed.emit(score)
	lives_changed.emit(lives)
	game_started.emit()


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


func register_kill() -> void:
	total_kills += 1
	var threshold := Constants.BOSS_SPAWN_KILL_THRESHOLD
	if total_kills > 0 and total_kills % threshold == 0 and total_kills != _boss_spawned_at_threshold:
		_boss_spawned_at_threshold = total_kills
		boss_incoming.emit()


func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		is_playing = false
		_update_high_score()
		game_over.emit()


func reset() -> void:
	score = 0
	lives = Constants.PLAYER_INITIAL_LIVES
	total_kills = 0
	_boss_spawned_at_threshold = 0
	is_playing = false


func get_high_score() -> int:
	return high_score


func _update_high_score() -> void:
	if score > high_score:
		high_score = score
		_save_high_score()


func _save_high_score() -> void:
	var file := FileAccess.open(Constants.SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_32(high_score)


func _load_high_score() -> void:
	if FileAccess.file_exists(Constants.SAVE_FILE_PATH):
		var file := FileAccess.open(Constants.SAVE_FILE_PATH, FileAccess.READ)
		if file:
			high_score = file.get_32()
