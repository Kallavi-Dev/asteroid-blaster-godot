class_name Asteroid
extends Area2D
## Falling asteroid enemy with size variants.
## Large asteroids break into medium, medium into small.

signal destroyed(asteroid_position: Vector2, asteroid_size: Constants.AsteroidSize)

const LARGE_TEXTURES: Array[String] = [
	"res://assets/sprites/meteors/meteorBrown_big1.png",
	"res://assets/sprites/meteors/meteorBrown_big2.png",
	"res://assets/sprites/meteors/meteorBrown_big3.png",
	"res://assets/sprites/meteors/meteorBrown_big4.png",
]
const MEDIUM_TEXTURES: Array[String] = [
	"res://assets/sprites/meteors/meteorBrown_med1.png",
	"res://assets/sprites/meteors/meteorBrown_med3.png",
]
const SMALL_TEXTURES: Array[String] = [
	"res://assets/sprites/meteors/meteorBrown_small1.png",
	"res://assets/sprites/meteors/meteorBrown_small2.png",
]

const SPRITE_SCALE: float = 0.9

var asteroid_size: Constants.AsteroidSize = Constants.AsteroidSize.LARGE
var _speed: float = 0.0
var _rotation_speed: float = 0.0

@onready var _meteor_sprite: Sprite2D = $MeteorSprite


func _ready() -> void:
	_speed = randf_range(Constants.ASTEROID_MIN_SPEED, Constants.ASTEROID_MAX_SPEED)
	_rotation_speed = randf_range(-2.0, 2.0)

	scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)

	var textures: Array[String]
	match asteroid_size:
		Constants.AsteroidSize.LARGE:
			textures = LARGE_TEXTURES
		Constants.AsteroidSize.MEDIUM:
			textures = MEDIUM_TEXTURES
		Constants.AsteroidSize.SMALL:
			textures = SMALL_TEXTURES
	_meteor_sprite.texture = load(textures[randi() % textures.size()])

	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	position.y += _speed * delta
	rotation += _rotation_speed * delta

	if position.y > Constants.VIEWPORT_HEIGHT + Constants.ASTEROID_DESPAWN_MARGIN:
		queue_free()


func setup(size: Constants.AsteroidSize, spawn_position: Vector2) -> void:
	asteroid_size = size
	position = spawn_position


func _on_area_entered(area: Area2D) -> void:
	if area is Bullet:
		area.queue_free()
		var score_value: int = Constants.ASTEROID_SIZE_SCORES[asteroid_size]
		GameManager.add_score(score_value)
		GameManager.register_kill()
		AudioManager.play_explosion()
		destroyed.emit(global_position, asteroid_size)
		queue_free()
	elif area is Player:
		(area as Player).take_damage()
		destroyed.emit(global_position, asteroid_size)
		queue_free()
