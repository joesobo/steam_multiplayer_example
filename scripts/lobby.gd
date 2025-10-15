extends Panel

signal player_list_updated

@export var players_list: VBoxContainer
@export var ready_button: Button
@export var leave_button: Button
@export var peer_count_label: Label
@export var peer_id_label: Label
@export var steam_id_label: Label
@export var lobby_id_label: Label
@export var role_label: Label

var _player_names: Dictionary = {} # peer_id -> String
var _player_ready: Dictionary = {} # peer_id -> bool
var _main: Node

func _ready() -> void:
	ready_button.pressed.connect(_on_ready_pressed)
	leave_button.pressed.connect(_on_leave_pressed)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	visibility_changed.connect(try_register_player)

	_main = get_tree().root.get_node_or_null("Main")

func try_register_player() -> void:
	if visible:
		_setup_footer()

		if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			# Register ourselves
			var my_id = multiplayer.get_unique_id()
			_player_names[my_id] = Steam.getPersonaName()
			_player_ready[my_id] = false

			# Broadcast our info to everyone
			_rpc_register_player.rpc(my_id, Steam.getPersonaName(), false)

			if !multiplayer.is_server():
				ready_button.disabled = true
				ready_button.text = "Syncing..."
				await player_list_updated
				ready_button.disabled = false
				ready_button.text = "Ready"
			else:
				ready_button.text = "Ready"
				_update_player_list()


func _setup_footer() -> void:
	var peer_count = multiplayer.get_peers().size() + 1

	peer_count_label.text = "Peers: " + str(peer_count)
	peer_id_label.text = "Peer ID: " + str(multiplayer.get_unique_id())
	steam_id_label.text = "Steam ID: " + str(Steam.getSteamID())
	lobby_id_label.text = "Lobby ID: " + str(_main.lobby_id)
	role_label.text = "Role: " + ("Host" if multiplayer.is_server() else "Client")

func _on_peer_connected(peer_id: int) -> void:
	_setup_footer()

	# Send our info to the new peer
	var my_id = multiplayer.get_unique_id()
	_rpc_register_player.rpc_id(peer_id, my_id, _player_names.get(my_id, "Unknown"), _player_ready.get(my_id, false))

func _on_peer_disconnected(peer_id: int) -> void:
	_player_names.erase(peer_id)
	_player_ready.erase(peer_id)
	_setup_footer()
	_update_player_list()

func _update_player_list() -> void:
	for child in players_list.get_children():
		child.queue_free()

	for peer_id in _player_names.keys():
		var container = HBoxContainer.new()

		var name_label = Label.new()
		name_label.text = _player_names.get(peer_id, "Player " + str(peer_id))
		name_label.custom_minimum_size = Vector2(200, 0)
		container.add_child(name_label)

		var status_label = Label.new()
		var is_ready = _player_ready.get(peer_id, false)
		status_label.text = "✓ Ready" if is_ready else "⏳ Not Ready"
		status_label.custom_minimum_size = Vector2(100, 0)
		container.add_child(status_label)

		players_list.add_child(container)

	player_list_updated.emit()

func _on_ready_pressed() -> void:
	var my_id = multiplayer.get_unique_id()
	var new_state = not _player_ready.get(my_id, false)

	_player_ready[my_id] = new_state
	ready_button.text = "Unready" if new_state else "Ready"

	# Broadcast ready state to all peers
	_rpc_set_ready.rpc(my_id, new_state)
	_update_player_list()

func _on_leave_pressed() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	_player_names.clear()
	_player_ready.clear()
	_update_player_list()

	if _main:
		_main.toggle_ui(false)

@rpc("any_peer", "call_local", "reliable")
func _rpc_register_player(peer_id: int, player_name: String, is_ready: bool) -> void:
	_player_names[peer_id] = player_name
	_player_ready[peer_id] = is_ready
	_update_player_list()

@rpc("any_peer", "call_local", "reliable")
func _rpc_set_ready(peer_id: int, is_ready: bool) -> void:
	_player_ready[peer_id] = is_ready
	_update_player_list()

	if multiplayer.is_server():
		_check_all_ready()

@rpc("authority", "call_local")
func _rpc_start_game() -> void:
	if _main:
		hide()
		_main.start_game()

func _check_all_ready() -> void:
	if _player_names.is_empty():
		return

	for peer_id in _player_names.keys():
		if not _player_ready.get(peer_id, false):
			return

	# All players ready, start the game
	print("All players ready! Starting game...")
	_rpc_start_game.rpc()
