# Multiplayer Asteroid Blaster — Design Document

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add 2-player online/LAN multiplayer (co-op and competitive modes) and convert the game to 1920x1080 desktop widescreen.

**Architecture:** Host-authoritative client-server using Godot's built-in `ENetMultiplayerPeer`. Host runs all game logic; clients send input and receive state. `MultiplayerSpawner` replicates entities, `MultiplayerSynchronizer` syncs positions, `@rpc` handles game events.

**Tech Stack:** Godot 4.6, GDScript, ENetMultiplayerPeer, MultiplayerSpawner, MultiplayerSynchronizer

---

## 1. Network Architecture

```
HOST (Player 1)                     CLIENT (Player 2)
┌─────────────────────┐             ┌─────────────────────┐
│ Player1 (local)     │             │ Player1 (puppet)    │
│ Player2 (puppet)    │◄───ENet────►│ Player2 (local)     │
│ Game Logic (spawn,  │   port 7000 │                     │
│   score, difficulty) │             │                     │
│ MultiplayerSpawner  │             │ MultiplayerSpawner  │
└─────────────────────┘             └─────────────────────┘
```

- **Host** = server + player. Peer ID always `1`.
- **Client** = player only. Gets unique peer ID.
- **ENet** works for both LAN (local IP) and online (public IP + port forward).
- All spawning happens on host → `MultiplayerSpawner` replicates to clients.
- Player positions synced via `MultiplayerSynchronizer`.
- Game events (score, lives, game over) via `@rpc` calls.

## 2. Game Flow

```
Main Menu → Solo       → existing single-player (now 1920x1080)
          → Multiplayer → Lobby → Host (shows IP, waits for join)
                                → Join (enter IP, connect)
                                → Mode select (co-op / competitive)
                                → Both ready → Game starts
                                → Game Over → Results screen → Lobby
```

## 3. Game Modes

### Co-op
- Shared score (one score counter)
- Shared lives pool (5 total)
- Both players fight the same asteroids/bosses together
- Game over when all shared lives depleted
- Combined high score saved

### Competitive
- Individual scores per player
- Individual lives (3 each)
- Same asteroid field, same boss encounters
- When a player loses all lives, they spectate
- Game ends when both players are dead
- Winner = highest score (or last alive if scores equal)
- Victory screen shows winner + both scores

## 4. Desktop Widescreen Conversion

- Viewport: 720×1080 → 1920×1080
- All code uses `Constants.VIEWPORT_WIDTH` so one constant change propagates everywhere
- Wider arena gives 2 players room to maneuver
- HUD: Player 1 info on left, Player 2 info on right
- Background tiling works automatically with TextureRect stretch_mode=1

## 5. New Files

| File | Purpose |
|------|---------|
| `scenes/ui/main_menu.gd` + `.tscn` | Entry point: Solo / Multiplayer |
| `scenes/ui/lobby.gd` + `.tscn` | Host/Join, mode select, ready up, IP display |
| `scenes/ui/victory_screen.gd` + `.tscn` | Competitive results: winner + scores |
| `scripts/autoload/network_manager.gd` | ENet connection, peer events, cleanup |

## 6. Modified Files

| File | Changes |
|------|---------|
| `project.godot` | Add NetworkManager autoload, main scene → main_menu, viewport 1920x1080 |
| `scripts/constants.gd` | VIEWPORT_WIDTH=1920, network constants, GameMode enum |
| `scripts/autoload/game_manager.gd` | Per-player score/lives, mode-aware, RPC-decorated |
| `scenes/player/player.gd` | Authority-based input, RPC shoot, peer ID ownership |
| `scenes/player/player.tscn` | Add MultiplayerSynchronizer |
| `scenes/main/main.gd` | Host-only spawning, MultiplayerSpawner setup, 2-player support |
| `scenes/main/main.tscn` | Add MultiplayerSpawner nodes, update positions for 1920 width |
| `scenes/ui/hud.gd` + `.tscn` | Dual-player score/lives display |
| `scenes/ui/game_over_screen.gd` + `.tscn` | Mode-aware results |

## 7. Unchanged Files

Asteroid, Boss, BossBullet, Bullet, PowerUp, Explosion, Starfield, Shaders — these work as-is. MultiplayerSpawner replicates them automatically.

## 8. Data Flow

### Player Input (client-authoritative movement, host-authoritative shooting)
1. Client presses arrow keys → local position changes
2. MultiplayerSynchronizer syncs position to all peers
3. Client presses Space → `@rpc("authority")` shoot call to host
4. Host spawns bullet → MultiplayerSpawner replicates to all

### Game Events (host-authoritative)
1. Host spawns asteroids on timer → auto-replicated
2. Collision detected on host → host calls `GameManager.add_score.rpc()`
3. Score/lives changes broadcast to all clients via RPC
4. Game over triggered on host → RPC to all clients

## 9. Milestones

1. **Widescreen conversion** — Change viewport to 1920x1080, update all affected positions
2. **NetworkManager + Lobby** — ENet connection, host/join UI, ready system
3. **Main Menu** — Solo/Multiplayer entry point, new main scene
4. **Player multiplayer** — Authority-based input, MultiplayerSynchronizer, 2 players
5. **Entity replication** — MultiplayerSpawner for bullets, asteroids, powerups, boss
6. **Game modes** — Co-op and competitive logic in GameManager
7. **Multiplayer HUD + Results** — Dual-player HUD, victory screen
8. **Polish + Testing** — Edge cases, disconnection handling, cleanup
