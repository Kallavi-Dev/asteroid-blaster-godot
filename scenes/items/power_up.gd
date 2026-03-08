class_name PowerUp
extends Area2D
## Collectible power-up that falls from destroyed asteroids.
## Types: Shield (temporary invincibility), Rapid Fire, Spread Shot.

var power_type: Constants.PowerUpType = Constants.PowerUpType.SHIELD
var _speed: float = Constants.POWER_UP_SPEED

@onready var _sprite: Sprite2D = $PowerUpSprite


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_apply_visual()


func _process(delta: float) -> void:
	position.y += _speed * delta
	rotation += 2.0 * delta
	if position.y > Constants.VIEWPORT_HEIGHT + 20.0:
		queue_free()


func setup(type: Constants.PowerUpType, spawn_position: Vector2) -> void:
	power_type = type
	position = spawn_position


func _apply_visual() -> void:
	match power_type:
		Constants.PowerUpType.SHIELD:
			_sprite.texture = load("res://assets/svg/powerups/powerup_shield.svg")
		Constants.PowerUpType.RAPID_FIRE:
			_sprite.texture = load("res://assets/svg/powerups/powerup_rapid.svg")
		Constants.PowerUpType.SPREAD_SHOT:
			_sprite.texture = load("res://assets/svg/powerups/powerup_spread.svg")


func _on_area_entered(area: Area2D) -> void:
	if area is Player:
		(area as Player).apply_power_up(power_type)
		AudioManager.play_powerup()
		queue_free()
