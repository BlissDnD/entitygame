class_name WorldGenerationSurfaceController
extends RefCounted

const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")
const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const PlaceablePlacementServiceClass = preload("res://systems/placeables/placeable_placement_service.gd")


func generate_rooms(context: Dictionary) -> Array[Dictionary]:
	_clear_room_placeable_containers(context.placeable_objects)
	_clear_room_npc_containers(context.npc_objects, context.persistent_followers)
	print("Old direct tree placement disabled; using PlaceablePlacementService for surface trees")

	var rooms: Array[Dictionary] = []
	for room_index in range(context.room_count):
		var room_size_cells: Vector2i = _generate_room_size_cells(context.viewport_world_size, context.room_rng)
		var room_world_data = _create_room_world_data(room_size_cells, context.world_data_class, context.get_surface_cell_y_for_room)
		var room_placeable_container: Node2D = _create_room_placeable_container(context.placeable_objects, room_index, context.active_room_index)
		var room_npc_container: Node2D = _create_room_npc_container(context.npc_objects, room_index, context.active_room_index)
		var tree_placement_stats: Dictionary = _create_tree_placement_stats(room_index)
		var room_surface_props: Array = _generate_surface_props_for_room(
			room_size_cells,
			room_world_data,
			room_placeable_container,
			tree_placement_stats,
			context
		)
		var room_entry: Dictionary = {
			"room_size_cells": room_size_cells,
			"world_data": room_world_data,
			"drop_data": context.item_drop_data_class.new(),
			"gravity_field_system": context.gravity_field_system_class.new(),
			"placeable_container": room_placeable_container,
			"npc_container": room_npc_container,
			"surface_props": room_surface_props,
			"protected_cells": _build_protected_cells_for_props(room_surface_props),
			"tree_placement_stats": tree_placement_stats,
		}
		rooms.append(room_entry)
		context.create_atlas_worker_spawn_point.call(room_index, room_size_cells, room_npc_container)
		_print_tree_placement_stats(tree_placement_stats)

	return rooms


func _create_room_world_data(room_size_cells: Vector2i, world_data_class, get_surface_cell_y_for_room: Callable):
	var room_world_data = world_data_class.new()
	var surface_cell_y: int = get_surface_cell_y_for_room.call(room_size_cells)
	var dirt_end_y: int = mini(surface_cell_y + GameplayTuningClass.SURFACE_DEPTH, room_size_cells.y)

	for cell_y in range(surface_cell_y, dirt_end_y):
		for cell_x in range(0, room_size_cells.x):
			room_world_data.set_cell(Vector2i(cell_x, cell_y), WorldConstantsClass.CellType.DIRT)

	for cell_y in range(dirt_end_y, room_size_cells.y):
		for cell_x in range(0, room_size_cells.x):
			room_world_data.set_cell(Vector2i(cell_x, cell_y), WorldConstantsClass.CellType.STONE)

	return room_world_data


func _generate_room_size_cells(viewport_world_size: Vector2, room_rng: RandomNumberGenerator) -> Vector2i:
	var min_viewport_width_cells: int = int(ceili(viewport_world_size.x / float(WorldConstantsClass.CELL_SIZE.x)))
	var min_viewport_height_cells: int = int(ceili(viewport_world_size.y / float(WorldConstantsClass.CELL_SIZE.y)))
	var min_size: Vector2i = GameplayTuningClass.ROOM_MIN_SIZE_CELLS
	var max_size: Vector2i = GameplayTuningClass.ROOM_MAX_SIZE_CELLS
	var width_min: int = maxi(min_size.x, min_viewport_width_cells)
	var width_max: int = maxi(width_min, max_size.x)
	var fixed_height: int = maxi(min_size.y, min_viewport_height_cells)

	return Vector2i(
		room_rng.randi_range(width_min, width_max),
		fixed_height
	)


func _clear_room_placeable_containers(placeable_objects: Node2D) -> void:
	if placeable_objects == null:
		return

	for child in placeable_objects.get_children():
		child.queue_free()


func _create_room_placeable_container(placeable_objects: Node2D, room_index: int, active_room_index: int) -> Node2D:
	var room_placeable_container: Node2D = Node2D.new()
	room_placeable_container.name = "room_%d_placeables" % room_index
	room_placeable_container.visible = room_index == active_room_index
	placeable_objects.add_child(room_placeable_container)
	return room_placeable_container


func _clear_room_npc_containers(npc_objects: Node2D, persistent_followers: Node2D) -> void:
	if npc_objects == null:
		return

	for child in npc_objects.get_children():
		if child == persistent_followers:
			continue
		child.queue_free()


func _create_room_npc_container(npc_objects: Node2D, room_index: int, active_room_index: int) -> Node2D:
	var room_npc_container: Node2D = Node2D.new()
	room_npc_container.name = "room_%d_npcs" % room_index
	room_npc_container.visible = room_index == active_room_index
	room_npc_container.process_mode = Node.PROCESS_MODE_INHERIT if room_index == active_room_index else Node.PROCESS_MODE_DISABLED
	npc_objects.add_child(room_npc_container)
	return room_npc_container


