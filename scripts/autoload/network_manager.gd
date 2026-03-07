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
