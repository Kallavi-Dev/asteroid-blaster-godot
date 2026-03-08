# Project Architecture

## Pattern
Scene-based composition with Autoload singletons (Godot's built-in architecture pattern).

## Engine
Godot 4.6.x | GDScript | 2D | gl_compatibility renderer

## Layer Overview

| Layer | Responsibility | Location |
|-------|---------------|----------|
| **Autoload** | Global game state, audio | `scripts/autoload/` |
| **Constants** | All magic numbers + enums | `scripts/constants.gd` |
| **Scenes** | Self-contained game entities | `scenes/<category>/` |
| **UI** | HUD, pause, game over | `scenes/ui/` |

## Module Map

```
GameManager (autoload)
  -> emits: score_changed, lives_changed, game_over, game_started, boss_incoming
  -> persistence: high score save/load via FileAccess

AudioManager (autoload, scene-based)
  -> procedural sound generation (AudioStreamWAV)
  -> methods: play_shoot(), play_explosion(), play_hit(), play_powerup()

Main (scenes/main/)
  -> preloads: Bullet, Asteroid, Explosion, PowerUp, Boss
  -> instances: Player, HUD, GameOverScreen, PauseMenu, Starfield
  -> screen shake via Camera2D offset
  -> difficulty ramp via DifficultyTimer
  -> asteroid breakup spawning (large->medium->small)
  -> power-up drops on asteroid kill
  -> boss spawning every N kills

Player (scenes/player/)
  -> emits: shoot(position, angle)
  -> power-up system: shield, rapid fire, spread shot
  -> invincibility frames with tween blink

Asteroid (scenes/enemies/)
  -> emits: destroyed(position, size)
  -> size variants: LARGE, MEDIUM, SMALL
  -> calls: GameManager.add_score(), GameManager.register_kill()

Boss (scenes/enemies/)
  -> health bar, multi-hit, side-to-side movement
  -> 3-way bullet spread attack
  -> spawns BossBullet projectiles

PowerUp (scenes/items/)
  -> emits: collected(type)
  -> types: SHIELD, RAPID_FIRE, SPREAD_SHOT
  -> visual color based on type

Starfield (scenes/main/)
  -> procedural scrolling star background
  -> parallax effect via speed variation

Bullet / BossBullet (scenes/projectiles/, scenes/enemies/)
  -> directional movement, auto-cleanup

Explosion (scenes/effects/)
  -> GPUParticles2D one-shot, auto-frees

HUD (scenes/ui/) -> score + lives display
GameOverScreen (scenes/ui/) -> final score + high score + restart
PauseMenu (scenes/ui/) -> ESC toggle, process_mode ALWAYS
```

## Key Decisions

1. **Area2D for all entities** - No physics simulation needed; overlap detection only
2. **Type-based collision** - `if area is Bullet` instead of collision layers
3. **Polygon2D visuals** - Zero external assets; shapes as vertex arrays
4. **Constants class_name** - Global access without autoload overhead
5. **Signal-driven flow** - GameManager signals decouple all scenes
6. **Procedural audio** - AudioStreamWAV with computed PCM samples
7. **Enum-driven variants** - AsteroidSize and PowerUpType as enums in Constants
8. **Camera2D shake** - Random offset lerped to zero for screen shake effect

## Data Flow

```
Input -> Player._process()
  -> shoot signal (position, angle)
  -> Main._on_player_shoot() -> Bullet instantiated

Asteroid._on_area_entered(Bullet)
  -> GameManager.add_score() + register_kill()
  -> destroyed signal (position, size)
  -> Main._on_asteroid_destroyed()
    -> Explosion instantiated
    -> _spawn_children() (breakup)
    -> _spawn_power_up() (random chance)
    -> _trigger_shake()

GameManager.register_kill()
  -> total_kills % THRESHOLD == 0
  -> boss_incoming signal
  -> Main._on_boss_incoming() -> Boss instantiated

DifficultyTimer.timeout
  -> _spawn_timer.wait_time decreases
  -> asteroids spawn faster over time
```

## Network Layer

### NetworkManager (Autoload)
- Manages ENet connections (host/join/disconnect)
- Signals: player_connected, player_disconnected, connection_succeeded, connection_failed, server_disconnected
- Provides local IP detection for LAN play

### Multiplayer Data Flow
- Host-authoritative: host runs game logic, clients send input
- Player positions synced via MultiplayerSynchronizer
- Entities replicated via MultiplayerSpawner
- Game events (score, lives) broadcast via @rpc
- Shooting: client sends RPC to host → host spawns bullet → MultiplayerSpawner replicates

### Game Modes
- Solo: single player, no networking
- Co-op: shared score + lives, both players fight together
- Competitive: individual scores + lives, winner = highest score

## File Naming
- Scripts: `snake_case.gd` (Godot convention)
- Scenes: `snake_case.tscn`
- Classes: `PascalCase` via `class_name`
- Nodes: `PascalCase` in scene tree
- Constants: `SCREAMING_SNAKE_CASE`
- Signals: `snake_case` past tense (`destroyed`, `game_over`)
- Enums: `PascalCase` name, `SCREAMING_SNAKE_CASE` members
