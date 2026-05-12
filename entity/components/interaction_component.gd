class_name InteractionComponent
extends Area2D

signal interactable_entered(interactable: Node)
signal interactable_exited(interactable: Node)
signal interacted(interactable: Node)

var nearby_interactables: Array[Node] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func get_best_interactable() -> Node:
	if nearby_interactables.is_empty():
		return null
	return nearby_interactables[0]


func try_interact(user: Node) -> bool:
	var interactable: Node = get_best_interactable()
	if interactable == null:
		return false
	if not interactable.has_method("interact"):
		return false

	interactable.interact(user)
	interacted.emit(interactable)
	return true


func _track_interactable(node: Node) -> void:
	if node == null or not node.has_method("interact"):
		return
	if nearby_interactables.has(node):
		return
	nearby_interactables.append(node)
	interactable_entered.emit(node)


func _untrack_interactable(node: Node) -> void:
	if not nearby_interactables.has(node):
		return
	nearby_interactables.erase(node)
	interactable_exited.emit(node)


func _on_body_entered(body: Node) -> void:
	_track_interactable(body)


func _on_body_exited(body: Node) -> void:
	_untrack_interactable(body)


func _on_area_entered(area: Area2D) -> void:
	_track_interactable(area)
	_track_interactable(area.get_parent())


func _on_area_exited(area: Area2D) -> void:
	_untrack_interactable(area)
	_untrack_interactable(area.get_parent())
