# Asteroid Blaster

A 2D space shooter built with **Godot 4.6** as a learning project for game development.

```
    /\
   /  \
  / ** \      ←  You
 /______\
    ||

  ◆  ◇  ◆    ←  Asteroids incoming!
 ◇  ◆  ◇  ◆
```

## Features

- **Player ship** — Arrow keys to move, Space to shoot
- **3 asteroid sizes** — Large breaks into medium, medium into small
- **Boss enemy** — Appears every 15 kills with health bar and 3-way bullet spread
- **Power-ups** — Shield (invincibility), Rapid Fire, Spread Shot
- **Difficulty ramp** — Spawn rate increases over time
- **High score** — Persisted to disk across sessions
- **Pause menu** — ESC to pause, resume or quit
- **Visual effects** — Procedural starfield, screen shake, GLSL glow shaders, GPU particles
- **Sound effects** — Kenney SFX for shooting, explosions, hits, and power-ups

## Assets

All sprites, fonts, and sounds from [Kenney's Space Shooter Redux](https://kenney.nl/assets/space-shooter-redux) (CC0 — public domain).

## Requirements

- **Godot 4.6.1** (stable) — [Download here](https://godotengine.org/download/)
- macOS, Windows, or Linux

## Running on macOS

### From the Editor (Development)

1. Download and install [Godot 4.6.1](https://godotengine.org/download/macos/)
2. Open Godot, click **Import** → navigate to this project's `project.godot`
3. Click **Import & Edit**
4. Press **F5** (or the Play button ▶) to run the game

### Exporting as a macOS App (Standalone .app)

To build a standalone `.app` you can double-click from Finder:

1. **Install export templates** — In Godot: `Editor → Manage Export Templates → Download and Install`
2. **Add macOS preset** — Go to `Project → Export → Add → macOS`
3. **Configure** (optional):
   - App name: `Asteroid Blaster`
   - Bundle identifier: `com.kallavidev.asteroidblaster`
   - Set icon if desired
4. **Export** — Click `Export Project` → choose a folder → name it `AsteroidBlaster.app`
5. **Run** — Double-click `AsteroidBlaster.app` in Finder

> **Note:** macOS may block unsigned apps. Right-click → Open → confirm to bypass Gatekeeper. For distribution, you'd need an Apple Developer certificate to sign and notarize the app.

### Fullscreen Mode

The game runs windowed at 720×1080 by default. To make it fullscreen:

**Option A — In `project.godot`** (permanent):
```ini
[display]
window/size/mode=3
```
Mode values: `0` = Windowed, `2` = Minimized, `3` = Maximized, `4` = Fullscreen

**Option B — At runtime via code** (toggle with a key):
```gdscript
DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
```

**Option C — In Godot Editor**: `Project → Project Settings → Display → Window → Size → Mode → Fullscreen`

## Controls

| Key | Action |
|-----|--------|
| ← → | Move left/right |
| ↑ ↓ | Move up/down |
| Space | Shoot |
| ESC | Pause/Resume |

Controls are the same for both players in multiplayer — each player uses their own keyboard on their own machine.

## Multiplayer

### How to Play Together

**LAN (same WiFi):**
1. Both players open the game
2. Player 1: Main Menu → Multiplayer → Host Game (note the IP shown)
3. Player 2: Main Menu → Multiplayer → enter Player 1's IP → Join Game
4. Host selects Co-op or Competitive
5. Both click Ready → game starts

**Online (different networks):**
Same as LAN, but Player 1 needs to:
- Forward port 7000 (UDP) on their router
- Share their public IP (find it at whatismyip.com)

### Game Modes

| Mode | Score | Lives | Win Condition |
|------|-------|-------|---------------|
| Co-op | Shared | 5 shared | Survive together |
| Competitive | Individual | 3 each | Highest score wins |

## Project Structure

```
experiment/
├── assets/              # Kenney sprites, fonts, audio (CC0)
├── scenes/
│   ├── main/            # Main scene, starfield background
│   ├── player/          # Player ship with power-up system
│   ├── enemies/         # Asteroid (3 sizes), Boss, BossBullet
│   ├── projectiles/     # Player bullet with glow shader
│   ├── items/           # Power-up drops
│   ├── effects/         # GPU particle explosions
│   └── ui/              # HUD, game over, pause, main menu, lobby
├── scripts/
│   ├── constants.gd     # All game constants (no magic numbers)
│   └── autoload/        # GameManager, AudioManager, NetworkManager
├── shaders/             # GLSL glow + shield shaders
└── project.godot        # Engine config
```

## Architecture

Signal-driven architecture with `GameManager` as the central event bus. Scenes communicate through signals, not direct references. See [CLAUDE-ARCHITECTURE.md](CLAUDE-ARCHITECTURE.md) for details.

## License

Code: MIT | Assets: [CC0 (Kenney)](https://creativecommons.org/publicdomain/zero/1.0/)
