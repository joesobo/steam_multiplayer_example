extends Node

func _ready() -> void:
	OS.set_environment("SteamAppID", "3569650")
	OS.set_environment("SteamGameID", "3569650")

	Steam.steamInitEx()

	Steam.allowP2PPacketRelay(true)

	Steam.network_messages_session_request.connect(_on_network_messages_session_request)
	Steam.network_messages_session_failed.connect(_on_network_messages_session_failed)

func _process(_delta: float) -> void:
	Steam.run_callbacks()

# Accept incoming Network Messages session requests
func _on_network_messages_session_request(remote_steam_id: int) -> void:
	print("Network Messages session request from: ", remote_steam_id)
	Steam.acceptSessionWithUser(remote_steam_id)

# Log session failures for debugging
func _on_network_messages_session_failed(_reason: int, _remote_steam_id: int, _connection_state: int, debug_message: String) -> void:
	print("Network Messages session failed with: ", debug_message)
