extends MultiplayerSpawner

var in_game_players: Dictionary[int, Node] = {}

@export var player_scene: PackedScene

func _ready() -> void:
	spawn_function = _spawn_player

	if is_multiplayer_authority():
		spawn(1)

		for peer_id in multiplayer.get_peers():
			spawn(peer_id)

		multiplayer.peer_disconnected.connect(_remove_player)

func _spawn_player(id: int) -> Node:
	var player = player_scene.instantiate()
	player.set_multiplayer_authority(id)
	player.position = Vector2(randi() % 101, randi() % 101)
	in_game_players[id] = player
	return player

func _remove_player(id: int) -> void:
	in_game_players[id].queue_free()
	in_game_players.erase(id)
