extends Panel

@export var players_list: VBoxContainer
@export var ready_button: Button
@export var leave_button: Button
@export var peer_count_label: Label
@export var peer_id_label: Label
@export var steam_id_label: Label
@export var lobby_id_label: Label
@export var role_label: Label

var _players: Array[int] = [] # List of peer IDs in the lobby
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

		# Add ourselves
		_add_player(multiplayer.get_unique_id())

		# Add all existing peers
		for peer_id in multiplayer.get_peers():
			_add_player(peer_id)

		# Set our lobby member data (name and ready state)
		Steam.setLobbyMemberData(_main.lobby_id, "name", Steam.getPersonaName())
		Steam.setLobbyMemberData(_main.lobby_id, "ready", "false")
		ready_button.text = "Ready"

		# Notify everyone to update their lobby UI
		_rpc_update_lobby.rpc()

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

func _on_peer_disconnected(peer_id: int) -> void:
	_remove_player(peer_id)
	_setup_footer()

func _add_player(peer_id: int) -> void:
	if peer_id in _players:
		return

	_players.append(peer_id)
	_update_player_list()

func _remove_player(peer_id: int) -> void:
	_players.erase(peer_id)
	_update_player_list()

func _update_player_list() -> void:
	for child in players_list.get_children():
		child.queue_free()

	for peer_id in _players:
		var container = HBoxContainer.new()

		var name_label = Label.new()
		name_label.text = _get_player_name(peer_id)
		name_label.custom_minimum_size = Vector2(200, 0)
		container.add_child(name_label)

		var status_label = Label.new()
		var is_ready = _get_player_ready_state(peer_id)
		status_label.text = "✓ Ready" if is_ready else "⏳ Not Ready"
		status_label.custom_minimum_size = Vector2(100, 0)
		container.add_child(status_label)

		players_list.add_child(container)

func _get_player_name(peer_id: int) -> String:
	var steam_id: int
	if peer_id == multiplayer.get_unique_id():
		steam_id = Steam.getSteamID()
	else:
		steam_id = peer_id

	# Try to get the name from lobby member data
	if steam_id > 0 and _main and _main.lobby_id > 0:
		var player_name = Steam.getLobbyMemberData(_main.lobby_id, steam_id, "name")
		if player_name != "":
			return player_name

	return "Player " + str(peer_id)

func _get_player_ready_state(peer_id: int) -> bool:
	var steam_id: int
	if peer_id == multiplayer.get_unique_id():
		steam_id = Steam.getSteamID()
	else:
		steam_id = peer_id

	if steam_id > 0:
		var ready_str = Steam.getLobbyMemberData(_main.lobby_id, steam_id, "ready")
		return ready_str == "true"

	return false

func _on_ready_pressed() -> void:
	var new_state = !_get_player_ready_state(multiplayer.get_unique_id())

	Steam.setLobbyMemberData(_main.lobby_id, "ready", "true" if new_state else "false")
	ready_button.text = "Unready" if new_state else "Ready"

	_rpc_update_lobby.rpc()
	_update_player_list()

func _on_leave_pressed() -> void:
	# Clear our ready state
	if _main and _main.lobby_id > 0:
		Steam.setLobbyMemberData(_main.lobby_id, "ready", "false")

	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	_players.clear()
	_update_player_list()

	if _main:
		_main.toggle_ui(false)

@rpc("any_peer", "call_local")
func _rpc_update_lobby() -> void:
	_update_player_list()

	if multiplayer.is_server():
		_check_all_ready()

@rpc("authority", "call_local")
func _rpc_start_game() -> void:
	if _main:
		hide()
		_main.start_game()

func _check_all_ready() -> void:
	if _players.is_empty():
		return

	for peer_id in _players:
		if not _get_player_ready_state(peer_id):
			return

	# All players ready, start the game
	print("All players ready! Starting game...")
	_rpc_start_game.rpc()