func _create_tree_placement_stats(room_index: int) -> Dictionary:
	return {
		"room_index": room_index,
		"valid_surface_positions": 0,
		"placed_count": 0,
		"failure_count": 0,
	}


func _try_place_surface_tree(
	placement_service: PlaceablePlacementService,
	surface_cell: Vector2i,
	tree_placement_stats: Dictionary,
	prototype_tree_definition
) -> void:
	var placement_tile: Vector2i = Vector2i(
		surface_cell.x,
		surface_cell.y - prototype_tree_definition.footprint_tiles.y
	)

	if placement_service.can_place(prototype_tree_definition, placement_tile, prototype_tree_definition.placement_mode):
		tree_placement_stats["valid_surface_positions"] = int(tree_placement_stats.get("valid_surface_positions", 0)) + 1
	else:
		tree_placement_stats["failure_count"] = int(tree_placement_stats.get("failure_count", 0)) + 1
		print("Tree placement failed at surface cell %s: invalid FLOOR position" % [surface_cell])
		return

	var placed_tree: Node = placement_service.place_object(prototype_tree_definition, placement_tile, prototype_tree_definition.placement_mode)
	if placed_tree == null:
		tree_placement_stats["failure_count"] = int(tree_placement_stats.get("failure_count", 0)) + 1
		print("Tree placement failed at surface cell %s: PlaceablePlacementService returned null" % [surface_cell])
		return

	tree_placement_stats["placed_count"] = int(tree_placement_stats.get("placed_count", 0)) + 1


func _print_tree_placement_stats(tree_placement_stats: Dictionary) -> void:
	print(
		"Room %d tree placeables: valid surface positions %d, placed %d, failures %d" % [
			int(tree_placement_stats.get("room_index", 0)),
			int(tree_placement_stats.get("valid_surface_positions", 0)),
			int(tree_placement_stats.get("placed_count", 0)),
			int(tree_placement_stats.get("failure_count", 0)),
		]
	)


func _generate_surface_props_for_room(
	room_size_cells: Vector2i,
	room_world_data,
	room_placeable_container: Node2D,
	tree_placement_stats: Dictionary,
	context: Dictionary
) -> Array:
	var props: Array = []
	var tree_placement_service = PlaceablePlacementServiceClass.new(room_world_data, room_placeable_container)
	tree_placement_service.set_interaction_registry(context.get("interaction_registry", null))
	var surface_cell_y: int = context.get_surface_cell_y_for_room.call(room_size_cells)
	var cell_x: int = GameplayTuningClass.SURFACE_PROP_EDGE_MARGIN_CELLS
	var max_cell_x: int = room_size_cells.x - GameplayTuningClass.SURFACE_PROP_EDGE_MARGIN_CELLS

	while cell_x < max_cell_x:
		if context.room_rng.randf() > GameplayTuningClass.SURFACE_PROP_DENSITY:
			cell_x += 1
			continue

		var prop_roll: float = context.room_rng.randf()
		var prop_entry: Dictionary = {}
		if prop_roll < 0.58:
			var tree_footprint_width: int = context.prototype_tree_definition.footprint_tiles.x
			if cell_x + tree_footprint_width >= max_cell_x:
				break

			_try_place_surface_tree(
				tree_placement_service,
				Vector2i(cell_x, surface_cell_y),
				tree_placement_stats,
				context.prototype_tree_definition
			)
			cell_x += tree_footprint_width + GameplayTuningClass.SURFACE_PROP_SPACING_MIN_CELLS + context.room_rng.randi_range(0, 2)
			continue
		elif prop_roll < 0.82:
			prop_entry = {
				"type": context.surface_prop_bush,
				"base_cell": Vector2i(cell_x, surface_cell_y),
				"footprint_width_cells": context.room_rng.randi_range(2, 4),
				"width_cells": context.room_rng.randi_range(2, 4),
				"height_cells": context.room_rng.randi_range(1, 2),
			}
		else:
			prop_entry = {
				"type": context.surface_prop_rock,
				"base_cell": Vector2i(cell_x, surface_cell_y),
				"footprint_width_cells": context.room_rng.randi_range(2, 4),
				"width_cells": context.room_rng.randi_range(2, 4),
				"height_cells": context.room_rng.randi_range(1, 2),
			}

		var footprint_width: int = int(prop_entry.get("footprint_width_cells", 1))
		if cell_x + footprint_width >= max_cell_x:
			break

		props.append(prop_entry)
		cell_x += footprint_width + GameplayTuningClass.SURFACE_PROP_SPACING_MIN_CELLS + context.room_rng.randi_range(0, 2)

	return props


func _build_protected_cells_for_props(surface_props: Array) -> Dictionary:
	var protected_cells: Dictionary = {}

	for prop_entry in surface_props:
		var base_cell: Vector2i = Vector2i(prop_entry.get("base_cell", Vector2i.ZERO))
		var footprint_width_cells: int = int(prop_entry.get("footprint_width_cells", 1))
		for offset_x in range(footprint_width_cells):
			for depth in range(GameplayTuningClass.SURFACE_PROP_PROTECTED_DEPTH_CELLS):
				protected_cells[Vector2i(base_cell.x + offset_x, base_cell.y + depth)] = true

	return protected_cells
