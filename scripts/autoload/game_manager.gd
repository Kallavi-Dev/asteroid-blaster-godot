extends Node
## Global game state manager (autoload singleton).
## Tracks score, lives, difficulty, high score, game flow.
## Supports Solo, Co-op, and Competitive modes.

signal score_changed(new_score: int, peer_id: int)
signal lives_changed(new_lives: int, peer_id: int)
signal game_over
signal game_started
signal boss_incoming
signal player_eliminated(peer_id: int)

var game_mode: Constants.GameMode = Constants.GameMode.SOLO
var is_playing: bool = false
var high_score: int = 0
var total_kills: int = 0
var _boss_spawned_at_threshold: int = 0

## Per-player state: { peer_id: { "score": int, "lives": int, "alive": bool } }
var player_states: Dictionary = {}

## Solo mode backward-compatible accessors
var score: int:
	get:
		if game_mode == Constants.GameMode.COOP:
			return player_states.get(1, {}).get("score", 0)
		return player_states.get(1, {}).get("score", 0)

var lives: int:
	get:
		if game_mode == Constants.GameMode.COOP:
			return player_states.get(1, {}).get("lives", 0)
		return player_states.get(1, {}).get("lives", 0)


func _ready() -> void:
	_load_high_score()


func start_game() -> void:
	total_kills = 0
	_boss_spawned_at_threshold = 0
	is_playing = true
	player_states.clear()

	match game_mode:
		Constants.GameMode.SOLO:
			_init_player_state(1, Constants.PLAYER_INITIAL_LIVES)
		Constants.GameMode.COOP:
			for peer_id in _get_all_peer_ids():
				_init_player_state(peer_id, 0)
			# Co-op: shared lives stored on peer 1
			player_states[1]["lives"] = Constants.COOP_LIVES
		Constants.GameMode.COMPETITIVE:
			for peer_id in _get_all_peer_ids():
				_init_player_state(peer_id, Constants.COMPETITIVE_LIVES)

	game_started.emit()


func _init_player_state(peer_id: int, initial_lives: int) -> void:
	player_states[peer_id] = {
		"score": 0,
		"lives": initial_lives,
		"alive": true,
	}
	score_changed.emit(0, peer_id)
	lives_changed.emit(initial_lives, peer_id)


func add_score(points: int, peer_id: int = 1) -> void:
	if game_mode == Constants.GameMode.COOP:
		# Co-op: shared score on peer 1
		player_states[1]["score"] = player_states[1].get("score", 0) + points
		score_changed.emit(player_states[1]["score"], 1)
	else:
		if peer_id in player_states:
			player_states[peer_id]["score"] = player_states[peer_id].get("score", 0) + points
			score_changed.emit(player_states[peer_id]["score"], peer_id)


@rpc("authority", "call_local", "reliable")
func sync_score(peer_id: int, new_score: int) -> void:
	if peer_id in player_states:
		player_states[peer_id]["score"] = new_score
		score_changed.emit(new_score, peer_id)


@rpc("authority", "call_local", "reliable")
func sync_lives(peer_id: int, new_lives: int) -> void:
	if peer_id in player_states:
		player_states[peer_id]["lives"] = new_lives
		lives_changed.emit(new_lives, peer_id)


func register_kill() -> void:
	total_kills += 1
	var threshold := Constants.BOSS_SPAWN_KILL_THRESHOLD
	if total_kills > 0 and total_kills % threshold == 0 and total_kills != _boss_spawned_at_threshold:
		_boss_spawned_at_threshold = total_kills
		boss_incoming.emit()


func lose_life(peer_id: int = 1) -> void:
	if game_mode == Constants.GameMode.COOP:
		# Shared lives on peer 1
		player_states[1]["lives"] -= 1
		var remaining: int = player_states[1]["lives"]
		lives_changed.emit(remaining, 1)
		if remaining <= 0:
			_end_game()
	else:
		if peer_id in player_states:
			player_states[peer_id]["lives"] -= 1
			var remaining: int = player_states[peer_id]["lives"]
			lives_changed.emit(remaining, peer_id)
			if remaining <= 0:
				player_states[peer_id]["alive"] = false
				player_eliminated.emit(peer_id)
				_check_all_eliminated()


func _check_all_eliminated() -> void:
	if game_mode == Constants.GameMode.SOLO:
		_end_game()
		return
	for state in player_states.values():
		if state["alive"]:
			return
	_end_game()


func _end_game() -> void:
	is_playing = false
	_update_high_score()
	game_over.emit()


func reset() -> void:
	player_states.clear()
	total_kills = 0
	_boss_spawned_at_threshold = 0
	is_playing = false


func get_score(peer_id: int) -> int:
	if game_mode == Constants.GameMode.COOP:
		return player_states.get(1, {}).get("score", 0)
	return player_states.get(peer_id, {}).get("score", 0)


func get_lives(peer_id: int) -> int:
	if game_mode == Constants.GameMode.COOP:
		return player_states.get(1, {}).get("lives", 0)
	return player_states.get(peer_id, {}).get("lives", 0)


func get_total_score() -> int:
	var total := 0
	for state in player_states.values():
		total += state.get("score", 0)
	return total


func is_player_alive(peer_id: int) -> bool:
	return player_states.get(peer_id, {}).get("alive", false)


func get_winner_id() -> int:
	var best_id := -1
	var best_score := -1
	for peer_id in player_states:
		var s: int = player_states[peer_id]["score"]
		if s > best_score:
			best_score = s
			best_id = peer_id
	return best_id


func get_high_score() -> int:
	return high_score


func _get_all_peer_ids() -> Array[int]:
	if game_mode == Constants.GameMode.SOLO:
		return [1]
	var ids: Array[int] = [1]
	for pid in NetworkManager.player_ids:
		if pid != 1 and pid not in ids:
			ids.append(pid)
	return ids


func _update_high_score() -> void:
	var current := get_total_score()
	if current > high_score:
		high_score = current
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
