class_name Player
extends Area2D
## Player ship: moves with arrow keys/WASD, shoots with Space.
## In multiplayer, only processes input if this peer has authority.

signal shoot(bullet_position: Vector2, angle: float, shooter_peer_id: int)

var _can_shoot: bool = true
var _is_invincible: bool = false
var _has_shield: bool = false
var _has_rapid_fire: bool = false
var _has_spread_shot: bool = false
var peer_id: int = 1

@onready var _shoot_timer: Timer = $ShootTimer
@onready var _invincibility_timer: Timer = $InvincibilityTimer
@onready var _ship_sprite: Sprite2D = $ShipSprite
@onready var _engine_flame: GPUParticles2D = $EngineFlame
@onready var _power_up_timer: Timer = $PowerUpTimer


func _ready() -> void:
	_shoot_timer.wait_time = Constants.PLAYER_SHOOT_COOLDOWN
	_shoot_timer.one_shot = true
	_shoot_timer.timeout.connect(_on_shoot_timer_timeout)

	_invincibility_timer.wait_time = Constants.PLAYER_INVINCIBILITY_DURATION
	_invincibility_timer.one_shot = true
	_invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)

	_power_up_timer.one_shot = true
	_power_up_timer.timeout.connect(_on_power_up_timer_timeout)

	setup_visuals()


func setup_visuals() -> void:
	if peer_id == 1 or GameManager.game_mode == Constants.GameMode.SOLO:
		_ship_sprite.texture = load("res://assets/svg/player/ship_p1.svg")
	else:
		_ship_sprite.texture = load("res://assets/svg/player/ship_p2.svg")


func _process(delta: float) -> void:
	if not GameManager.is_playing:
		_engine_flame.emitting = false
		return
	if not _is_local_player():
		return
	_engine_flame.emitting = true
	_handle_movement(delta)
	_handle_shooting()


func _is_local_player() -> bool:
	if GameManager.game_mode == Constants.GameMode.SOLO:
		return true
	return peer_id == multiplayer.get_unique_id()


func _handle_movement(delta: float) -> void:
	var velocity := Vector2.ZERO

	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1.0
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1.0
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1.0

	if velocity.length() > 0.0:
		velocity = velocity.normalized() * Constants.PLAYER_SPEED

	position += velocity * delta
	position = position.clamp(
		Vector2(Constants.PLAYER_MARGIN, Constants.PLAYER_MARGIN),
		Vector2(
			Constants.VIEWPORT_WIDTH - Constants.PLAYER_MARGIN,
			Constants.VIEWPORT_HEIGHT - Constants.PLAYER_MARGIN
		)
	)

	_ship_sprite.rotation = velocity.x / Constants.PLAYER_SPEED * 0.3


func _handle_shooting() -> void:
	if Input.is_key_pressed(KEY_SPACE) and _can_shoot:
		_can_shoot = false
		var cooldown := Constants.PLAYER_RAPID_FIRE_COOLDOWN if _has_rapid_fire else Constants.PLAYER_SHOOT_COOLDOWN
		_shoot_timer.wait_time = cooldown
		_shoot_timer.start()

		var spawn_pos := global_position + Vector2(0, Constants.BULLET_SPAWN_OFFSET_Y)

		if GameManager.game_mode == Constants.GameMode.SOLO:
			shoot.emit(spawn_pos, 0.0, peer_id)
			if _has_spread_shot:
				shoot.emit(spawn_pos, -deg_to_rad(Constants.PLAYER_SPREAD_ANGLE), peer_id)
				shoot.emit(spawn_pos, deg_to_rad(Constants.PLAYER_SPREAD_ANGLE), peer_id)
		else:
			_request_shoot.rpc_id(1, spawn_pos, 0.0)
			if _has_spread_shot:
				_request_shoot.rpc_id(1, spawn_pos, -deg_to_rad(Constants.PLAYER_SPREAD_ANGLE))
				_request_shoot.rpc_id(1, spawn_pos, deg_to_rad(Constants.PLAYER_SPREAD_ANGLE))

		AudioManager.play_shoot()


func take_damage() -> void:
	if _is_invincible or _has_shield:
		if _has_shield:
			_has_shield = false
			_ship_sprite.modulate = Color.WHITE
		return
	AudioManager.play_hit()
	GameManager.lose_life(peer_id)
	if GameManager.is_player_alive(peer_id):
		_start_invincibility()
	else:
		visible = false
		set_process(false)


func apply_power_up(power_type: Constants.PowerUpType) -> void:
	_clear_power_ups()
	_power_up_timer.wait_time = Constants.POWER_UP_DURATION
	_power_up_timer.start()

	match power_type:
		Constants.PowerUpType.SHIELD:
			_has_shield = true
			_ship_sprite.modulate = Constants.POWER_UP_COLORS[Constants.PowerUpType.SHIELD]
		Constants.PowerUpType.RAPID_FIRE:
			_has_rapid_fire = true
			_ship_sprite.modulate = Constants.POWER_UP_COLORS[Constants.PowerUpType.RAPID_FIRE]
		Constants.PowerUpType.SPREAD_SHOT:
			_has_spread_shot = true
			_ship_sprite.modulate = Constants.POWER_UP_COLORS[Constants.PowerUpType.SPREAD_SHOT]


@rpc("any_peer", "reliable")
func _request_shoot(bullet_position: Vector2, angle: float) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	shoot.emit(bullet_position, angle, sender)


func _clear_power_ups() -> void:
	_has_shield = false
	_has_rapid_fire = false
	_has_spread_shot = false
	_ship_sprite.modulate = Color.WHITE


func _start_invincibility() -> void:
	_is_invincible = true
	_invincibility_timer.start()

	var blink_count := int(Constants.PLAYER_INVINCIBILITY_DURATION / 0.15)
	var tween := create_tween()
	tween.set_loops(blink_count)
	tween.tween_property(_ship_sprite, "modulate:a", 0.2, 0.075)
	tween.tween_property(_ship_sprite, "modulate:a", 1.0, 0.075)


func _on_shoot_timer_timeout() -> void:
	_can_shoot = true


func _on_invincibility_timer_timeout() -> void:
	_is_invincible = false
	_ship_sprite.modulate.a = 1.0


func _on_power_up_timer_timeout() -> void:
	_clear_power_ups()
