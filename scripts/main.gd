extends Node

const LEVEL_SCENE = "res://scenes/level.tscn"

@export var host_button: Button
@export var refresh_button: Button
@export var lobbies_container: VBoxContainer

var _lobby_id: int = 0
var _peer := SteamMultiplayerPeer.new()

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

func _ready() -> void:
	spawner.spawn_function = _spawn_level

	host_button.pressed.connect(_on_host_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	_peer.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)

	_open_lobby_list()

func _on_host_pressed() -> void:
	_peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_PUBLIC)
	multiplayer.multiplayer_peer = _peer

	_hide_ui()

	call_deferred("_spawn_level_deferred")

func _on_lobby_created(connection: int, id: int) -> void:
	if connection:
		_lobby_id = id
		Steam.setLobbyData(_lobby_id, "name", str(Steam.getPersonaName()) + "'s Lobby")
		Steam.setLobbyJoinable(_lobby_id, true)

func _on_lobby_match_list(lobbies: Array) -> void:
	for lobby in lobbies:
		var lobby_name = Steam.getLobbyData(lobby, "name")
		var members_count = Steam.getNumLobbyMembers(lobby)

		var button = Button.new()
		button.set_text(str(lobby_name,"| Player Count: ", members_count))
		button.set_size(Vector2(100, 5))
		button.pressed.connect(_join_lobby.bind(lobby))
		lobbies_container.add_child(button)

func _on_refresh_pressed() -> void:
	for node in lobbies_container.get_children():
		node.queue_free()

	_open_lobby_list()

func _hide_ui() -> void:
	host_button.hide()
	refresh_button.hide()
	lobbies_container.hide()

func _join_lobby(id: int) -> void:
	_peer.connect_lobby(id)
	multiplayer.multiplayer_peer = _peer
	_lobby_id = id

	_hide_ui()

func _open_lobby_list() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

func _spawn_level(data: String) -> Node:
	return (load(data) as PackedScene).instantiate()

func _spawn_level_deferred() -> void:
	spawner.spawn(LEVEL_SCENE)
