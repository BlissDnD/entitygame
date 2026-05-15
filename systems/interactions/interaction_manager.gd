class_name InteractionManager
extends RefCounted

const InteractionTypesClass = preload("res://systems/interactions/interaction_types.gd")
const HandInteractionControllerClass = preload("res://systems/interactions/hand/hand_interaction_controller.gd")

var hand_interaction_controller = HandInteractionControllerClass.new()


func get_active_mode(player_cursor_controller: PlayerCursorController) -> int:
	if player_cursor_controller == null:
		return InteractionTypesClass.InteractionMode.HAND
	return InteractionTypesClass.from_cursor_behavior(player_cursor_controller.get_current_cursor_behavior())


func try_interact(context: InteractionContext, user: Node = null) -> Dictionary:
	if context == null:
		return {"handled": false}

	var active_mode: int = get_active_mode(context.player_cursor_controller)
	match active_mode:
		InteractionTypesClass.InteractionMode.HAND:
			var hand_result: Dictionary = hand_interaction_controller.try_interact(context, user)
			hand_result["interaction_mode"] = active_mode
			return hand_result
		_:
			var fallback_result: Dictionary = hand_interaction_controller.try_interact(context, user)
			fallback_result["interaction_mode"] = active_mode
			return fallback_result


func get_hovered_hand_target(context: InteractionContext, user: Node = null, mouse_world_position: Vector2 = Vector2.ZERO) -> InteractionTarget:
	return hand_interaction_controller.hand_interaction_query.resolve_hovered_target(context, user, mouse_world_position)
