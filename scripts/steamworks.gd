extends Node

func _ready() -> void:
	print(1)
	OS.set_environment("SteamAppID", "480")
	OS.set_environment("SteamGameID", "480")

	Steam.steamInitEx()

func _process(_delta: float) -> void:
	Steam.run_callbacks()
