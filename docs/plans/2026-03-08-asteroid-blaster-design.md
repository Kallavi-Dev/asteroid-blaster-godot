# Asteroid Blaster - Design Document

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a complete 2D space shooter in Godot 4.6 to explore game development fundamentals.

**Architecture:** Scene-based composition with Autoload singleton for game state. Each game entity (player, bullet, asteroid, explosion) is its own scene with paired GDScript. Communication via Godot signals through a central GameManager.

**Tech Stack:** Godot 4.6.x, GDScript, GPUParticles2D, Area2D collision

---

## Game Design

**Core Loop:** Player shoots falling asteroids for points. Avoid getting hit. 3 lives. Game over at 0 lives. Restart.

**Controls:**
- Arrow keys / WASD: Move ship (all 4 directions, clamped to viewport)
- Space: Shoot (with cooldown)

**Entities:**
| Entity | Node Type | Behavior |
|--------|-----------|----------|
| Player | Area2D | 4-directional movement, shooting, invincibility |
| Bullet | Area2D | Moves upward, auto-frees offscreen |
| Asteroid | Area2D | Falls downward, random speed/rotation/scale |
| Explosion | Node2D + GPUParticles2D | One-shot particles, auto-frees |

**Game State (GameManager autoload):**
- `score: int` - incremented on asteroid kill
- `lives: int` - decremented on player hit
- `is_playing: bool` - gates player input and spawning

**Signals:**
- `GameManager.score_changed` -> HUD updates score
- `GameManager.lives_changed` -> HUD updates lives
- `GameManager.game_over` -> stops spawning, shows overlay
- `GameManager.game_started` -> resets state, starts spawning
- `Player.shoot` -> Main spawns bullet
- `Asteroid.destroyed` -> Main spawns explosion

## Visual Design
All visuals are Polygon2D shapes (no external assets):
- Player: cyan arrow/ship shape
- Bullet: yellow elongated rectangle
- Asteroid: brown irregular polygon
- Background: dark navy ColorRect
- Explosion: orange GPU particles

## Project Structure
```
experiment/
├── project.godot
├── .gitignore
├── CLAUDE-ARCHITECTURE.md
├── CLAUDE-PRODUCT.md
├── scenes/
│   ├── main/        (main.tscn + main.gd)
│   ├── player/      (player.tscn + player.gd)
│   ├── projectiles/ (bullet.tscn + bullet.gd)
│   ├── enemies/     (asteroid.tscn + asteroid.gd)
│   ├── effects/     (explosion.tscn + explosion.gd)
│   └── ui/          (hud + game_over_screen)
├── scripts/
│   ├── autoload/    (game_manager.gd)
│   └── constants.gd
└── docs/plans/
```
