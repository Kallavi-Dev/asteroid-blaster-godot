# Multiplayer Asteroid Blaster — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add 2-player online/LAN multiplayer with co-op and competitive modes, convert viewport to 1920×1080 desktop widescreen.

**Architecture:** Host-authoritative client-server via Godot's `ENetMultiplayerPeer`. Host runs game logic (spawning, scoring, collisions). Clients send input locally and sync positions via `MultiplayerSynchronizer`. Entity spawning replicated via `MultiplayerSpawner`. Game events broadcast via `@rpc`.

**Tech Stack:** Godot 4.6, GDScript, ENetMultiplayerPeer, MultiplayerSpawner, MultiplayerSynchronizer, @rpc

---

## Milestone 1: Widescreen Conversion (1920×1080)

### Task 1.1: Update viewport constants and project settings

**Files:**
- Modify: `scripts/constants.gd`
- Modify: `project.godot`

**Step 1: Update constants.gd**

Change `VIEWPORT_WIDTH` from 720 to 1920:

```gdscript
# -- Window --
const VIEWPORT_WIDTH: int = 1920
const VIEWPORT_HEIGHT: int = 1080
```

**Step 2: Update project.godot**

Change viewport width:

```ini
[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"
```

**Step 3: Verify**

Open in Godot, press F5. The game should run in a wider window. Player spawns at center-bottom, asteroids span the full width, background tiles across 1920px.

### Task 1.2: Update main scene positions for widescreen

**Files:**
- Modify: `scenes/main/main.tscn`

**Step 1: Update Camera2D position** (center of new viewport)

```
position = Vector2(960, 540)
```

**Step 2: Update Player start position**

```
position = Vector2(960, 980)
```

**Step 3: Update Background TextureRect width**

```
offset_right = 1920.0
```

**Step 4: Verify**

Run the game. Background should tile across full width, camera centered, player centered at bottom.

### Task 1.3: Commit and push Milestone 1

```bash
git add -A
git commit -m "feat: convert viewport to 1920x1080 desktop widescreen

All game elements scale automatically via Constants.VIEWPORT_WIDTH.
Background tiles, camera centers, player spawns at new center.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push
```

---

## Milestone 2: Constants & GameMode Enum

### Task 2.1: Add network constants and GameMode enum

**Files:**
- Modify: `scripts/constants.gd`

**Step 1: Add network section and game mode enum**

Add after the `# -- Persistence --` section:

```gdscript
# -- Network --
const NETWORK_PORT: int = 7000
const NETWORK_MAX_PLAYERS: int = 2

# -- Game Mode --
enum GameMode { SOLO, COOP, COMPETITIVE }

const COOP_LIVES: int = 5
const COMPETITIVE_LIVES: int = 3
```

### Task 2.2: Commit and push

```bash
git add scripts/constants.gd
git commit -m "feat: add network constants and GameMode enum

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push
```

---

## Milestone 3: NetworkManager Autoload

### Task 3.1: Create NetworkManager autoload

**Files:**
- Create: `scripts/autoload/network_manager.gd`

**Step 1: Write the full NetworkManager**

```gdscript
extends Node
## Manages ENet multiplayer connections for LAN and online play.
## Handles hosting, joining, peer events, and cleanup.

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_succeeded
signal connection_failed
signal server_disconnected

var peer: ENetMultiplayerPeer = null
var player_ids: Array[int] = []
var is_host: bool = false


func host_game() -> Error:
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(Constants.NETWORK_PORT, Constants.NETWORK_MAX_PLAYERS)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	is_host = true
	player_ids.append(1)
	_connect_signals()
	return OK


func join_game(address: String) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(address, Constants.NETWORK_PORT)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	is_host = false
	_connect_signals()
	return OK


func disconnect_game() -> void:
	if peer:
		multiplayer.multiplayer_peer = null
		peer = null
	player_ids.clear()
	is_host = false


func get_local_ip() -> String:
	var addresses := IP.get_local_addresses()
	for addr in addresses:
		if addr.begins_with("192.168.") or addr.begins_with("10.") or addr.begins_with("172."):
			return addr
	return "127.0.0.1"


func _connect_signals() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_peer_connected(id: int) -> void:
	player_ids.append(id)
	player_connected.emit(id)


func _on_peer_disconnected(id: int) -> void:
	player_ids.erase(id)
	player_disconnected.emit(id)


func _on_connected_to_server() -> void:
	player_ids.append(multiplayer.get_unique_id())
	connection_succeeded.emit()


func _on_connection_failed() -> void:
	disconnect_game()
	connection_failed.emit()


func _on_server_disconnected() -> void:
	disconnect_game()
	server_disconnected.emit()
```

### Task 3.2: Register NetworkManager as autoload

**Files:**
- Modify: `project.godot`

Add to `[autoload]` section:

```ini
[autoload]
GameManager="*res://scripts/autoload/game_manager.gd"
AudioManager="*res://scripts/autoload/audio_manager.tscn"
NetworkManager="*res://scripts/autoload/network_manager.gd"
```

### Task 3.3: Commit and push

```bash
git add scripts/autoload/network_manager.gd project.godot
git commit -m "feat: add NetworkManager autoload for ENet multiplayer

Handles hosting, joining, peer events, disconnect, and local IP detection.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push
```

---

## Milestone 4: Main Menu & Lobby UI

### Task 4.1: Create Main Menu scene

**Files:**
- Create: `scenes/ui/main_menu.gd`
- Create: `scenes/ui/main_menu.tscn`

**Step 1: Write main_menu.gd**

```gdscript
extends Control
## Main menu: entry point with Solo and Multiplayer options.

@onready var _solo_button: Button = $CenterContainer/VBoxContainer/SoloButton
@onready var _multi_button: Button = $CenterContainer/VBoxContainer/MultiButton
@onready var _quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	_solo_button.pressed.connect(_on_solo_pressed)
	_multi_button.pressed.connect(_on_multi_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_solo_pressed() -> void:
	GameManager.game_mode = Constants.GameMode.SOLO
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_multi_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
```

**Step 2: Write main_menu.tscn**

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scenes/ui/main_menu.gd" id="1_menu"]
[ext_resource type="FontFile" path="res://assets/fonts/kenvector_future.ttf" id="2_font"]

[sub_resource type="LabelSettings" id="LabelSettings_title"]
font = ExtResource("2_font")
font_size = 48
font_color = Color(1, 1, 1, 1)

