extends Node

func _ready() -> void:
	OS.set_environment("SteamAppID", "480")
	OS.set_environment("SteamGameID", "480")

	Steam.steamInitEx()

	Steam.allowP2PPacketRelay(true)

func _process(_delta: float) -> void:
	Steam.run_callbacks()
