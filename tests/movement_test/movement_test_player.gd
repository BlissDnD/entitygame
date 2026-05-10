extends CharacterBody2D

@export var speed: float = 220.0
@export var jump_velocity: float = -360.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("move_up") and is_on_floor():
		velocity.y = jump_velocity

	var input_direction := Input.get_axis("move_left", "move_right")
	velocity.x = input_direction * speed
	move_and_slide()
