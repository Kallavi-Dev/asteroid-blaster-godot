extends Node2D
## Scrolling parallax starfield background.
## Stars are generated procedurally and scroll downward at varying speeds.

var _stars: Array[Dictionary] = []


func _ready() -> void:
	for i in Constants.STAR_COUNT:
		_stars.append(_create_star(true))


func _process(delta: float) -> void:
	for star in _stars:
		star.position.y += star.speed * delta
		if star.position.y > Constants.VIEWPORT_HEIGHT:
			star.position = Vector2(
				randf_range(0, Constants.VIEWPORT_WIDTH),
				-star.size
			)
			star.speed = randf_range(Constants.STAR_MIN_SPEED, Constants.STAR_MAX_SPEED)
	queue_redraw()


func _draw() -> void:
	for star in _stars:
		var alpha := remap(star.speed, Constants.STAR_MIN_SPEED, Constants.STAR_MAX_SPEED, 0.3, 0.9)
		var color := Color(1.0, 1.0, 1.0, alpha)
		draw_circle(star.position, star.size, color)


func _create_star(random_y: bool) -> Dictionary:
	return {
		"position": Vector2(
			randf_range(0, Constants.VIEWPORT_WIDTH),
			randf_range(0, Constants.VIEWPORT_HEIGHT) if random_y else -2.0
		),
		"speed": randf_range(Constants.STAR_MIN_SPEED, Constants.STAR_MAX_SPEED),
		"size": randf_range(Constants.STAR_MIN_SIZE, Constants.STAR_MAX_SIZE),
	}
