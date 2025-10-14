extends Panel

@export var players_list: VBoxContainer
@export var ready_button: Button
@export var leave_button: Button
@export var peer_count_label: Label
@export var peer_id_label: Label
@export var steam_id_label: Label
@export var lobby_id_label: Label
@export var role_label: Label

var _players_ready: Dictionary = {} # peer_id -> bool
var _player_names: Dictionary = {} # peer_id -> String
var _main: Node

func _ready() -> void:
	ready_button.pressed.connect(_on_ready_pressed)
	leave_button.pressed.connect(_on_leave_pressed)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	visibility_changed.connect(_on_visibility_changed)

	_main = get_tree().root.get_node_or_null("Main")

func _on_visibility_changed() -> void:
	if visible:
		_setup_footer()
		_add_player(multiplayer.get_unique_id())

		# Add all existing peers
		for peer_id in multiplayer.get_peers():
			_add_player(peer_id)

		# Broadcast our name to all peers
		_rpc_register_player.rpc(multiplayer.get_unique_id(), Steam.getPersonaName())

func _setup_footer() -> void:
	var peer_count = multiplayer.get_peers().size() + 1

	peer_count_label.text = "Peers: " + str(peer_count)
	peer_id_label.text = "Peer ID: " + str(multiplayer.get_unique_id())
	steam_id_label.text = "Steam ID: " + str(Steam.getSteamID())
	lobby_id_label.text = "Lobby ID: " + str(_main.lobby_id)
	role_label.text = "Role: " + ("Host" if multiplayer.is_server() else "Client")

func _on_peer_connected(peer_id: int) -> void:
	_add_player(peer_id)
	_setup_footer()

	# Send our name to the new peer
	_rpc_register_player.rpc_id(peer_id, multiplayer.get_unique_id(), Steam.getPersonaName())

func _on_peer_disconnected(peer_id: int) -> void:
	_remove_player(peer_id)
	_setup_footer()

func _add_player(peer_id: int) -> void:
	if _players_ready.has(peer_id):
		return

	_players_ready[peer_id] = false
	_update_player_list()

func _remove_player(peer_id: int) -> void:
	_players_ready.erase(peer_id)
	_player_names.erase(peer_id)
	_update_player_list()

func _update_player_list() -> void:
	for child in players_list.get_children():
		child.queue_free()

	for peer_id in _players_ready.keys():
		var container = HBoxContainer.new()

		var name_label = Label.new()
		name_label.text = _get_player_name(peer_id)
		name_label.custom_minimum_size = Vector2(200, 0)
		container.add_child(name_label)

		var status_label = Label.new()
		status_label.text = "✓ Ready" if _players_ready[peer_id] else "⏳ Not Ready"
		status_label.custom_minimum_size = Vector2(100, 0)
		container.add_child(status_label)

		players_list.add_child(container)

func _get_player_name(peer_id: int) -> String:
	if _player_names.has(peer_id):
		return _player_names[peer_id]
	return "Player " + str(peer_id)

func _on_ready_pressed() -> void:
	var my_id = multiplayer.get_unique_id()
	_players_ready[my_id] = not _players_ready[my_id]

	_rpc_set_ready.rpc(my_id, _players_ready[my_id])
	ready_button.text = "Unready" if _players_ready[my_id] else "Ready"
	_update_player_list()

	if multiplayer.is_server():
		_check_all_ready()

func _on_leave_pressed() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	_players_ready.clear()
	_player_names.clear()
	_update_player_list()

	if _main:
		_main.toggle_ui(false)

@rpc("any_peer", "call_local")
func _rpc_register_player(peer_id: int, player_name: String) -> void:
	_player_names[peer_id] = player_name
	_update_player_list()

@rpc("any_peer", "call_local")
func _rpc_set_ready(peer_id: int, is_ready: bool) -> void:
	_players_ready[peer_id] = is_ready
	_update_player_list()

	if multiplayer.is_server():
		_check_all_ready()

@rpc("authority", "call_local")
func _rpc_start_game() -> void:
	if _main:
		_main.start_game()

func _check_all_ready() -> void:
	if _players_ready.is_empty():
		return

	for is_ready in _players_ready.values():
		if not is_ready:
			return

	# All players ready, start the game
	_rpc_start_game.rpc()
