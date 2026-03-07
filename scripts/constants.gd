class_name Constants
extends RefCounted
## Central configuration for all game constants.
## Eliminates magic numbers across the codebase.

# -- Window --
const VIEWPORT_WIDTH: int = 1920
const VIEWPORT_HEIGHT: int = 1080

# -- Player --
const PLAYER_SPEED: float = 400.0
const PLAYER_SHOOT_COOLDOWN: float = 0.25
const PLAYER_RAPID_FIRE_COOLDOWN: float = 0.10
const PLAYER_INITIAL_LIVES: int = 3
const PLAYER_INVINCIBILITY_DURATION: float = 2.0
const PLAYER_MARGIN: float = 20.0
const PLAYER_SPREAD_ANGLE: float = 15.0

# -- Bullet --
const BULLET_SPEED: float = 600.0
const BULLET_SPAWN_OFFSET_Y: float = -30.0

# -- Asteroid Sizes --
enum AsteroidSize { LARGE, MEDIUM, SMALL }

const ASTEROID_SIZE_SCALES: Dictionary = {
	AsteroidSize.LARGE: 1.2,
	AsteroidSize.MEDIUM: 0.7,
	AsteroidSize.SMALL: 0.4,
}

const ASTEROID_SIZE_SCORES: Dictionary = {
	AsteroidSize.LARGE: 100,
	AsteroidSize.MEDIUM: 150,
	AsteroidSize.SMALL: 200,
}

const ASTEROID_CHILDREN_ON_BREAK: int = 2
const ASTEROID_MIN_SPEED: float = 100.0
const ASTEROID_MAX_SPEED: float = 300.0
const ASTEROID_SPAWN_INTERVAL: float = 1.2
const ASTEROID_SPAWN_MARGIN: float = 50.0
const ASTEROID_DESPAWN_MARGIN: float = 100.0

# -- Boss --
const BOSS_SPAWN_KILL_THRESHOLD: int = 15
const BOSS_HEALTH: int = 20
const BOSS_SPEED: float = 60.0
const BOSS_SHOOT_INTERVAL: float = 1.5
const BOSS_BULLET_SPEED: float = 300.0
const BOSS_SCORE_VALUE: int = 2000
const BOSS_WIDTH: float = 80.0
const BOSS_HEIGHT: float = 60.0

# -- Power-ups --
enum PowerUpType { SHIELD, RAPID_FIRE, SPREAD_SHOT }

const POWER_UP_DROP_CHANCE: float = 0.15
const POWER_UP_SPEED: float = 120.0
const POWER_UP_DURATION: float = 8.0
const POWER_UP_SIZE: float = 14.0

const POWER_UP_COLORS: Dictionary = {
	PowerUpType.SHIELD: Color(0.2, 1.0, 0.4),
	PowerUpType.RAPID_FIRE: Color(1.0, 0.3, 0.3),
	PowerUpType.SPREAD_SHOT: Color(0.8, 0.4, 1.0),
}

# -- Explosion --
const EXPLOSION_LIFETIME: float = 0.8

# -- Starfield --
const STAR_COUNT: int = 80
const STAR_MIN_SPEED: float = 30.0
const STAR_MAX_SPEED: float = 120.0
const STAR_MIN_SIZE: float = 1.0
const STAR_MAX_SIZE: float = 3.0

# -- Screen Shake --
const SHAKE_DURATION: float = 0.3
const SHAKE_INTENSITY: float = 8.0

# -- Difficulty --
const DIFFICULTY_RAMP_INTERVAL: float = 10.0
const DIFFICULTY_SPAWN_DECREASE: float = 0.08
const DIFFICULTY_MIN_SPAWN_INTERVAL: float = 0.3

# -- Persistence --
const SAVE_FILE_PATH: String = "user://highscore.save"

# -- Network --
const NETWORK_PORT: int = 7000
const NETWORK_MAX_PLAYERS: int = 2

# -- Game Mode --
enum GameMode { SOLO, COOP, COMPETITIVE }

const COOP_LIVES: int = 5
const COMPETITIVE_LIVES: int = 3

# -- Groups --
const GROUP_ASTEROIDS: String = "asteroids"
const GROUP_BULLETS: String = "bullets"
const GROUP_ENEMY_BULLETS: String = "enemy_bullets"
const GROUP_POWER_UPS: String = "power_ups"
