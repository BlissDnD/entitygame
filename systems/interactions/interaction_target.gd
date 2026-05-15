class_name InteractionTarget
extends RefCounted

const InteractionTypesClass = preload("res://systems/interactions/interaction_types.gd")

var interaction_mode: int = InteractionTypesClass.InteractionMode.NONE
var target_type: int = InteractionTypesClass.InteractionTargetType.NONE
var target_node: Node = null
var metadata: Dictionary = {}


func _init(
	next_interaction_mode: int = InteractionTypesClass.InteractionMode.NONE,
	next_target_type: int = InteractionTypesClass.InteractionTargetType.NONE,
	next_target_node: Node = null,
	next_metadata: Dictionary = {}
) -> void:
	interaction_mode = next_interaction_mode
	target_type = next_target_type
	target_node = next_target_node
	metadata = next_metadata.duplicate(true)


func is_valid() -> bool:
	return target_type != InteractionTypesClass.InteractionTargetType.NONE
