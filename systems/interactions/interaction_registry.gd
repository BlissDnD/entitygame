class_name InteractionRegistry
extends RefCounted

var interactables: Array[Node] = []


func register_interactable(interactable: Node) -> void:
	if interactable == null or not is_instance_valid(interactable):
		return
	if interactables.has(interactable):
		return
	interactables.append(interactable)


func unregister_interactable(interactable: Node) -> void:
	if interactable == null:
		return
	interactables.erase(interactable)


func get_interactables() -> Array[Node]:
	var valid_interactables: Array[Node] = []
	for interactable in interactables:
		if interactable == null or not is_instance_valid(interactable):
			continue
		valid_interactables.append(interactable)
	return valid_interactables
