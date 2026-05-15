class_name InteractionContext
extends RefCounted

var player_cursor_controller: PlayerCursorController = null
var item_interaction_controller: ItemInteractionController = null
var crash_ship_interaction_controller: CrashShipInteractionController = null
var inventory_runtime: InventoryRuntime = null
var player_equipment: PlayerEquipment = null
var crash_ship: CrashShip = null
var interaction_registry: InteractionRegistry = null
var refresh_godmode_ui: Callable = Callable()
var get_world_size_from_cells: Callable = Callable()
var get_hand_interaction_candidates_callback: Callable = Callable()
var current_room_index: int = 0
var mouse_world_position: Vector2 = Vector2.ZERO
var player_world_position: Vector2 = Vector2.ZERO
var player_size_cells: Vector2i = Vector2i.ZERO


func configure(config: Dictionary) -> void:
	player_cursor_controller = config.get("player_cursor_controller", player_cursor_controller)
	item_interaction_controller = config.get("item_interaction_controller", item_interaction_controller)
	crash_ship_interaction_controller = config.get("crash_ship_interaction_controller", crash_ship_interaction_controller)
	inventory_runtime = config.get("inventory_runtime", inventory_runtime)
	player_equipment = config.get("player_equipment", player_equipment)
	crash_ship = config.get("crash_ship", crash_ship)
	interaction_registry = config.get("interaction_registry", interaction_registry)
	refresh_godmode_ui = config.get("refresh_godmode_ui", refresh_godmode_ui)
	get_world_size_from_cells = config.get("get_world_size_from_cells", get_world_size_from_cells)
	get_hand_interaction_candidates_callback = config.get("get_hand_interaction_candidates", get_hand_interaction_candidates_callback)


func set_frame_state(state: Dictionary) -> void:
	current_room_index = int(state.get("current_room_index", current_room_index))
	mouse_world_position = Vector2(state.get("mouse_world_position", mouse_world_position))
	player_world_position = Vector2(state.get("player_world_position", player_world_position))
	player_size_cells = Vector2i(state.get("player_size_cells", player_size_cells))


func get_player_rect() -> Rect2:
	if not get_world_size_from_cells.is_valid():
		return Rect2(player_world_position, Vector2.ZERO)
	return Rect2(player_world_position, get_world_size_from_cells.call(player_size_cells))


func get_hand_interaction_candidates() -> Array[Node]:
	if not get_hand_interaction_candidates_callback.is_valid():
		return []
	return get_hand_interaction_candidates_callback.call()
