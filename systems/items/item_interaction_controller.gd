class_name ItemInteractionController
extends RefCounted

var item_drop_data: ItemDropData = null
var inventory_runtime: InventoryRuntime = null
var player_equipment: PlayerEquipment = null
var interaction_registry: InteractionRegistry = null
var spawn_manager: SpawnManager = null
var world_items: Node2D = null
var world_backpack_items: Array[BackpackWorldItem] = []
var has_spawned_initial_backpack: bool = false


func _init(
	next_item_drop_data: ItemDropData = null,
	next_inventory_runtime: InventoryRuntime = null,
	next_player_equipment: PlayerEquipment = null
) -> void:
	item_drop_data = next_item_drop_data
	inventory_runtime = next_inventory_runtime
	player_equipment = next_player_equipment


func bind_scene_dependencies(next_spawn_manager: SpawnManager, next_world_items: Node2D) -> void:
	spawn_manager = next_spawn_manager
	world_items = next_world_items


func set_interaction_registry(next_interaction_registry: InteractionRegistry) -> void:
	interaction_registry = next_interaction_registry


func set_item_drop_data(next_item_drop_data: ItemDropData) -> void:
	item_drop_data = next_item_drop_data


func get_backpack_world_items() -> Array[BackpackWorldItem]:
	var valid_items: Array[BackpackWorldItem] = []
	for backpack_item in world_backpack_items:
		if backpack_item == null or not is_instance_valid(backpack_item):
			continue
		valid_items.append(backpack_item)
	return valid_items


func unregister_backpack_world_item(backpack_item: BackpackWorldItem) -> void:
	if backpack_item == null:
		return
	world_backpack_items.erase(backpack_item)
	if interaction_registry != null:
		interaction_registry.unregister_interactable(backpack_item)


func update_item_drops(
	world_data,
	delta: float,
	room_rect: Rect2,
	gravity: float,
	pull_radius_pixels: float,
	merge_radius_pixels: float,
	gravity_field_system
) -> bool:
	var previous_drop_count: int = item_drop_data.get_drops().size()
	item_drop_data.update_physics(
		world_data,
		delta,
		room_rect,
		gravity,
		pull_radius_pixels,
		merge_radius_pixels,
		gravity_field_system
	)
	return previous_drop_count != item_drop_data.get_drops().size() or previous_drop_count > 0


func find_hovered_drop_index(mouse_world_position: Vector2, hover_radius_pixels: float) -> int:
	return item_drop_data.find_nearest_drop_index(mouse_world_position, hover_radius_pixels)


func try_pick_up_hovered_drop(
	hovered_drop_index: int,
	mouse_world_position: Vector2,
	hover_radius_pixels: float
) -> Dictionary:
	var picked_any: bool = inventory_runtime.try_pick_up_drop(item_drop_data, hovered_drop_index)
	var next_hovered_drop_index: int = hovered_drop_index
	if picked_any:
		next_hovered_drop_index = find_hovered_drop_index(mouse_world_position, hover_radius_pixels)

	return {
		"picked_any": picked_any,
		"hovered_drop_index": next_hovered_drop_index,
	}


func spawn_initial_backpack_world_item(
	player_ground_world: Vector2,
	initial_backpack_definition: ItemDefinition,
	default_scene: PackedScene
) -> void:
	if has_spawned_initial_backpack:
		return

	spawn_backpack_world_item(player_ground_world + Vector2(42.0, 0.0), initial_backpack_definition, default_scene)
	has_spawned_initial_backpack = true


func try_interact_with_backpack_world_item(player_rect: Rect2) -> Dictionary:
	for backpack_item in world_backpack_items:
		if not is_instance_valid(backpack_item):
			continue
		if not backpack_item.overlaps_world_rect(player_rect):
			continue

		if player_equipment.get_equipped_backpack() != null:
			print("[Backpack] Cannot equip backpack: backpack slot already occupied")
			return {
				"handled": true,
				"did_change_inventory": false,
			}

		var item_definition: ItemDefinition = backpack_item.item_definition
		var did_equip: bool = inventory_runtime.equip_backpack_item(item_definition, "[Backpack]")
		if did_equip:
			unregister_backpack_world_item(backpack_item)
			backpack_item.queue_free()

		return {
			"handled": true,
			"did_change_inventory": did_equip,
		}

	return {
		"handled": false,
		"did_change_inventory": false,
	}


func drop_equipped_backpack(
	player_ground_world: Vector2,
	is_moving_left: bool,
	default_scene: PackedScene
) -> bool:
	var equipped_backpack: ItemDefinition = inventory_runtime.unequip_backpack_for_drop()
	if equipped_backpack == null:
		return false

	spawn_backpack_world_item(get_backpack_drop_position(player_ground_world, is_moving_left), equipped_backpack, default_scene)
	print("[Backpack] Backpack dropped")
	return true


func get_backpack_drop_position(player_ground_world: Vector2, is_moving_left: bool) -> Vector2:
	var drop_offset_x: float = 28.0
	if is_moving_left:
		drop_offset_x = -28.0
	return player_ground_world + Vector2(drop_offset_x, 0.0)


func spawn_backpack_world_item(
	world_position: Vector2,
	item_definition: ItemDefinition,
	default_scene: PackedScene
) -> BackpackWorldItem:
	if spawn_manager == null or world_items == null:
		return null

	var scene: PackedScene = default_scene
	if item_definition != null and item_definition.uses_scene_world_drop():
		scene = item_definition.get_dropped_world_scene()

	var backpack_item: BackpackWorldItem = spawn_manager.spawn_scene(scene, world_items, world_position, &"backpack_world_item") as BackpackWorldItem
	if backpack_item == null:
		return null

	backpack_item.setup(item_definition)
	world_backpack_items.append(backpack_item)
	if interaction_registry != null:
		interaction_registry.register_interactable(backpack_item)
	return backpack_item
