class_name WorldPlayerController
extends RefCounted

const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")
const WorldConstantsClass = preload("res://systems/world/world_constants.gd")

var run_hold_time: float = 0.0
var last_run_direction: int = 0


func update(delta: float, state: Dictionary, context: Dictionary) -> bool:
	if is_player_inside_gravity_field(state.position, context.gravity_field_system, context.get_world_size_from_cells):
		return _update_player_in_gravity_field(delta, state, context)

	var previous_position: Vector2 = state.position
	var input_axis: float = Input.get_axis("move_left", "move_right")
	var is_on_floor: bool = _is_player_on_floor(state.position, context.collides_at)
	var move_direction: int = int(signf(input_axis))
	var speed_multiplier: float = _update_run_speed_multiplier(delta, move_direction, is_on_floor)
	var horizontal_speed: float = input_axis * GameplayTuningClass.PLAYER_MOVE_SPEED * speed_multiplier

	state.velocity.y += GameplayTuningClass.PLAYER_GRAVITY * delta

	if Input.is_action_just_pressed("move_up") and is_on_floor:
		state.velocity.y = GameplayTuningClass.PLAYER_JUMP_VELOCITY

	if is_on_floor:
		state.velocity.x = 0.0
		var max_step_up_cells: int = GameplayTuningClass.PLAYER_STEP_UP_BASE_CELLS
		if speed_multiplier >= GameplayTuningClass.PLAYER_FAST_STEP_THRESHOLD:
			max_step_up_cells = GameplayTuningClass.PLAYER_STEP_UP_FAST_CELLS
		_move_player_grounded(state, context, horizontal_speed * delta, max_step_up_cells * WorldConstantsClass.CELL_SIZE.y)
		if state.velocity.y > 0.0:
			state.velocity.y = 0.0
	else:
		state.velocity.x = horizontal_speed

	if is_on_floor:
		_move_player(state, context, Vector2(0.0, state.velocity.y * delta))
	else:
		_move_player(state, context, Vector2(state.velocity.x * delta, state.velocity.y * delta))

	if _is_player_on_floor(state.position, context.collides_at):
		state.velocity.y = minf(state.velocity.y, 0.0)

	return state.position != previous_position


func snap_player_to_ground(state: Dictionary, collides_at: Callable) -> void:
	var guard_limit: int = 4096
	var guard_steps: int = 0

	while not _is_player_on_floor(state.position, collides_at) and guard_steps < guard_limit:
		state.position += Vector2.DOWN
		guard_steps += 1

	guard_steps = 0
	while collides_at.call(state.position) and guard_steps < guard_limit:
		state.position += Vector2.UP
		guard_steps += 1


func get_player_center_world(player_world_position: Vector2, get_world_size_from_cells: Callable) -> Vector2:
	return player_world_position + (get_world_size_from_cells.call(GameplayTuningClass.PLAYER_SIZE_CELLS) * 0.5)


func get_player_world_rect(player_world_position: Vector2, get_world_size_from_cells: Callable) -> Rect2:
	return Rect2(player_world_position, get_world_size_from_cells.call(GameplayTuningClass.PLAYER_SIZE_CELLS))


func get_player_ground_world(player_world_position: Vector2, get_world_size_from_cells: Callable) -> Vector2:
	var player_size: Vector2 = get_world_size_from_cells.call(GameplayTuningClass.PLAYER_SIZE_CELLS)
	return player_world_position + Vector2(player_size.x * 0.5, player_size.y)


func is_player_inside_gravity_field(
	player_world_position: Vector2,
	gravity_field_system,
	get_world_size_from_cells: Callable
) -> bool:
	return gravity_field_system.find_active_field_intersecting(get_player_world_rect(player_world_position, get_world_size_from_cells)) != null


func get_gravity_acceleration_at_player(
	player_world_position: Vector2,
	gravity_field_system,
	get_world_size_from_cells: Callable
) -> Vector2:
	return gravity_field_system.get_gravity_acceleration(
		get_player_center_world(player_world_position, get_world_size_from_cells),
		GameplayTuningClass.PLAYER_GRAVITY
	)


func _update_player_in_gravity_field(delta: float, state: Dictionary, context: Dictionary) -> bool:
	var previous_position: Vector2 = state.position
	var input_axis: float = Input.get_axis("move_left", "move_right")
	var gravity_acceleration: Vector2 = get_gravity_acceleration_at_player(
		state.position,
		context.gravity_field_system,
		context.get_world_size_from_cells
	)

	state.velocity += gravity_acceleration * delta
	state.velocity.x += input_axis * GameplayTuningClass.PLAYER_MOVE_SPEED * delta * 2.0

	if Input.is_action_just_pressed("move_up") and gravity_acceleration != Vector2.ZERO:
		state.velocity += -gravity_acceleration.normalized() * absf(GameplayTuningClass.PLAYER_JUMP_VELOCITY)

	var intended_motion: Vector2 = state.velocity * delta
	_move_player(state, context, intended_motion)

	if is_equal_approx(state.position.x, previous_position.x) and not is_zero_approx(intended_motion.x):
		state.velocity.x = 0.0
	if is_equal_approx(state.position.y, previous_position.y) and not is_zero_approx(intended_motion.y):
		state.velocity.y = 0.0

	return state.position != previous_position


