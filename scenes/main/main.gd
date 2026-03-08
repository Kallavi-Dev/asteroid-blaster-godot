extends Node2D
## Main game scene. Orchestrates spawning, bullet creation, game flow,
## screen shake, difficulty ramping, boss encounters, and power-up drops.
## In multiplayer, host manages spawning; entities replicate via MultiplayerSpawner.

const BULLET_SCENE: PackedScene = preload("res://scenes/projectiles/bullet.tscn")
const ASTEROID_SCENE: PackedScene = preload("res://scenes/enemies/asteroid.tscn")
const EXPLOSION_SCENE: PackedScene = preload("res://scenes/effects/explosion.tscn")
const POWER_UP_SCENE: PackedScene = preload("res://scenes/items/power_up.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/enemies/boss.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

@onready var _spawn_timer: Timer = $SpawnTimer
@onready var _difficulty_timer: Timer = $DifficultyTimer
@onready var _camera: Camera2D = $Camera2D
@onready var _start_button: Button = $StartUI/CenterContainer/VBoxContainer/StartButton
@onready var _start_ui: CanvasLayer = $StartUI
@onready var _high_score_label: Label = $StartUI/CenterContainer/VBoxContainer/HighScoreLabel
@onready var _entities: Node2D = $Entities
@onready var _players_node: Node2D = $Players

var _shake_amount: float = 0.0
var _players: Dictionary = {}


func _ready() -> void:
	_spawn_timer.wait_time = Constants.ASTEROID_SPAWN_INTERVAL
	_spawn_timer.timeout.connect(_spawn_asteroid)

	_difficulty_timer.wait_time = Constants.DIFFICULTY_RAMP_INTERVAL
	_difficulty_timer.timeout.connect(_on_difficulty_tick)

	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over.connect(_on_game_over)
	GameManager.boss_incoming.connect(_on_boss_incoming)

	if GameManager.game_mode == Constants.GameMode.SOLO:
		_start_button.pressed.connect(_on_start_pressed)
		_update_high_score_display()
	else:
		NetworkManager.player_disconnected.connect(_on_peer_disconnected)
		NetworkManager.server_disconnected.connect(_on_server_lost)
		_start_ui.visible = false
		GameManager.start_game()


func _process(delta: float) -> void:
	if _shake_amount > 0.0:
		_camera.offset = Vector2(
			randf_range(-_shake_amount, _shake_amount),
			randf_range(-_shake_amount, _shake_amount)
		)
		_shake_amount = lerpf(_shake_amount, 0.0, 10.0 * delta)
		if _shake_amount < 0.5:
			_shake_amount = 0.0
			_camera.offset = Vector2.ZERO


func _on_start_pressed() -> void:
	GameManager.start_game()


func _on_game_started() -> void:
	_start_ui.visible = false
	_clear_entities()
	_spawn_players()
	_spawn_timer.wait_time = Constants.ASTEROID_SPAWN_INTERVAL
	_spawn_timer.start()
	_difficulty_timer.start()


func _spawn_players() -> void:
	if GameManager.game_mode == Constants.GameMode.SOLO:
		var player := PLAYER_SCENE.instantiate()
		player.peer_id = 1
		player.position = Vector2(Constants.VIEWPORT_WIDTH / 2.0, Constants.VIEWPORT_HEIGHT - 100.0)
		player.shoot.connect(_on_player_shoot)
		_players_node.add_child(player)
		_players[1] = player
	else:
		var peer_ids: Array[int] = [1]
		for pid in NetworkManager.player_ids:
			if pid != 1 and pid not in peer_ids:
				peer_ids.append(pid)

		var spawn_positions := [
			Vector2(Constants.VIEWPORT_WIDTH / 3.0, Constants.VIEWPORT_HEIGHT - 100.0),
			Vector2(Constants.VIEWPORT_WIDTH * 2.0 / 3.0, Constants.VIEWPORT_HEIGHT - 100.0),
		]

		for i in peer_ids.size():
			var player := PLAYER_SCENE.instantiate()
			player.peer_id = peer_ids[i]
			player.name = "Player_%d" % peer_ids[i]
			player.position = spawn_positions[mini(i, spawn_positions.size() - 1)]
			player.shoot.connect(_on_player_shoot)
			_players_node.add_child(player)
			_players[peer_ids[i]] = player


func _on_game_over() -> void:
	_spawn_timer.stop()
	_difficulty_timer.stop()
	for player in _players.values():
		if is_instance_valid(player):
			player.visible = false


func _on_player_shoot(bullet_position: Vector2, angle: float, shooter_peer_id: int) -> void:
	var bullet := BULLET_SCENE.instantiate()
	bullet.position = bullet_position
	bullet.direction = Vector2.UP.rotated(angle)
	bullet.owner_peer_id = shooter_peer_id
	bullet.add_to_group(Constants.GROUP_BULLETS)
	_entities.add_child(bullet)


func _spawn_asteroid() -> void:
	if not _is_host_or_solo():
		return
	var asteroid := ASTEROID_SCENE.instantiate()
	asteroid.setup(
		Constants.AsteroidSize.LARGE,
		Vector2(
			randf_range(
				Constants.ASTEROID_SPAWN_MARGIN,
				Constants.VIEWPORT_WIDTH - Constants.ASTEROID_SPAWN_MARGIN
			),
			-Constants.ASTEROID_SPAWN_MARGIN
		)
	)
	asteroid.add_to_group(Constants.GROUP_ASTEROIDS)
	asteroid.destroyed.connect(_on_asteroid_destroyed)
	_entities.add_child(asteroid)


func _on_asteroid_destroyed(asteroid_position: Vector2, asteroid_size: Constants.AsteroidSize) -> void:
	var explosion := EXPLOSION_SCENE.instantiate()
	explosion.position = asteroid_position
	_entities.add_child(explosion)

	_trigger_shake()
	_spawn_children(asteroid_position, asteroid_size)

	if randf() < Constants.POWER_UP_DROP_CHANCE:
		_spawn_power_up(asteroid_position)


func _spawn_children(parent_position: Vector2, parent_size: Constants.AsteroidSize) -> void:
	var child_size: Constants.AsteroidSize
	match parent_size:
		Constants.AsteroidSize.LARGE:
			child_size = Constants.AsteroidSize.MEDIUM
		Constants.AsteroidSize.MEDIUM:
			child_size = Constants.AsteroidSize.SMALL
		Constants.AsteroidSize.SMALL:
			return

	for i in Constants.ASTEROID_CHILDREN_ON_BREAK:
		var offset := Vector2(randf_range(-30, 30), randf_range(-20, 20))
		var child := ASTEROID_SCENE.instantiate()
		child.setup(child_size, parent_position + offset)
		child.add_to_group(Constants.GROUP_ASTEROIDS)
		child.destroyed.connect(_on_asteroid_destroyed)
		_entities.add_child(child)


func _spawn_power_up(spawn_position: Vector2) -> void:
	var power_up := POWER_UP_SCENE.instantiate()
	var types := Constants.PowerUpType.values()
	var random_type: Constants.PowerUpType = types[randi() % types.size()]
	power_up.setup(random_type, spawn_position)
	power_up.add_to_group(Constants.GROUP_POWER_UPS)
	_entities.add_child(power_up)


func _on_boss_incoming() -> void:
	if not _is_host_or_solo():
		return
	var boss := BOSS_SCENE.instantiate()
	boss.position = Vector2(Constants.VIEWPORT_WIDTH / 2.0, -80.0)
	boss.destroyed.connect(_on_boss_destroyed)
	_entities.add_child(boss)


func _on_boss_destroyed(boss_position: Vector2) -> void:
	var explosion := EXPLOSION_SCENE.instantiate()
	explosion.position = boss_position
	_entities.add_child(explosion)
	_trigger_shake()


func _trigger_shake() -> void:
	_shake_amount = Constants.SHAKE_INTENSITY


func _on_difficulty_tick() -> void:
	var new_interval := _spawn_timer.wait_time - Constants.DIFFICULTY_SPAWN_DECREASE
	_spawn_timer.wait_time = maxf(new_interval, Constants.DIFFICULTY_MIN_SPAWN_INTERVAL)


func _update_high_score_display() -> void:
	var hs := GameManager.get_high_score()
	if hs > 0:
		_high_score_label.text = "HIGH SCORE: %d" % hs
	else:
		_high_score_label.text = ""


func _clear_entities() -> void:
	for child in _entities.get_children():
		child.queue_free()
	for child in _players_node.get_children():
		child.queue_free()
	_players.clear()


func _on_peer_disconnected(peer_id: int) -> void:
	if peer_id in _players:
		_players[peer_id].queue_free()
		_players.erase(peer_id)


func _on_server_lost() -> void:
	get_tree().paused = false
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _is_host_or_solo() -> bool:
	return GameManager.game_mode == Constants.GameMode.SOLO or multiplayer.is_server()
