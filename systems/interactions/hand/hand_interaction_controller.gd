class_name HandInteractionController
extends RefCounted

const HandInteractionQueryClass = preload("res://systems/interactions/hand/hand_interaction_query.gd")
const InteractionTargetClass = preload("res://systems/interactions/interaction_target.gd")

var hand_interaction_query = HandInteractionQueryClass.new()


func try_interact(context: InteractionContext, user: Node = null) -> Dictionary:
	if context == null:
		return {"handled": false}

	var interaction_target: InteractionTarget = hand_interaction_query.resolve_hovered_target(
		context,
		user,
		context.mouse_world_position
	)
	if not interaction_target.is_valid():
		return {"handled": false}

	if not _execute_target(interaction_target, context, user):
		return {"handled": false}

	return {
		"handled": true,
		"interaction_target": interaction_target,
	}


func _execute_target(interaction_target: InteractionTarget, context: InteractionContext, user: Node) -> bool:
	var target_node: Node = interaction_target.target_node
	if target_node == null or not is_instance_valid(target_node):
		return false
	var result = target_node.interact(user, context)
	if result is bool:
		return result
	return true
