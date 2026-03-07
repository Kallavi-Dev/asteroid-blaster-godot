extends Node2D
## One-shot particle explosion. Auto-frees after particles finish.

@onready var _particles: GPUParticles2D = $GPUParticles2D
@onready var _timer: Timer = $Timer


func _ready() -> void:
	_timer.wait_time = Constants.EXPLOSION_LIFETIME
	_timer.one_shot = true
	_timer.timeout.connect(queue_free)
	_particles.emitting = true
	_timer.start()
