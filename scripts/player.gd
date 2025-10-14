extends CharacterBody2D

const SPEED: float = 300.0

func _enter_tree() -> void:
	var camera = get_node("Camera2D")
	camera.enabled = false

	if is_multiplayer_authority():
		camera.enabled = true

func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority():
		return

	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * SPEED

	move_and_slide()
