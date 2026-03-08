# Product Overview

## Purpose
A 2D space shooter ("Asteroid Blaster") built as a learning project to explore Godot 4 game development on macOS. Demonstrates core Godot patterns: scenes, signals, physics, spawning, UI, game state, audio, particles, and difficulty scaling.

## Major Features
- [x] Player ship with directional movement and shooting
- [x] Asteroid enemies with size variants (large/medium/small breakup)
- [x] Collision system (bullet-asteroid, player-asteroid, boss-player)
- [x] Score tracking with HUD display
- [x] Lives system with invincibility frames
- [x] Explosion particle effects with screen shake
- [x] Start screen with high score display
- [x] Game over screen with high score persistence
- [x] Boss enemy every 15 kills (health bar, 3-way shooting)
- [x] Power-up system (shield, rapid fire, spread shot)
- [x] Scrolling parallax starfield background
- [x] Difficulty ramp (faster spawns over time)
- [x] Pause menu (ESC key)
- [x] Procedural sound effects (shoot, explosion, hit, power-up)
- [x] High score save/load to disk
- [x] 2-Player Multiplayer (Online/LAN via ENet)
- [x] Co-op Mode (shared score, shared lives)
- [x] Competitive Mode (individual scores, winner detection)
- [x] Multiplayer Lobby (host/join, mode select, ready system)
- [x] Main Menu (Solo/Multiplayer/Quit)
- [x] 1920x1080 Desktop Widescreen
- [x] Disconnect Handling (graceful peer/server loss)

## Feature Details

### Player Ship
**Status:** Complete
- Arrow keys / WASD movement (clamped to viewport)
- Space bar shooting with cooldown timer
- Invincibility after damage (blinking tween effect)
- Power-up support: shield (green), rapid fire (red), spread shot (purple)

### Asteroid System
**Status:** Complete
- Three sizes: LARGE (100pts) -> MEDIUM (150pts) -> SMALL (200pts)
- Large breaks into 2 medium, medium into 2 small
- Random speed, rotation per asteroid
- 15% chance to drop power-up on destruction

### Boss Encounters
**Status:** Complete
- Spawns every 15 kills
- 20 HP with health bar display
- Side-to-side movement pattern
- 3-way bullet spread attack
- 2000 points on defeat

### Power-Up System
**Status:** Complete
- Shield: temporary invincibility (green glow)
- Rapid Fire: reduced shoot cooldown (red glow)
- Spread Shot: 3 bullets per shot (purple glow)
- 8-second duration, visual feedback on player

### Audio System
**Status:** Complete
- All sounds generated procedurally (zero audio files)
- Sine wave tones for shooting and power-ups
- White noise for explosions
- Frequency sweep for power-up collection

### Game Polish
**Status:** Complete
- Scrolling starfield with parallax (speed-based alpha)
- Screen shake on explosions
- Difficulty ramp every 10 seconds
- Pause menu with resume/quit
- High score persistence to disk

## Scope Boundaries
- No background music (ambient track)
- No weapon upgrade progression
- No multiple levels/stages
- No online leaderboards

## Changelog
- 2026-03-08: Initial implementation - core game loop
- 2026-03-08: Added all features - boss, power-ups, audio, starfield, screen shake, difficulty, pause, high score
