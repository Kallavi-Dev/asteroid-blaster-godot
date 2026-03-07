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
