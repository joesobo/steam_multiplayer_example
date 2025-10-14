extends Node

const LOADING_SCENE = preload("res://scenes/loading.tscn")
const GAME_SCENE = preload("res://scenes/game.tscn")

var loading_instance
var scene_to_load = GAME_SCENE

func _ready() -> void:
	call_deferred("start_loading_sequence")

func _process(_delta: float) -> void:
	var status = ResourceLoader.load_threaded_get_status(scene_to_load)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# TODO: for progress bar
			pass
		ResourceLoader.THREAD_LOAD_LOADED:
			var loaded_scene = ResourceLoader.load_threaded_get(scene_to_load)
			var scene_instance = loaded_scene.instantiate()
			add_child(scene_instance)

			if loading_instance:
				loading_instance.queue_free()

			set_process(false)
		ResourceLoader.THREAD_LOAD_FAILED:
			print("Failed to load scene")
			set_process(false)

func start_loading_sequence() -> void:
	loading_instance = LOADING_SCENE.instantiate()
	add_child(loading_instance)
	ResourceLoader.load_threaded_request(scene_to_load)
