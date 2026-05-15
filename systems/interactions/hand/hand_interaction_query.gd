class_name HandInteractionQuery
extends RefCounted

const InteractionTargetClass = preload("res://systems/interactions/interaction_target.gd")
const InteractionTypesClass = preload("res://systems/interactions/interaction_types.gd")


func resolve_target(context: InteractionContext, user: Node = null) -> InteractionTarget:
	if context == null:
		return InteractionTargetClass.new()

	var best_target: InteractionTarget = InteractionTargetClass.new()
	var best_distance_squared: float = INF
	var player_center: Vector2 = context.get_player_rect().get_center()

	for candidate in _gather_candidate_nodes(context):
		if not _is_candidate_interactable(candidate, context, user):
			continue

		var distance_squared: float = player_center.distance_squared_to(_get_candidate_world_position(candidate, player_center))
		if distance_squared >= best_distance_squared:
			continue

		best_distance_squared = distance_squared
		best_target = InteractionTargetClass.new(
			InteractionTypesClass.InteractionMode.HAND,
			_resolve_target_type(candidate),
			candidate,
			{"distance_squared": distance_squared}
		)

	return best_target


func resolve_hovered_target(context: InteractionContext, user: Node = null, mouse_world_position: Vector2 = Vector2.ZERO) -> InteractionTarget:
	if context == null:
		return InteractionTargetClass.new()

	var best_target: InteractionTarget = InteractionTargetClass.new()
	var best_distance_squared: float = INF
	var player_center: Vector2 = context.get_player_rect().get_center()

	for candidate in _gather_candidate_nodes(context):
		if not _is_candidate_hovered(candidate, mouse_world_position):
			continue
		if not _is_candidate_interactable(candidate, context, user):
			continue

		var distance_squared: float = player_center.distance_squared_to(_get_candidate_world_position(candidate, player_center))
		if distance_squared >= best_distance_squared:
			continue

		best_distance_squared = distance_squared
		best_target = InteractionTargetClass.new(
			InteractionTypesClass.InteractionMode.HAND,
			_resolve_target_type(candidate),
			candidate,
			{"distance_squared": distance_squared}
		)

	return best_target


func _gather_candidate_nodes(context: InteractionContext) -> Array[Node]:
	return context.get_hand_interaction_candidates()


func _is_candidate_interactable(candidate: Node, context: InteractionContext, user: Node) -> bool:
	if candidate == null or not is_instance_valid(candidate):
		return false
	if not candidate.has_method("interact"):
		return false
	if candidate.has_method("can_interact"):
		return bool(candidate.can_interact(user, context))
	return true


func _resolve_target_type(candidate: Node) -> int:
	if candidate is BackpackWorldItem:
		return InteractionTypesClass.InteractionTargetType.WORLD_ITEM
	return InteractionTypesClass.InteractionTargetType.ACTOR


func _get_candidate_world_position(candidate: Node, fallback_position: Vector2) -> Vector2:
	if candidate is Node2D:
		return candidate.global_position
	return fallback_position


func _is_candidate_hovered(candidate: Node, mouse_world_position: Vector2) -> bool:
	if candidate == null or not is_instance_valid(candidate):
		return false
	if candidate.has_method("get_interaction_rect"):
		return Rect2(candidate.get_interaction_rect()).has_point(mouse_world_position)
	if candidate is Node2D:
		return candidate.global_position.distance_squared_to(mouse_world_position) <= 16.0 * 16.0
	return false
