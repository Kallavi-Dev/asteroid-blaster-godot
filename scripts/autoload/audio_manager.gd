extends Node
## Audio manager using Kenney sound effects.

const SFX_SHOOT: AudioStream = preload("res://assets/audio/sfx_laser1.ogg")
const SFX_EXPLOSION: AudioStream = preload("res://assets/audio/sfx_zap.ogg")
const SFX_HIT: AudioStream = preload("res://assets/audio/sfx_lose.ogg")
const SFX_POWERUP: AudioStream = preload("res://assets/audio/sfx_shieldUp.ogg")

@onready var _sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var _sfx_player_2: AudioStreamPlayer = $SFXPlayer2
@onready var _sfx_player_3: AudioStreamPlayer = $SFXPlayer3


func play_shoot() -> void:
	_play_sound(SFX_SHOOT)


func play_explosion() -> void:
	_play_sound(SFX_EXPLOSION)


func play_hit() -> void:
	_play_sound(SFX_HIT)


func play_powerup() -> void:
	_play_sound(SFX_POWERUP)


func _play_sound(stream: AudioStream) -> void:
	if not _sfx_player.playing:
		_sfx_player.stream = stream
		_sfx_player.play()
	elif not _sfx_player_2.playing:
		_sfx_player_2.stream = stream
		_sfx_player_2.play()
	else:
		_sfx_player_3.stream = stream
		_sfx_player_3.play()
