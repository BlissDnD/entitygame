class_name PlaceablePlacementService
extends RefCounted

const PlaceableObjectDefinitionClass = preload("res://systems/placeables/placeable_object_definition.gd")
const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")

var world_data = null
var object_parent: Node = null
var interaction_registry: InteractionRegistry = null


func _init(next_world_data = null, next_object_parent: Node = null) -> void:
	world_data = next_world_data
	object_parent = next_object_parent


func set_context(next_world_data, next_object_parent: Node) -> void:
	world_data = next_world_data
	object_parent = next_object_parent


func set_interaction_registry(next_interaction_registry: InteractionRegistry) -> void:
	interaction_registry = next_interaction_registry


func can_place(definition: PlaceableObjectDefinition, tile_position: Vector2i, placement_mode: int = -1) -> bool:
	if definition == null:
		return false
	if definition.scene == null:
		return false
	if definition.footprint_tiles.x <= 0 or definition.footprint_tiles.y <= 0:
		return false

	var resolved_mode: int = _resolve_placement_mode(definition, placement_mode)
	if not _is_occupied_space_clear(tile_position, definition.footprint_tiles):
		return false

	if not definition.requires_support_tile and resolved_mode == PlaceableObjectDefinitionClass.PlacementMode.BACKGROUND:
		return true

	return _has_required_support(definition, tile_position, resolved_mode)


func place_object(definition: PlaceableObjectDefinition, tile_position: Vector2i, placement_mode: int = -1) -> Node:
	if not can_place(definition, tile_position, placement_mode):
		return null
	if object_parent == null:
		return null

	var placed_object: Node = definition.scene.instantiate()
	object_parent.add_child(placed_object)
	if placed_object is Node2D:
		var placed_node_2d: Node2D = placed_object
		placed_node_2d.global_position = tile_to_world(tile_position) + definition.placement_offset
	if placed_object.has_method("setup_from_definition"):
		placed_object.setup_from_definition(definition)
	if interaction_registry != null and placed_object.has_method("can_interact") and placed_object.has_method("interact"):
		interaction_registry.register_interactable(placed_object)

	return placed_object


func is_solid_tile(tile_position: Vector2i) -> bool:
	if world_data != null and world_data.has_method("has_cell"):
		return world_data.has_cell(tile_position)

	# TODO: Connect this adapter to future non-material tile/background layers.
	return false


func is_background_tile(tile_position: Vector2i) -> bool:
	if world_data == null:
		return true
	if world_data.has_method("has_cell"):
		return not world_data.has_cell(tile_position)

	# TODO: Replace with a real background-layer query when one exists.
	return true


func tile_to_world(tile_position: Vector2i) -> Vector2:
	return WorldUtilsClass.cell_to_world(tile_position)


func _resolve_placement_mode(definition: PlaceableObjectDefinition, placement_mode: int) -> int:
	if placement_mode >= 0:
		return placement_mode

	return definition.placement_mode


func _is_occupied_space_clear(tile_position: Vector2i, footprint_tiles: Vector2i) -> bool:
	for offset_y in range(footprint_tiles.y):
		for offset_x in range(footprint_tiles.x):
			if is_solid_tile(tile_position + Vector2i(offset_x, offset_y)):
				return false

	return true


func _has_required_support(definition: PlaceableObjectDefinition, tile_position: Vector2i, placement_mode: int) -> bool:
	match placement_mode:
		PlaceableObjectDefinitionClass.PlacementMode.BACKGROUND:
			return is_background_tile(tile_position) or not definition.requires_support_tile
		PlaceableObjectDefinitionClass.PlacementMode.FLOOR:
			return _has_floor_support(tile_position, definition.footprint_tiles)
		PlaceableObjectDefinitionClass.PlacementMode.WALL:
			return _has_wall_support(tile_position, definition.footprint_tiles)
		PlaceableObjectDefinitionClass.PlacementMode.TILE_SIDE:
			return _has_tile_side_support(tile_position, definition.footprint_tiles)
		PlaceableObjectDefinitionClass.PlacementMode.TILE_UNDERSIDE:
			return _has_underside_support(tile_position, definition.footprint_tiles)
		_:
			return false


func _has_floor_support(tile_position: Vector2i, footprint_tiles: Vector2i) -> bool:
	var support_y: int = tile_position.y + footprint_tiles.y
	for offset_x in range(footprint_tiles.x):
		if not is_solid_tile(Vector2i(tile_position.x + offset_x, support_y)):
			return false

	return true


func _has_wall_support(tile_position: Vector2i, footprint_tiles: Vector2i) -> bool:
	for offset_y in range(footprint_tiles.y):
		if is_solid_tile(tile_position + Vector2i(-1, offset_y)):
			return true
		if is_solid_tile(tile_position + Vector2i(footprint_tiles.x, offset_y)):
			return true

	return false


func _has_tile_side_support(tile_position: Vector2i, footprint_tiles: Vector2i) -> bool:
	# TODO: Add explicit left/right placement direction when object rotation/orientation exists.
	return _has_wall_support(tile_position, footprint_tiles)


func _has_underside_support(tile_position: Vector2i, footprint_tiles: Vector2i) -> bool:
	var support_y: int = tile_position.y - 1
	for offset_x in range(footprint_tiles.x):
		if not is_solid_tile(Vector2i(tile_position.x + offset_x, support_y)):
			return false

	return true
