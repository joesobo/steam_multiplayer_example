extends Node

func _ready() -> void:
	OS.set_environment("SteamAppID", "3569650")
	OS.set_environment("SteamGameID", "3569650")

	Steam.steamInitEx()

	Steam.allowP2PPacketRelay(true)

	Steam.p2p_session_request.connect(_on_p2p_session_request)

func _process(_delta: float) -> void:
	Steam.run_callbacks()

func _on_p2p_session_request(remote_id: int) -> void:
	print("P2P session request from: ", remote_id)
	Steam.acceptP2PSessionWithUser(remote_id)
