class_name BossBullet
extends Area2D
## Projectile fired by the boss. Moves in a given direction.

var direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	position += direction * Constants.BOSS_BULLET_SPEED * delta
	if position.y > Constants.VIEWPORT_HEIGHT + 20.0 or position.y < -20.0:
		queue_free()
	if position.x < -20.0 or position.x > Constants.VIEWPORT_WIDTH + 20.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area is Player:
		(area as Player).take_damage()
		queue_free()
