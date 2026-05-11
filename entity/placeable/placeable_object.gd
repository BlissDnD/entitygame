class_name PlaceableObject
extends Node2D

@export var definition: PlaceableObjectDefinition
@export var has_collision: bool = false

@onready var debug_label: Label = $DebugLabel


func _ready() -> void:
	if definition != null:
		setup_from_definition(definition)
	else:
		_apply_collision_state()


func setup_from_definition(new_definition: PlaceableObjectDefinition) -> void:
	definition = new_definition
	has_collision = definition.has_collision
	if debug_label != null:
		debug_label.text = definition.display_name
	_apply_collision_state()


func _apply_collision_state() -> void:
	_apply_collision_state_recursive(self)


func _apply_collision_state_recursive(node: Node) -> void:
	if node is CollisionShape2D:
		var collision_shape: CollisionShape2D = node
		collision_shape.disabled = not has_collision
	if node is CollisionPolygon2D:
		var collision_polygon: CollisionPolygon2D = node
		collision_polygon.disabled = not has_collision

	for child in node.get_children():
		_apply_collision_state_recursive(child)
