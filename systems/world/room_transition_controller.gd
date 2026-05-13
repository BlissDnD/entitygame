class_name RoomTransitionController
extends RefCounted


func should_transition_for_edge(room_edge: String, wants_left: bool, wants_right: bool, wants_up: bool, wants_down: bool) -> bool:
	match room_edge:
		"left":
			return wants_left
		"right":
			return wants_right
		"top":
			return wants_up
		"bottom":
			return wants_down
		_:
			return false


func get_room_transition_edge(
	room_rect: Rect2,
	player_rect: Rect2,
	margin_pixels: float,
	has_left_room: bool,
	has_right_room: bool,
	room_edge_none: String,
	room_edge_left: String,
	room_edge_right: String,
	room_edge_top: String,
	room_edge_bottom: String
) -> String:
	if player_rect.position.x <= room_rect.position.x + margin_pixels and has_left_room:
		return room_edge_left
	if player_rect.end.x >= room_rect.end.x - margin_pixels and has_right_room:
		return room_edge_right
	if player_rect.position.y <= room_rect.position.y + margin_pixels:
		return room_edge_top
	if player_rect.end.y >= room_rect.end.y - margin_pixels:
		return room_edge_bottom

	return room_edge_none


func get_void_fall_rect(room_rect: Rect2, void_margin: float, void_depth: float) -> Rect2:
	return Rect2(
		Vector2(room_rect.position.x - void_margin, room_rect.position.y),
		Vector2(room_rect.size.x + (void_margin * 2.0), room_rect.size.y + void_depth)
	)


func should_trigger_void_fall(
	room_rect: Rect2,
	player_rect: Rect2,
	void_margin: float,
	void_depth: float,
	is_outer_left_edge: bool,
	is_outer_right_edge: bool
) -> bool:
	var fell_left: bool = is_outer_left_edge and player_rect.end.x < room_rect.position.x - void_margin
	var fell_right: bool = is_outer_right_edge and player_rect.position.x > room_rect.end.x + void_margin
	var fell_below: bool = player_rect.position.y > room_rect.end.y + void_depth
	return fell_left or fell_right or fell_below


func get_room_entry_position(
	exit_edge: String,
	room_rect: Rect2,
	player_size: Vector2,
	entry_inset_pixels: float,
	current_position: Vector2
) -> Vector2:
	var next_position: Vector2 = current_position

	match exit_edge:
		"left":
			next_position.x = room_rect.end.x - player_size.x - entry_inset_pixels
		"right":
			next_position.x = room_rect.position.x + entry_inset_pixels
		"top":
			next_position.y = room_rect.end.y - player_size.y - entry_inset_pixels
		"bottom":
			next_position.y = room_rect.position.y + entry_inset_pixels

	return next_position


func clamp_player_to_room(
	next_position: Vector2,
	room_rect: Rect2,
	player_size: Vector2,
	is_outer_left_edge: bool,
	is_outer_right_edge: bool
) -> Vector2:
	var min_x: float = -INF
	var max_x: float = INF
	var max_y: float = room_rect.end.y - player_size.y
	if not is_outer_left_edge:
		min_x = room_rect.position.x
	if not is_outer_right_edge:
		max_x = room_rect.end.x - player_size.x
	if is_position_beyond_outer_horizontal_edge(next_position, room_rect, player_size, is_outer_left_edge, is_outer_right_edge):
		max_y = INF

	return Vector2(
		clampf(next_position.x, min_x, max_x),
		clampf(next_position.y, room_rect.position.y, max_y)
	)


func is_position_beyond_outer_horizontal_edge(
	position: Vector2,
	room_rect: Rect2,
	player_size: Vector2,
	is_outer_left_edge: bool,
	is_outer_right_edge: bool
) -> bool:
	if is_outer_left_edge and position.x + player_size.x < room_rect.position.x:
		return true
	if is_outer_right_edge and position.x > room_rect.end.x:
		return true

	return false


func build_room_entry_clear_rect(
	entry_position: Vector2,
	room_rect: Rect2,
	player_size: Vector2,
	side_padding: float,
	top_padding: float
) -> Rect2:
	var player_rect: Rect2 = Rect2(
		entry_position + Vector2(-side_padding, -top_padding),
		player_size + Vector2(side_padding * 2.0, top_padding)
	)
	var player_center: Vector2 = player_rect.get_center()
	var distance_left: float = absf(player_center.x - room_rect.position.x)
	var distance_right: float = absf(room_rect.end.x - player_center.x)
	var distance_top: float = absf(player_center.y - room_rect.position.y)
	var distance_bottom: float = absf(room_rect.end.y - player_center.y)
	var minimum_distance: float = minf(minf(distance_left, distance_right), minf(distance_top, distance_bottom))
	var clear_rect: Rect2 = player_rect

	if is_equal_approx(distance_left, minimum_distance):
		clear_rect = clear_rect.merge(Rect2(
			Vector2(room_rect.position.x, player_rect.position.y),
			Vector2(player_rect.end.x - room_rect.position.x, player_rect.size.y)
		))

	if is_equal_approx(distance_right, minimum_distance):
		clear_rect = clear_rect.merge(Rect2(
			Vector2(player_rect.position.x, player_rect.position.y),
			Vector2(room_rect.end.x - player_rect.position.x, player_rect.size.y)
		))

	if is_equal_approx(distance_top, minimum_distance):
		clear_rect = clear_rect.merge(Rect2(
			Vector2(player_rect.position.x, room_rect.position.y),
			Vector2(player_rect.size.x, player_rect.end.y - room_rect.position.y)
		))

	if is_equal_approx(distance_bottom, minimum_distance):
		clear_rect = clear_rect.merge(Rect2(
			Vector2(player_rect.position.x, player_rect.position.y),
			Vector2(player_rect.size.x, room_rect.end.y - player_rect.position.y)
		))

	return clear_rect
