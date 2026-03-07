class_name Bullet
extends Area2D
## Projectile fired by the player. Moves upward (with optional angle for spread shot).
## Self-destructs when leaving the viewport.

var direction: Vector2 = Vector2.UP


func _process(delta: float) -> void:
	position += direction * Constants.BULLET_SPEED * delta
	if position.y < -20.0 or position.x < -20.0 or position.x > Constants.VIEWPORT_WIDTH + 20.0:
		queue_free()