func _move_player_grounded(state: Dictionary, context: Dictionary, surface_distance: float, max_step_up_pixels: int) -> void:
	if is_zero_approx(surface_distance):
		return

	var remaining_distance: float = surface_distance
	var step_sign: float = signf(surface_distance)
	var guard_steps: int = 0
	var guard_limit: int = 4096

	while absf(remaining_distance) > 0.0 and guard_steps < guard_limit:
		var step_distance: float = minf(absf(remaining_distance), 1.0)
		var next_position: Vector2 = context.clamp_player_to_room.call(state.position + Vector2(step_sign * step_distance, 0.0))
		var resolved_position: Vector2 = _resolve_grounded_step_position(state.position, next_position, max_step_up_pixels, context.collides_at)
		if resolved_position == state.position:
			break

		state.position = resolved_position
		_settle_player_to_floor(state, context.collides_at, WorldConstantsClass.CELL_SIZE.y + 2)
		remaining_distance -= step_distance * step_sign
		guard_steps += 1


func _resolve_grounded_step_position(
	current_position: Vector2,
	next_position: Vector2,
	max_step_up_pixels: int,
	collides_at: Callable
) -> Vector2:
	if not collides_at.call(next_position):
		return next_position

	for outward_steps in range(1, maxi(max_step_up_pixels, 1) + 1):
		var adjusted_position: Vector2 = next_position + Vector2(0.0, -float(outward_steps))
		if not collides_at.call(adjusted_position):
			return adjusted_position

	return current_position


func _settle_player_to_floor(state: Dictionary, collides_at: Callable, max_steps: int) -> void:
	for _step_index in range(max_steps):
		if _is_player_on_floor(state.position, collides_at):
			return

		var next_position: Vector2 = state.position + Vector2.DOWN
		if collides_at.call(next_position):
			return

		state.position = next_position


func _move_player(state: Dictionary, context: Dictionary, motion: Vector2) -> void:
	_move_player_axis(state, context, Vector2(motion.x, 0.0), true)
	_move_player_axis(state, context, Vector2(0.0, motion.y), false)


func _move_player_axis(state: Dictionary, context: Dictionary, axis_motion: Vector2, allow_step_assist: bool) -> void:
	if axis_motion == Vector2.ZERO:
		return

	var remaining_distance: float = axis_motion.length()
	var direction: Vector2 = axis_motion.normalized()

	while remaining_distance > 0.0:
		var step_distance: float = minf(remaining_distance, 1.0)
		var step_motion: Vector2 = direction * step_distance
		var next_position: Vector2 = context.clamp_player_to_room.call(state.position + step_motion)

		if context.collides_at.call(next_position):
			if allow_step_assist and absf(step_motion.x) > 0.0:
				var assisted_position: Vector2 = _get_wall_step_assisted_position(state.position, next_position, context)
				if assisted_position != state.position:
					state.position = assisted_position
					remaining_distance -= step_distance
					continue
			return

		state.position = next_position
		remaining_distance -= step_distance


func _get_wall_step_assisted_position(current_position: Vector2, next_position: Vector2, context: Dictionary) -> Vector2:
	for step_pixels in range(1, GameplayTuningClass.PLAYER_WALL_STEP_ASSIST_PIXELS + 1):
		var adjusted_position: Vector2 = context.clamp_player_to_room.call(next_position + Vector2(0.0, -float(step_pixels)))
		if not context.collides_at.call(adjusted_position):
			return adjusted_position

	return current_position


func _is_player_on_floor(player_world_position: Vector2, collides_at: Callable) -> bool:
	return collides_at.call(player_world_position + Vector2.DOWN)


func _update_run_speed_multiplier(delta: float, move_direction: int, is_on_floor: bool) -> float:
	if not is_on_floor or move_direction == 0:
		run_hold_time = 0.0
		last_run_direction = move_direction
		return 1.0

	if move_direction != last_run_direction:
		run_hold_time = 0.0

	run_hold_time = minf(run_hold_time + delta, GameplayTuningClass.PLAYER_RUN_BOOST_TIME)
	last_run_direction = move_direction

	var boost_t: float = 1.0
	if GameplayTuningClass.PLAYER_RUN_BOOST_TIME > 0.0:
		boost_t = clampf(run_hold_time / GameplayTuningClass.PLAYER_RUN_BOOST_TIME, 0.0, 1.0)

	return lerpf(1.0, GameplayTuningClass.PLAYER_RUN_BOOST_MULTIPLIER, boost_t)