[node name="MainMenu" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_menu")

[node name="CenterContainer" type="CenterContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="VBoxContainer" type="VBoxContainer" parent="CenterContainer"]
layout_mode = 2
theme_override_constants/separation = 30
alignment = 1

[node name="TitleLabel" type="Label" parent="CenterContainer/VBoxContainer"]
layout_mode = 2
horizontal_alignment = 1
text = "ASTEROID BLASTER"
label_settings = SubResource("LabelSettings_title")

[node name="SoloButton" type="Button" parent="CenterContainer/VBoxContainer"]
layout_mode = 2
custom_minimum_size = Vector2(300, 60)
size_flags_horizontal = 4
text = "SOLO"

[node name="MultiButton" type="Button" parent="CenterContainer/VBoxContainer"]
layout_mode = 2
custom_minimum_size = Vector2(300, 60)
size_flags_horizontal = 4
text = "MULTIPLAYER"

[node name="QuitButton" type="Button" parent="CenterContainer/VBoxContainer"]
layout_mode = 2
custom_minimum_size = Vector2(300, 60)
size_flags_horizontal = 4
text = "QUIT"
```

### Task 4.2: Create Lobby scene

**Files:**
- Create: `scenes/ui/lobby.gd`
- Create: `scenes/ui/lobby.tscn`

**Step 1: Write lobby.gd**

```gdscript
extends Control
## Multiplayer lobby: host or join a game, select mode, ready up.

@onready var _host_button: Button = $PanelContainer/VBoxContainer/HostJoin/HostButton
@onready var _join_button: Button = $PanelContainer/VBoxContainer/HostJoin/JoinButton
@onready var _ip_input: LineEdit = $PanelContainer/VBoxContainer/IPContainer/IPInput
@onready var _ip_display: Label = $PanelContainer/VBoxContainer/IPDisplay
@onready var _status_label: Label = $PanelContainer/VBoxContainer/StatusLabel
@onready var _mode_coop: Button = $PanelContainer/VBoxContainer/ModeContainer/CoopButton
@onready var _mode_competitive: Button = $PanelContainer/VBoxContainer/ModeContainer/CompetitiveButton
@onready var _ready_button: Button = $PanelContainer/VBoxContainer/ReadyButton
@onready var _back_button: Button = $PanelContainer/VBoxContainer/BackButton

var _local_ready: bool = false
var _remote_ready: bool = false
var _selected_mode: Constants.GameMode = Constants.GameMode.COOP


func _ready() -> void:
	_host_button.pressed.connect(_on_host_pressed)
	_join_button.pressed.connect(_on_join_pressed)
	_mode_coop.pressed.connect(_on_coop_pressed)
	_mode_competitive.pressed.connect(_on_competitive_pressed)
	_ready_button.pressed.connect(_on_ready_pressed)
	_back_button.pressed.connect(_on_back_pressed)

	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)

	_ready_button.visible = false
	_ip_display.text = ""
	_status_label.text = "Host a game or join one"
	_update_mode_buttons()


func _on_host_pressed() -> void:
	var error := NetworkManager.host_game()
	if error != OK:
		_status_label.text = "Failed to create server (port in use?)"
		return
	_ip_display.text = "YOUR IP: %s" % NetworkManager.get_local_ip()
	_status_label.text = "Waiting for player to join..."
	_host_button.disabled = true
	_join_button.disabled = true
	_ip_input.editable = false


func _on_join_pressed() -> void:
	var address := _ip_input.text.strip_edges()
	if address.is_empty():
		_status_label.text = "Enter host IP address"
		return
	var error := NetworkManager.join_game(address)
	if error != OK:
		_status_label.text = "Failed to connect"
		return
	_status_label.text = "Connecting to %s..." % address
	_host_button.disabled = true
	_join_button.disabled = true
	_ip_input.editable = false


func _on_player_connected(_peer_id: int) -> void:
	_status_label.text = "Player joined! Select mode and ready up."
	_ready_button.visible = true


func _on_player_disconnected(_peer_id: int) -> void:
	_status_label.text = "Player disconnected."
	_ready_button.visible = false
	_local_ready = false
	_remote_ready = false


func _on_connection_succeeded() -> void:
	_status_label.text = "Connected! Waiting for host to select mode."
	_ready_button.visible = true


func _on_connection_failed() -> void:
	_status_label.text = "Connection failed. Try again."
	_host_button.disabled = false
	_join_button.disabled = false
	_ip_input.editable = true


func _on_coop_pressed() -> void:
	if not NetworkManager.is_host:
		return
	_selected_mode = Constants.GameMode.COOP
	_update_mode_buttons()
	_sync_mode.rpc(Constants.GameMode.COOP)


func _on_competitive_pressed() -> void:
	if not NetworkManager.is_host:
		return
	_selected_mode = Constants.GameMode.COMPETITIVE
	_update_mode_buttons()
	_sync_mode.rpc(Constants.GameMode.COMPETITIVE)


func _update_mode_buttons() -> void:
	_mode_coop.disabled = not NetworkManager.is_host
	_mode_competitive.disabled = not NetworkManager.is_host
	_mode_coop.modulate = Color.GREEN if _selected_mode == Constants.GameMode.COOP else Color.WHITE
	_mode_competitive.modulate = Color.GREEN if _selected_mode == Constants.GameMode.COMPETITIVE else Color.WHITE


func _on_ready_pressed() -> void:
	_local_ready = not _local_ready
	_ready_button.text = "READY!" if _local_ready else "READY UP"
	_ready_button.modulate = Color.GREEN if _local_ready else Color.WHITE
	_notify_ready.rpc(_local_ready)
	_check_all_ready()


func _check_all_ready() -> void:
	if _local_ready and _remote_ready:
		if NetworkManager.is_host:
			_start_game.rpc()


func _on_back_pressed() -> void:
	NetworkManager.disconnect_game()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


@rpc("any_peer", "call_local", "reliable")
func _sync_mode(mode: int) -> void:
	_selected_mode = mode as Constants.GameMode
	_update_mode_buttons()


@rpc("any_peer", "reliable")
func _notify_ready(is_ready: bool) -> void:
	_remote_ready = is_ready
	_status_label.text = "Other player is ready!" if is_ready else "Waiting for other player..."
	_check_all_ready()


@rpc("authority", "call_local", "reliable")
func _start_game() -> void:
	GameManager.game_mode = _selected_mode
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
```

**Step 2: Write lobby.tscn**

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scenes/ui/lobby.gd" id="1_lobby"]
[ext_resource type="FontFile" path="res://assets/fonts/kenvector_future.ttf" id="2_font"]

[sub_resource type="LabelSettings" id="LabelSettings_lobby"]
font = ExtResource("2_font")
font_size = 22
font_color = Color(1, 1, 1, 1)

[sub_resource type="LabelSettings" id="LabelSettings_title"]
font = ExtResource("2_font")
font_size = 36
font_color = Color(1, 1, 1, 1)

[node name="Lobby" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_lobby")

[node name="PanelContainer" type="PanelContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -250.0
offset_top = -280.0
offset_right = 250.0
offset_bottom = 280.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBoxContainer" type="VBoxContainer" parent="PanelContainer"]
layout_mode = 2
theme_override_constants/separation = 18
alignment = 1

[node name="TitleLabel" type="Label" parent="PanelContainer/VBoxContainer"]
layout_mode = 2
horizontal_alignment = 1
text = "MULTIPLAYER LOBBY"
label_settings = SubResource("LabelSettings_title")

[node name="HostJoin" type="HBoxContainer" parent="PanelContainer/VBoxContainer"]
layout_mode = 2
theme_override_constants/separation = 20
alignment = 1

[node name="HostButton" type="Button" parent="PanelContainer/VBoxContainer/HostJoin"]
layout_mode = 2
custom_minimum_size = Vector2(200, 50)
text = "HOST GAME"

[node name="JoinButton" type="Button" parent="PanelContainer/VBoxContainer/HostJoin"]
layout_mode = 2
custom_minimum_size = Vector2(200, 50)
text = "JOIN GAME"

[node name="IPContainer" type="HBoxContainer" parent="PanelContainer/VBoxContainer"]
layout_mode = 2
alignment = 1

[node name="IPLabel" type="Label" parent="PanelContainer/VBoxContainer/IPContainer"]
layout_mode = 2
text = "IP:"
label_settings = SubResource("LabelSettings_lobby")

[node name="IPInput" type="LineEdit" parent="PanelContainer/VBoxContainer/IPContainer"]
layout_mode = 2
custom_minimum_size = Vector2(250, 0)
placeholder_text = "192.168.1.x"

[node name="IPDisplay" type="Label" parent="PanelContainer/VBoxContainer"]
layout_mode = 2
horizontal_alignment = 1
label_settings = SubResource("LabelSettings_lobby")
text = ""

[node name="ModeContainer" type="HBoxContainer" parent="PanelContainer/VBoxContainer"]
layout_mode = 2
theme_override_constants/separation = 20
alignment = 1

[node name="CoopButton" type="Button" parent="PanelContainer/VBoxContainer/ModeContainer"]
layout_mode = 2
custom_minimum_size = Vector2(200, 50)
text = "CO-OP"

[node name="CompetitiveButton" type="Button" parent="PanelContainer/VBoxContainer/ModeContainer"]
layout_mode = 2
custom_minimum_size = Vector2(200, 50)
text = "COMPETITIVE"

[node name="StatusLabel" type="Label" parent="PanelContainer/VBoxContainer"]
layout_mode = 2
horizontal_alignment = 1
label_settings = SubResource("LabelSettings_lobby")
text = "Host a game or join one"

[node name="ReadyButton" type="Button" parent="PanelContainer/VBoxContainer"]
layout_mode = 2
custom_minimum_size = Vector2(200, 60)
size_flags_horizontal = 4
text = "READY UP"

[node name="BackButton" type="Button" parent="PanelContainer/VBoxContainer"]
layout_mode = 2
custom_minimum_size = Vector2(200, 40)
size_flags_horizontal = 4
text = "BACK"
```

### Task 4.3: Update project.godot main scene

**Files:**
- Modify: `project.godot`

Change `run/main_scene`:

```ini
run/main_scene="res://scenes/ui/main_menu.tscn"
```

### Task 4.4: Commit and push Milestone 4

```bash
git add -A
git commit -m "feat: add main menu and multiplayer lobby

Main menu with Solo/Multiplayer/Quit. Lobby supports host/join,
co-op/competitive mode selection, ready system, and IP display.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push
```

---

## Milestone 5: GameManager Multiplayer Refactor

### Task 5.1: Refactor GameManager for multiplayer modes

**Files:**
- Modify: `scripts/autoload/game_manager.gd`

**Step 1: Replace the entire game_manager.gd with mode-aware version**

```gdscript
extends Node
## Global game state manager (autoload singleton).
## Tracks score, lives, difficulty, high score, game flow.
## Supports Solo, Co-op, and Competitive modes.

signal score_changed(new_score: int, peer_id: int)
signal lives_changed(new_lives: int, peer_id: int)
signal game_over
signal game_started
signal boss_incoming
signal player_eliminated(peer_id: int)

var game_mode: Constants.GameMode = Constants.GameMode.SOLO
var is_playing: bool = false
var high_score: int = 0
var total_kills: int = 0
var _boss_spawned_at_threshold: int = 0

## Per-player state: { peer_id: { "score": int, "lives": int, "alive": bool } }
var player_states: Dictionary = {}

## Solo mode backward-compatible accessors
var score: int:
	get:
		if game_mode == Constants.GameMode.SOLO:
			return player_states.get(1, {}).get("score", 0)
		return get_total_score()

var lives: int:
	get:
		if game_mode == Constants.GameMode.SOLO:
			return player_states.get(1, {}).get("lives", 0)
		if game_mode == Constants.GameMode.COOP:
			return player_states.get(1, {}).get("lives", 0)
		return 0


func _ready() -> void:
	_load_high_score()


func start_game() -> void:
	total_kills = 0
	_boss_spawned_at_threshold = 0
	is_playing = true
	player_states.clear()

	match game_mode:
		Constants.GameMode.SOLO:
			_init_player_state(1, Constants.PLAYER_INITIAL_LIVES)
		Constants.GameMode.COOP:
			for peer_id in _get_all_peer_ids():
				_init_player_state(peer_id, Constants.COOP_LIVES)
		Constants.GameMode.COMPETITIVE:
			for peer_id in _get_all_peer_ids():
				_init_player_state(peer_id, Constants.COMPETITIVE_LIVES)

	game_started.emit()


func _init_player_state(peer_id: int, initial_lives: int) -> void:
	var shared_lives := initial_lives if game_mode != Constants.GameMode.COOP else 0
	player_states[peer_id] = {
		"score": 0,
		"lives": initial_lives if game_mode != Constants.GameMode.COOP else 0,
		"alive": true,
	}
	if game_mode == Constants.GameMode.COOP:
		# Co-op: shared lives stored on host (peer_id 1)
		if peer_id == 1:
			player_states[peer_id]["lives"] = initial_lives
	else:
		player_states[peer_id]["lives"] = initial_lives

	score_changed.emit(player_states[peer_id]["score"], peer_id)
	lives_changed.emit(get_lives(peer_id), peer_id)


func add_score(points: int, peer_id: int = 1) -> void:
	if game_mode == Constants.GameMode.COOP:
		# Co-op: add to host's score (shared)
		player_states[1]["score"] = player_states[1].get("score", 0) + points
		score_changed.emit(player_states[1]["score"], 1)
	else:
		if peer_id in player_states:
			player_states[peer_id]["score"] = player_states[peer_id].get("score", 0) + points
			score_changed.emit(player_states[peer_id]["score"], peer_id)


@rpc("authority", "call_local", "reliable")
func sync_score(peer_id: int, new_score: int) -> void:
	if peer_id in player_states:
		player_states[peer_id]["score"] = new_score
		score_changed.emit(new_score, peer_id)


@rpc("authority", "call_local", "reliable")
func sync_lives(peer_id: int, new_lives: int) -> void:
	if peer_id in player_states:
		player_states[peer_id]["lives"] = new_lives
		lives_changed.emit(new_lives, peer_id)


func register_kill() -> void:
	total_kills += 1
	var threshold := Constants.BOSS_SPAWN_KILL_THRESHOLD
	if total_kills > 0 and total_kills % threshold == 0 and total_kills != _boss_spawned_at_threshold:
		_boss_spawned_at_threshold = total_kills
		boss_incoming.emit()


func lose_life(peer_id: int = 1) -> void:
	if game_mode == Constants.GameMode.COOP:
		# Shared lives on host
		player_states[1]["lives"] -= 1
		var remaining: int = player_states[1]["lives"]
		lives_changed.emit(remaining, 1)
		if remaining <= 0:
			_end_game()
	else:
		if peer_id in player_states:
			player_states[peer_id]["lives"] -= 1
			var remaining: int = player_states[peer_id]["lives"]
			lives_changed.emit(remaining, peer_id)
			if remaining <= 0:
				player_states[peer_id]["alive"] = false
				player_eliminated.emit(peer_id)
				_check_all_eliminated()


func _check_all_eliminated() -> void:
	if game_mode == Constants.GameMode.SOLO:
		_end_game()
		return
	for state in player_states.values():
		if state["alive"]:
			return
	_end_game()


func _end_game() -> void:
	is_playing = false
	_update_high_score()
	game_over.emit()


func reset() -> void:
	player_states.clear()
	total_kills = 0
	_boss_spawned_at_threshold = 0
	is_playing = false


func get_score(peer_id: int) -> int:
	if game_mode == Constants.GameMode.COOP:
		return player_states.get(1, {}).get("score", 0)
	return player_states.get(peer_id, {}).get("score", 0)


func get_lives(peer_id: int) -> int:
	if game_mode == Constants.GameMode.COOP:
		return player_states.get(1, {}).get("lives", 0)
	return player_states.get(peer_id, {}).get("lives", 0)


func get_total_score() -> int:
	var total := 0
	for state in player_states.values():
		total += state.get("score", 0)
	return total


func is_player_alive(peer_id: int) -> bool:
	return player_states.get(peer_id, {}).get("alive", false)


func get_winner_id() -> int:
	var best_id := -1
	var best_score := -1
	for peer_id in player_states:
		var s: int = player_states[peer_id]["score"]
		if s > best_score:
			best_score = s
			best_id = peer_id
	return best_id


func get_high_score() -> int:
	return high_score


func _get_all_peer_ids() -> Array[int]:
	if game_mode == Constants.GameMode.SOLO:
		return [1]
	var ids: Array[int] = [1]
	for pid in NetworkManager.player_ids:
		if pid != 1 and pid not in ids:
			ids.append(pid)
	return ids


func _update_high_score() -> void:
	var current := get_total_score() if game_mode == Constants.GameMode.COOP else score
	if current > high_score:
		high_score = current
		_save_high_score()


func _save_high_score() -> void:
	var file := FileAccess.open(Constants.SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_32(high_score)


func _load_high_score() -> void:
	if FileAccess.file_exists(Constants.SAVE_FILE_PATH):
		var file := FileAccess.open(Constants.SAVE_FILE_PATH, FileAccess.READ)
		if file:
			high_score = file.get_32()
```

### Task 5.2: Commit and push Milestone 5

```bash
git add scripts/autoload/game_manager.gd
git commit -m "feat: refactor GameManager for multiplayer modes

Per-player score/lives tracking, co-op shared lives, competitive
individual scoring, RPC sync methods, winner detection.
Backward-compatible with solo mode via property accessors.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push
```

---

## Milestone 6: Multiplayer Player & Entity Replication

### Task 6.1: Refactor Player for multiplayer authority

**Files:**
- Modify: `scenes/player/player.gd`

**Step 1: Replace player.gd with authority-aware version**

```gdscript
class_name Player
extends Area2D
## Player ship: moves with arrow keys/WASD, shoots with Space.
## In multiplayer, only processes input if this peer has authority.

signal shoot(bullet_position: Vector2, angle: float)

var _can_shoot: bool = true
var _is_invincible: bool = false
var _has_shield: bool = false
var _has_rapid_fire: bool = false
var _has_spread_shot: bool = false
var peer_id: int = 1

@onready var _shoot_timer: Timer = $ShootTimer
@onready var _invincibility_timer: Timer = $InvincibilityTimer
@onready var _ship_sprite: Sprite2D = $ShipSprite
@onready var _engine_flame: GPUParticles2D = $EngineFlame
@onready var _power_up_timer: Timer = $PowerUpTimer


func _ready() -> void:
	_shoot_timer.wait_time = Constants.PLAYER_SHOOT_COOLDOWN
	_shoot_timer.one_shot = true
	_shoot_timer.timeout.connect(_on_shoot_timer_timeout)

	_invincibility_timer.wait_time = Constants.PLAYER_INVINCIBILITY_DURATION
	_invincibility_timer.one_shot = true
	_invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)

	_power_up_timer.one_shot = true
	_power_up_timer.timeout.connect(_on_power_up_timer_timeout)


func _process(delta: float) -> void:
	if not GameManager.is_playing:
		_engine_flame.emitting = false
		return
	if not _is_local_player():
		return
	_engine_flame.emitting = true
	_handle_movement(delta)
	_handle_shooting()


func _is_local_player() -> bool:
	if GameManager.game_mode == Constants.GameMode.SOLO:
		return true
	return peer_id == multiplayer.get_unique_id()


func _handle_movement(delta: float) -> void:
	var velocity := Vector2.ZERO

	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1.0
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1.0
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1.0

	if velocity.length() > 0.0:
		velocity = velocity.normalized() * Constants.PLAYER_SPEED

	position += velocity * delta
	position = position.clamp(
		Vector2(Constants.PLAYER_MARGIN, Constants.PLAYER_MARGIN),
		Vector2(
			Constants.VIEWPORT_WIDTH - Constants.PLAYER_MARGIN,
			Constants.VIEWPORT_HEIGHT - Constants.PLAYER_MARGIN
		)
	)

	_ship_sprite.rotation = velocity.x / Constants.PLAYER_SPEED * 0.3


func _handle_shooting() -> void:
	if Input.is_key_pressed(KEY_SPACE) and _can_shoot:
		_can_shoot = false
		var cooldown := Constants.PLAYER_RAPID_FIRE_COOLDOWN if _has_rapid_fire else Constants.PLAYER_SHOOT_COOLDOWN
		_shoot_timer.wait_time = cooldown
		_shoot_timer.start()

		var spawn_pos := global_position + Vector2(0, Constants.BULLET_SPAWN_OFFSET_Y)

		if GameManager.game_mode == Constants.GameMode.SOLO:
			shoot.emit(spawn_pos, 0.0)
			if _has_spread_shot:
				shoot.emit(spawn_pos, -deg_to_rad(Constants.PLAYER_SPREAD_ANGLE))
				shoot.emit(spawn_pos, deg_to_rad(Constants.PLAYER_SPREAD_ANGLE))
		else:
			_request_shoot.rpc_id(1, spawn_pos, 0.0)
			if _has_spread_shot:
				_request_shoot.rpc_id(1, spawn_pos, -deg_to_rad(Constants.PLAYER_SPREAD_ANGLE))
				_request_shoot.rpc_id(1, spawn_pos, deg_to_rad(Constants.PLAYER_SPREAD_ANGLE))

		AudioManager.play_shoot()


func take_damage() -> void:
	if _is_invincible or _has_shield:
		if _has_shield:
			_has_shield = false
			_ship_sprite.modulate = Color.WHITE
		return
	AudioManager.play_hit()
	GameManager.lose_life(peer_id)
	if GameManager.is_player_alive(peer_id):
		_start_invincibility()
	else:
		visible = false


func apply_power_up(power_type: Constants.PowerUpType) -> void:
	_clear_power_ups()
	_power_up_timer.wait_time = Constants.POWER_UP_DURATION
	_power_up_timer.start()

	match power_type:
		Constants.PowerUpType.SHIELD:
			_has_shield = true
			_ship_sprite.modulate = Constants.POWER_UP_COLORS[Constants.PowerUpType.SHIELD]
		Constants.PowerUpType.RAPID_FIRE:
			_has_rapid_fire = true
			_ship_sprite.modulate = Constants.POWER_UP_COLORS[Constants.PowerUpType.RAPID_FIRE]
		Constants.PowerUpType.SPREAD_SHOT:
			_has_spread_shot = true
			_ship_sprite.modulate = Constants.POWER_UP_COLORS[Constants.PowerUpType.SPREAD_SHOT]


@rpc("any_peer", "reliable")
func _request_shoot(bullet_position: Vector2, angle: float) -> void:
	# Only host processes shoot requests
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	shoot.emit(bullet_position, angle)


func _clear_power_ups() -> void:
	_has_shield = false
	_has_rapid_fire = false
	_has_spread_shot = false
	_ship_sprite.modulate = Color.WHITE


func _start_invincibility() -> void:
	_is_invincible = true
	_invincibility_timer.start()

	var blink_count := int(Constants.PLAYER_INVINCIBILITY_DURATION / 0.15)
	var tween := create_tween()
	tween.set_loops(blink_count)
	tween.tween_property(_ship_sprite, "modulate:a", 0.2, 0.075)
	tween.tween_property(_ship_sprite, "modulate:a", 1.0, 0.075)


func _on_shoot_timer_timeout() -> void:
	_can_shoot = true


func _on_invincibility_timer_timeout() -> void:
	_is_invincible = false
	_ship_sprite.modulate.a = 1.0


func _on_power_up_timer_timeout() -> void:
	_clear_power_ups()
```

### Task 6.2: Update player.tscn with MultiplayerSynchronizer

**Files:**
- Modify: `scenes/player/player.tscn`

Add a `MultiplayerSynchronizer` node to sync position. Add it after the existing nodes:

```
[node name="MultiplayerSynchronizer" type="MultiplayerSynchronizer" parent="."]
replication_config = SubResource("SceneReplicationConfig_player")
```

And add a sub_resource for the replication config:

```
[sub_resource type="SceneReplicationConfig" id="SceneReplicationConfig_player"]
properties/0/path = NodePath(".:position")
properties/0/spawn = true
properties/0/replication_mode = 1
```

**Note:** `replication_mode = 1` means "always sync". The full .tscn will need the `load_steps` incremented and the new sub_resource and node added.

### Task 6.3: Refactor main.gd for multiplayer spawning

**Files:**
- Modify: `scenes/main/main.gd`

**Step 1: Replace main.gd with multiplayer-aware version**

```gdscript
extends Node2D
## Main game scene. Orchestrates spawning, bullet creation, game flow,
## screen shake, difficulty ramping, boss encounters, and power-up drops.
## In multiplayer, host manages spawning; entities replicate via MultiplayerSpawner.

const BULLET_SCENE: PackedScene = preload("res://scenes/projectiles/bullet.tscn")
const ASTEROID_SCENE: PackedScene = preload("res://scenes/enemies/asteroid.tscn")
const EXPLOSION_SCENE: PackedScene = preload("res://scenes/effects/explosion.tscn")
const POWER_UP_SCENE: PackedScene = preload("res://scenes/items/power_up.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/enemies/boss.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

@onready var _spawn_timer: Timer = $SpawnTimer
@onready var _difficulty_timer: Timer = $DifficultyTimer
@onready var _camera: Camera2D = $Camera2D
@onready var _start_button: Button = $StartUI/CenterContainer/VBoxContainer/StartButton
@onready var _start_ui: CanvasLayer = $StartUI
@onready var _high_score_label: Label = $StartUI/CenterContainer/VBoxContainer/HighScoreLabel
@onready var _entities: Node2D = $Entities
@onready var _players_node: Node2D = $Players

var _shake_amount: float = 0.0
var _players: Dictionary = {}  # { peer_id: Player }


func _ready() -> void:
	_spawn_timer.wait_time = Constants.ASTEROID_SPAWN_INTERVAL
	_spawn_timer.timeout.connect(_spawn_asteroid)

	_difficulty_timer.wait_time = Constants.DIFFICULTY_RAMP_INTERVAL
	_difficulty_timer.timeout.connect(_on_difficulty_tick)

	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over.connect(_on_game_over)
	GameManager.boss_incoming.connect(_on_boss_incoming)

	if GameManager.game_mode == Constants.GameMode.SOLO:
		_start_button.pressed.connect(_on_start_pressed)
		_update_high_score_display()
	else:
		# In multiplayer, game starts immediately (lobby handled ready)
		_start_ui.visible = false
		GameManager.start_game()


func _process(delta: float) -> void:
	if _shake_amount > 0.0:
		_camera.offset = Vector2(
			randf_range(-_shake_amount, _shake_amount),
			randf_range(-_shake_amount, _shake_amount)
		)
		_shake_amount = lerpf(_shake_amount, 0.0, 10.0 * delta)
		if _shake_amount < 0.5:
			_shake_amount = 0.0
			_camera.offset = Vector2.ZERO


func _on_start_pressed() -> void:
	GameManager.start_game()


func _on_game_started() -> void:
	_start_ui.visible = false
	_clear_entities()
	_spawn_players()
	_spawn_timer.wait_time = Constants.ASTEROID_SPAWN_INTERVAL
	_spawn_timer.start()
	_difficulty_timer.start()


func _spawn_players() -> void:
	if GameManager.game_mode == Constants.GameMode.SOLO:
		var player := PLAYER_SCENE.instantiate()
		player.peer_id = 1
		player.position = Vector2(Constants.VIEWPORT_WIDTH / 2.0, Constants.VIEWPORT_HEIGHT - 100.0)
		player.shoot.connect(_on_player_shoot)
		_players_node.add_child(player)
		_players[1] = player
	else:
		var peer_ids := [1]
		for pid in NetworkManager.player_ids:
			if pid != 1 and pid not in peer_ids:
				peer_ids.append(pid)

		var spawn_positions := [
			Vector2(Constants.VIEWPORT_WIDTH / 3.0, Constants.VIEWPORT_HEIGHT - 100.0),
			Vector2(Constants.VIEWPORT_WIDTH * 2.0 / 3.0, Constants.VIEWPORT_HEIGHT - 100.0),
		]

		for i in peer_ids.size():
			var player := PLAYER_SCENE.instantiate()
			player.peer_id = peer_ids[i]
			player.name = "Player_%d" % peer_ids[i]
			player.position = spawn_positions[i]
			player.shoot.connect(_on_player_shoot)
			_players_node.add_child(player)
			_players[peer_ids[i]] = player


func _on_game_over() -> void:
	_spawn_timer.stop()
	_difficulty_timer.stop()
	for player in _players.values():
		player.visible = false


func _on_player_shoot(bullet_position: Vector2, angle: float) -> void:
	var bullet := BULLET_SCENE.instantiate()
	bullet.position = bullet_position
	bullet.direction = Vector2.UP.rotated(angle)
	bullet.add_to_group(Constants.GROUP_BULLETS)
	_entities.add_child(bullet)


func _spawn_asteroid() -> void:
	if not _is_host_or_solo():
		return
	var asteroid := ASTEROID_SCENE.instantiate()
	asteroid.setup(
		Constants.AsteroidSize.LARGE,
		Vector2(
			randf_range(
				Constants.ASTEROID_SPAWN_MARGIN,
				Constants.VIEWPORT_WIDTH - Constants.ASTEROID_SPAWN_MARGIN
			),
			-Constants.ASTEROID_SPAWN_MARGIN
		)
	)
	asteroid.add_to_group(Constants.GROUP_ASTEROIDS)
	asteroid.destroyed.connect(_on_asteroid_destroyed)
	_entities.add_child(asteroid)


func _on_asteroid_destroyed(asteroid_position: Vector2, asteroid_size: Constants.AsteroidSize) -> void:
	var explosion := EXPLOSION_SCENE.instantiate()
	explosion.position = asteroid_position
	_entities.add_child(explosion)

	_trigger_shake()
	_spawn_children(asteroid_position, asteroid_size)

	if randf() < Constants.POWER_UP_DROP_CHANCE:
		_spawn_power_up(asteroid_position)


func _spawn_children(parent_position: Vector2, parent_size: Constants.AsteroidSize) -> void:
	var child_size: Constants.AsteroidSize
	match parent_size:
		Constants.AsteroidSize.LARGE:
			child_size = Constants.AsteroidSize.MEDIUM
		Constants.AsteroidSize.MEDIUM:
			child_size = Constants.AsteroidSize.SMALL
		Constants.AsteroidSize.SMALL:
			return

	for i in Constants.ASTEROID_CHILDREN_ON_BREAK:
		var offset := Vector2(randf_range(-30, 30), randf_range(-20, 20))
		var child := ASTEROID_SCENE.instantiate()
		child.setup(child_size, parent_position + offset)
		child.add_to_group(Constants.GROUP_ASTEROIDS)
		child.destroyed.connect(_on_asteroid_destroyed)
		_entities.add_child(child)


func _spawn_power_up(spawn_position: Vector2) -> void:
	var power_up := POWER_UP_SCENE.instantiate()
	var types := Constants.PowerUpType.values()
	var random_type: Constants.PowerUpType = types[randi() % types.size()]
	power_up.setup(random_type, spawn_position)
	power_up.add_to_group(Constants.GROUP_POWER_UPS)
	power_up.collected.connect(_on_power_up_collected)
	_entities.add_child(power_up)


func _on_power_up_collected(power_type: Constants.PowerUpType) -> void:
	# In multiplayer, the player who collects it gets it (handled by PowerUp collision)
	pass


func _on_boss_incoming() -> void:
	if not _is_host_or_solo():
		return
	var boss := BOSS_SCENE.instantiate()
	boss.position = Vector2(Constants.VIEWPORT_WIDTH / 2.0, -80.0)
	boss.destroyed.connect(_on_boss_destroyed)
	_entities.add_child(boss)


func _on_boss_destroyed(boss_position: Vector2) -> void:
	var explosion := EXPLOSION_SCENE.instantiate()
	explosion.position = boss_position
	_entities.add_child(explosion)
	_trigger_shake()


func _trigger_shake() -> void:
	_shake_amount = Constants.SHAKE_INTENSITY


func _on_difficulty_tick() -> void:
	var new_interval := _spawn_timer.wait_time - Constants.DIFFICULTY_SPAWN_DECREASE
	_spawn_timer.wait_time = maxf(new_interval, Constants.DIFFICULTY_MIN_SPAWN_INTERVAL)


func _update_high_score_display() -> void:
	var hs := GameManager.get_high_score()
	if hs > 0:
		_high_score_label.text = "HIGH SCORE: %d" % hs
	else:
		_high_score_label.text = ""


func _clear_entities() -> void:
	for child in _entities.get_children():
		child.queue_free()
	for child in _players_node.get_children():
		child.queue_free()
	_players.clear()


func _is_host_or_solo() -> bool:
	return GameManager.game_mode == Constants.GameMode.SOLO or multiplayer.is_server()
```

### Task 6.4: Update main.tscn for multiplayer nodes

**Files:**
- Modify: `scenes/main/main.tscn`

Key changes to the scene:
1. Remove the static Player instance (players are now spawned dynamically)
2. Add `Entities` Node2D container (for MultiplayerSpawner)
3. Add `Players` Node2D container
4. Add `MultiplayerSpawner` that watches the Entities node

The Player node `[node name="Player" parent="." instance=ExtResource("2_player")]` is removed. Instead, two new container nodes are added:

```
[node name="Players" type="Node2D" parent="."]

[node name="Entities" type="Node2D" parent="."]

[node name="MultiplayerSpawner" type="MultiplayerSpawner" parent="."]
spawn_path = NodePath("../Entities")
```

The `ext_resource` for player.tscn remains (used by preload in main.gd).

### Task 6.5: Update asteroid.gd collision to track which player's bullet

**Files:**
- Modify: `scenes/enemies/asteroid.gd`

The `_on_area_entered` function needs to know which player scored. Since bullets are spawned by the host on behalf of players, we add a `owner_peer_id` to bullets:

In `scenes/projectiles/bullet.gd`, add:
```gdscript
var owner_peer_id: int = 1
```

Then in `asteroid.gd` `_on_area_entered`:
```gdscript
func _on_area_entered(area: Area2D) -> void:
	if area is Bullet:
		var scorer_id: int = (area as Bullet).owner_peer_id
		area.queue_free()
		var score_value: int = Constants.ASTEROID_SIZE_SCORES[asteroid_size]
		GameManager.add_score(score_value, scorer_id)
		GameManager.register_kill()
		AudioManager.play_explosion()
		destroyed.emit(global_position, asteroid_size)
		queue_free()
	elif area is Player:
		(area as Player).take_damage()
		destroyed.emit(global_position, asteroid_size)
		queue_free()
```

### Task 6.6: Update boss.gd collision for multiplayer scoring

**Files:**
- Modify: `scenes/enemies/boss.gd`

```gdscript
func _on_area_entered(area: Area2D) -> void:
	if area is Bullet:
		var scorer_id: int = (area as Bullet).owner_peer_id
		area.queue_free()
		take_hit(scorer_id)
	elif area is Player:
		(area as Player).take_damage()


func take_hit(scorer_id: int = 1) -> void:
	_health -= 1
	_health_bar.value = _health
	health_changed.emit(_health, _max_health)

	modulate = Color(1.0, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

	if _health <= 0:
		GameManager.add_score(Constants.BOSS_SCORE_VALUE, scorer_id)
		GameManager.register_kill()
		destroyed.emit(global_position)
		queue_free()
```

### Task 6.7: Update power_up.gd for multiplayer collection

**Files:**
- Modify: `scenes/items/power_up.gd`

When a player collects a power-up in multiplayer, apply it directly:

```gdscript
func _on_area_entered(area: Area2D) -> void:
	if area is Player:
		(area as Player).apply_power_up(power_type)
		AudioManager.play_powerup()
		queue_free()
```

Remove the `collected` signal usage — apply directly via the Player reference instead.

### Task 6.8: Commit and push Milestone 6

```bash
git add -A
git commit -m "feat: add multiplayer player spawning and entity replication

Authority-based player input, MultiplayerSynchronizer for position sync,
dynamic player spawning, per-player bullet ownership for score tracking,
host-only entity spawning, Entities/Players container nodes.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push
```

---

## Milestone 7: Multiplayer HUD, Game Over & Victory Screen

### Task 7.1: Refactor HUD for multiplayer

**Files:**
- Modify: `scenes/ui/hud.gd`
- Modify: `scenes/ui/hud.tscn`

**Step 1: Update hud.gd**

```gdscript
extends CanvasLayer
## In-game HUD. Shows score/lives per player, adapts to game mode.

@onready var _p1_score_label: Label = $MarginContainer/HBoxContainer/P1Score
@onready var _p1_lives_label: Label = $MarginContainer/HBoxContainer/P1Lives
@onready var _p2_score_label: Label = $MarginContainer/HBoxContainer/P2Score
@onready var _p2_lives_label: Label = $MarginContainer/HBoxContainer/P2Lives


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)

	if GameManager.game_mode == Constants.GameMode.SOLO:
		_p2_score_label.visible = false
		_p2_lives_label.visible = false
		_update_solo_display()
	elif GameManager.game_mode == Constants.GameMode.COOP:
		_p2_score_label.visible = false
		_p2_lives_label.visible = false
		_update_coop_display()
	else:
		_p2_score_label.visible = true
		_p2_lives_label.visible = true
		_update_competitive_display()


func _update_solo_display() -> void:
	_p1_score_label.text = "SCORE: %d" % GameManager.get_score(1)
	_p1_lives_label.text = "LIVES: %d" % GameManager.get_lives(1)


func _update_coop_display() -> void:
	_p1_score_label.text = "TEAM SCORE: %d" % GameManager.get_score(1)
	_p1_lives_label.text = "TEAM LIVES: %d" % GameManager.get_lives(1)


func _update_competitive_display() -> void:
	_p1_score_label.text = "P1: %d" % GameManager.get_score(1)
	_p1_lives_label.text = "P1 LIVES: %d" % GameManager.get_lives(1)
	var p2_ids := NetworkManager.player_ids.filter(func(id): return id != 1)
	if p2_ids.size() > 0:
		var p2_id: int = p2_ids[0]
		_p2_score_label.text = "P2: %d" % GameManager.get_score(p2_id)
		_p2_lives_label.text = "P2 LIVES: %d" % GameManager.get_lives(p2_id)


func _on_score_changed(_new_score: int, _peer_id: int) -> void:
	match GameManager.game_mode:
		Constants.GameMode.SOLO:
			_update_solo_display()
		Constants.GameMode.COOP:
			_update_coop_display()
		Constants.GameMode.COMPETITIVE:
			_update_competitive_display()


func _on_lives_changed(_new_lives: int, _peer_id: int) -> void:
	match GameManager.game_mode:
		Constants.GameMode.SOLO:
			_update_solo_display()
		Constants.GameMode.COOP:
			_update_coop_display()
		Constants.GameMode.COMPETITIVE:
			_update_competitive_display()
```

**Step 2: Update hud.tscn**

Replace the HBoxContainer children with 4 labels:

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scenes/ui/hud.gd" id="1_hud"]
[ext_resource type="FontFile" path="res://assets/fonts/kenvector_future.ttf" id="2_font"]

[sub_resource type="LabelSettings" id="LabelSettings_hud"]
font = ExtResource("2_font")
font_size = 22
font_color = Color(1, 1, 1, 1)

[node name="HUD" type="CanvasLayer"]
script = ExtResource("1_hud")

[node name="MarginContainer" type="MarginContainer" parent="."]
anchors_preset = 10
anchor_right = 1.0
offset_bottom = 50.0
theme_override_constants/margin_left = 20
theme_override_constants/margin_top = 15
theme_override_constants/margin_right = 20

[node name="HBoxContainer" type="HBoxContainer" parent="MarginContainer"]
layout_mode = 2

[node name="P1Score" type="Label" parent="MarginContainer/HBoxContainer"]
layout_mode = 2
size_flags_horizontal = 3
text = "SCORE: 0"
label_settings = SubResource("LabelSettings_hud")

[node name="P1Lives" type="Label" parent="MarginContainer/HBoxContainer"]
layout_mode = 2
size_flags_horizontal = 3
text = "LIVES: 3"
label_settings = SubResource("LabelSettings_hud")

[node name="P2Score" type="Label" parent="MarginContainer/HBoxContainer"]
layout_mode = 2
size_flags_horizontal = 3
horizontal_alignment = 2
text = "P2: 0"
label_settings = SubResource("LabelSettings_hud")

[node name="P2Lives" type="Label" parent="MarginContainer/HBoxContainer"]
layout_mode = 2
horizontal_alignment = 2
text = "P2 LIVES: 3"
label_settings = SubResource("LabelSettings_hud")
```

### Task 7.2: Update game_over_screen.gd for multiplayer

**Files:**
- Modify: `scenes/ui/game_over_screen.gd`

```gdscript
extends CanvasLayer
## Game over overlay. Mode-aware: shows combined or individual scores.

@onready var _final_score_label: Label = $PanelContainer/VBoxContainer/FinalScoreLabel
@onready var _high_score_label: Label = $PanelContainer/VBoxContainer/HighScoreLabel
@onready var _restart_button: Button = $PanelContainer/VBoxContainer/RestartButton


func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.game_started.connect(_on_game_started)
	_restart_button.pressed.connect(_on_restart_pressed)
	visible = false


func _on_game_over() -> void:
	match GameManager.game_mode:
		Constants.GameMode.SOLO:
			_final_score_label.text = "FINAL SCORE: %d" % GameManager.get_score(1)
		Constants.GameMode.COOP:
			_final_score_label.text = "TEAM SCORE: %d" % GameManager.get_score(1)
		Constants.GameMode.COMPETITIVE:
			var winner_id := GameManager.get_winner_id()
			var winner_label := "P1" if winner_id == 1 else "P2"
			_final_score_label.text = "%s WINS! (%d pts)" % [winner_label, GameManager.get_score(winner_id)]
	_high_score_label.text = "HIGH SCORE: %d" % GameManager.get_high_score()
	visible = true


func _on_game_started() -> void:
	visible = false


func _on_restart_pressed() -> void:
	GameManager.reset()
	if GameManager.game_mode == Constants.GameMode.SOLO:
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn")
```

### Task 7.3: Update pause_menu.gd for multiplayer quit

**Files:**
- Modify: `scenes/ui/pause_menu.gd`

```gdscript
extends CanvasLayer
## Pause overlay. Toggled with ESC key.

@onready var _resume_button: Button = $PanelContainer/VBoxContainer/ResumeButton
@onready var _quit_button: Button = $PanelContainer/VBoxContainer/QuitButton


func _ready() -> void:
	_resume_button.pressed.connect(_on_resume_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and GameManager.is_playing:
		_toggle_pause()


func _toggle_pause() -> void:
	var is_paused := not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused


func _on_resume_pressed() -> void:
	_toggle_pause()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	GameManager.reset()
	NetworkManager.disconnect_game()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
```

### Task 7.4: Commit and push Milestone 7

```bash
git add -A
git commit -m "feat: multiplayer HUD, game over, and pause menu

Mode-aware HUD shows team/individual scores. Game over screen
shows winner in competitive. Pause quit returns to main menu
and disconnects network.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push
```

---

## Milestone 8: Polish & Disconnect Handling

### Task 8.1: Handle player disconnection in main.gd

**Files:**
- Modify: `scenes/main/main.gd`

Add to `_ready()`:
```gdscript
NetworkManager.player_disconnected.connect(_on_peer_disconnected)
NetworkManager.server_disconnected.connect(_on_server_lost)
```

Add functions:
```gdscript
func _on_peer_disconnected(peer_id: int) -> void:
	if peer_id in _players:
		_players[peer_id].queue_free()
		_players.erase(peer_id)
	# If only one player remains in multiplayer, end the game
	if GameManager.game_mode != Constants.GameMode.SOLO and _players.size() <= 1:
		GameManager._end_game()


func _on_server_lost() -> void:
	get_tree().paused = false
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
```

### Task 8.2: Update CLAUDE-PRODUCT.md and CLAUDE-ARCHITECTURE.md

**Files:**
- Modify: `CLAUDE-PRODUCT.md` — Add multiplayer features
- Modify: `CLAUDE-ARCHITECTURE.md` — Add NetworkManager, multiplayer data flow

### Task 8.3: Update README.md with multiplayer instructions

**Files:**
- Modify: `README.md` — Add multiplayer section, controls for 2 players, LAN/online setup

### Task 8.4: Final commit and push Milestone 8

```bash
git add -A
git commit -m "feat: disconnect handling, docs update, multiplayer polish

Handle peer disconnect gracefully, return to menu on server loss.
Update product/architecture docs and README with multiplayer info.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push
```
