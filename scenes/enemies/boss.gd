class_name Boss
extends Area2D
## Boss enemy with health bar, movement patterns, and shooting.
## Spawns every N kills. Moves side-to-side and shoots at the player.

signal destroyed(boss_position: Vector2)
signal health_changed(current: int, max_health: int)

var _health: int = Constants.BOSS_HEALTH
var _max_health: int = Constants.BOSS_HEALTH
var _direction: float = 1.0
var _entered: bool = false
var _target_y: float = 150.0

@onready var _shoot_timer: Timer = $ShootTimer
@onready var _health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_shoot_timer.wait_time = Constants.BOSS_SHOOT_INTERVAL
	_shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	_health_bar.max_value = _max_health
	_health_bar.value = _health
	_health_bar.position = Vector2(-40, -50)
	_health_bar.size = Vector2(80, 8)


func _process(delta: float) -> void:
	if not _entered:
		position.y += Constants.BOSS_SPEED * 2.0 * delta
		if position.y >= _target_y:
			position.y = _target_y
			_entered = true
			_shoot_timer.start()
		return

	position.x += Constants.BOSS_SPEED * _direction * delta
	if position.x > Constants.VIEWPORT_WIDTH - Constants.BOSS_WIDTH:
		_direction = -1.0
	elif position.x < Constants.BOSS_WIDTH:
		_direction = 1.0


func take_hit() -> void:
	_health -= 1
	_health_bar.value = _health
	health_changed.emit(_health, _max_health)

	# Flash red on hit
	modulate = Color(1.0, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

	if _health <= 0:
		GameManager.add_score(Constants.BOSS_SCORE_VALUE)
		GameManager.register_kill()
		destroyed.emit(global_position)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area is Bullet:
		area.queue_free()
		take_hit()
	elif area is Player:
		(area as Player).take_damage()


func _on_shoot_timer_timeout() -> void:
	if not _entered or not GameManager.is_playing:
		return
	_spawn_boss_bullet(Vector2(0, 1))
	_spawn_boss_bullet(Vector2(-0.3, 1).normalized())
	_spawn_boss_bullet(Vector2(0.3, 1).normalized())


func _spawn_boss_bullet(direction: Vector2) -> void:
	var bullet_scene := preload("res://scenes/enemies/boss_bullet.tscn")
	var bullet := bullet_scene.instantiate()
	bullet.position = global_position + Vector2(0, 30)
	bullet.direction = direction
	bullet.add_to_group(Constants.GROUP_ENEMY_BULLETS)
	get_tree().current_scene.add_child(bullet)
