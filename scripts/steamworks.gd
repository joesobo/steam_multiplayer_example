extends Node

func _ready() -> void:
	OS.set_environment("SteamAppID", "3569650")
	OS.set_environment("SteamGameID", "3569650")

	Steam.steamInitEx()

	Steam.allowP2PPacketRelay(true)

func _process(_delta: float) -> void:
	Steam.run_callbacks()
