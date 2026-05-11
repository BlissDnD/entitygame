class_name AtlasWorker
extends NpcBase

signal group_activation_requested

@export var activation_radius: float = 120.0
@export var follow_distance: float = 28.0
@export var stop_distance: float = 12.0
@export var max_speed: float = 220.0
@export var acceleration: float = 900.0
@export var deceleration: float = 1200.0

var group_index: int = 0
var follow_target: Node2D = null
var activation_target: Node2D = null
var is_group_activated: bool = false
var personal_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	if personal_offset == Vector2.ZERO:
		personal_offset = _get_group_offset(group_index)


func configure_worker(next_group_index: int, next_activation_target: Node2D, next_follow_target: Node2D) -> void:
	group_index = next_group_index
	activation_target = next_activation_target
	follow_target = next_follow_target
	follow_distance = 28.0 + (float(group_index) * 10.0)
	stop_distance = 10.0 + (float(group_index) * 3.0)
	personal_offset = _get_group_offset(group_index)


func activate_group() -> void:
	is_group_activated = true


func deactivate_group() -> void:
	is_group_activated = false
	follow_target = null
	velocity = Vector2.ZERO


func _process(delta: float) -> void:
	_update_activation()

	if not is_group_activated:
		_update_idle_motion(delta)
		return

	_update_follow_motion(delta)


func _update_activation() -> void:
	if is_group_activated:
		return
	if group_index != 0:
		return
	if activation_target == null:
		return
	if global_position.distance_to(activation_target.global_position) > activation_radius:
		return

	group_activation_requested.emit()


func _update_idle_motion(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	global_position += velocity * delta


func _update_follow_motion(delta: float) -> void:
	if follow_target == null:
		return

	var target_position: Vector2 = _get_ground_target_position()
	var target_vector: Vector2 = target_position - global_position
	var distance_to_target: float = target_vector.length()
	var desired_velocity: Vector2 = Vector2.ZERO

	if distance_to_target > follow_distance:
		desired_velocity = target_vector.normalized() * max_speed
	elif distance_to_target < stop_distance and distance_to_target > 0.001:
		desired_velocity = -target_vector.normalized() * (max_speed * 0.35)

	var speed_change: float = acceleration
	if desired_velocity == Vector2.ZERO:
		speed_change = deceleration
	velocity = velocity.move_toward(desired_velocity, speed_change * delta)
	global_position += velocity * delta


func _get_ground_target_position() -> Vector2:
	var target_position: Vector2 = follow_target.global_position + personal_offset
	target_position.y = follow_target.global_position.y
	return target_position


func _get_group_offset(index: int) -> Vector2:
	var side_offset: float = -10.0
	if index % 2 == 1:
		side_offset = 10.0
	return Vector2(side_offset, 0.0)
