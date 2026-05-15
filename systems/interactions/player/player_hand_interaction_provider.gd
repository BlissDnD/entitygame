class_name PlayerHandInteractionProvider
extends RefCounted

var interaction_registry: InteractionRegistry = null


func configure(config: Dictionary) -> void:
	interaction_registry = config.get("interaction_registry", interaction_registry)


func get_candidates() -> Array[Node]:
	if interaction_registry == null:
		return []
	return interaction_registry.get_interactables()
