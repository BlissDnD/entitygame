class_name GodModeUiController
extends RefCounted

const BuildModeRuntimeClass = preload("res://systems/build/build_mode_runtime.gd")

var console_panel: Panel = null
var console_input: LineEdit = null
var godmode_panel: GodModePanel = null
var ui_root: UIRoot = null
var debug_settings = null
var godmode_action_handler: GodModeActionHandler = null
var godmode_snapshot_builder: GodModeSnapshotBuilder = null
var time_debug_controller: TimeDebugController = null
var inventory_runtime: InventoryRuntime = null
var inventory_data: InventoryData = null
var player_equipment: PlayerEquipment = null
var backpack_container: BackpackContainer = null
var player_cursor_controller: PlayerCursorController = null
var time_manager: TimeManager = null
var map_handler: MapHandler = null
var world_draw_controller: WorldDrawController = null
var item_registry: ItemRegistry = null

var queue_redraw_callback: Callable = Callable()
var start_background_fade_callback: Callable = Callable()
var equip_backpack_item_callback: Callable = Callable()
var set_debug_enabled_callback: Callable = Callable()
var set_inventory_capacity_callback: Callable = Callable()
var set_inventory_weight_capacity_callback: Callable = Callable()
var set_build_mode_callback: Callable = Callable()
var select_gravity_strength_callback: Callable = Callable()

var get_item_drop_data_callback: Callable = Callable()
var get_gravity_field_system_callback: Callable = Callable()
var get_build_mode_name_callback: Callable = Callable()
var is_player_inside_gravity_field_callback: Callable = Callable()
var get_selected_material_name_callback: Callable = Callable()
var get_shape_name_callback: Callable = Callable()
var get_current_room_index_callback: Callable = Callable()
var get_room_world_rect_callback: Callable = Callable()
var get_current_room_surface_cell_y_callback: Callable = Callable()


func configure(context: Dictionary) -> void:
	console_panel = context.console_panel
	console_input = context.console_input
	godmode_panel = context.godmode_panel
	ui_root = context.ui_root
	debug_settings = context.debug_settings
	godmode_action_handler = context.godmode_action_handler
	godmode_snapshot_builder = context.godmode_snapshot_builder
	time_debug_controller = context.time_debug_controller
	inventory_runtime = context.inventory_runtime
	item_registry = context.item_registry
	inventory_data = context.inventory_data
	player_equipment = context.player_equipment
	backpack_container = context.backpack_container
	player_cursor_controller = context.player_cursor_controller
	time_manager = context.time_manager
	map_handler = context.map_handler
	world_draw_controller = context.world_draw_controller

	queue_redraw_callback = context.queue_redraw
	start_background_fade_callback = context.start_background_fade
	equip_backpack_item_callback = context.equip_backpack_item
	set_debug_enabled_callback = context.set_debug_enabled
	set_inventory_capacity_callback = context.set_inventory_capacity
	set_inventory_weight_capacity_callback = context.set_inventory_weight_capacity
	set_build_mode_callback = context.set_build_mode
	select_gravity_strength_callback = context.select_gravity_strength

	get_item_drop_data_callback = context.get_item_drop_data
	get_gravity_field_system_callback = context.get_gravity_field_system
	get_build_mode_name_callback = context.get_build_mode_name
	is_player_inside_gravity_field_callback = context.is_player_inside_gravity_field
	get_selected_material_name_callback = context.get_selected_material_name
	get_shape_name_callback = context.get_shape_name
	get_current_room_index_callback = context.get_current_room_index
	get_room_world_rect_callback = context.get_room_world_rect
	get_current_room_surface_cell_y_callback = context.get_current_room_surface_cell_y


func connect_signals() -> void:
	if time_manager != null:
		time_manager.hour_changed.connect(_on_sun_cycle_hour_changed)
		time_manager.sun_room_changed.connect(_on_sun_cycle_sun_room_changed)
		time_manager.room_time_state_changed.connect(_on_room_time_state_changed)

	if console_input != null:
		console_input.text_submitted.connect(_on_console_input_text_submitted)
		

	if godmode_panel == null:
		return

	godmode_panel.mining_power_changed.connect(_on_godmode_mining_power_changed)
	godmode_panel.mining_radius_changed.connect(_on_godmode_mining_radius_changed)
	godmode_panel.mining_shape_changed.connect(_on_godmode_mining_shape_changed)
	godmode_panel.equip_tool_requested.connect(_on_equip_tool_button_pressed)
	godmode_panel.unequip_tool_requested.connect(_on_unequip_tool_button_pressed)
	godmode_panel.equip_backpack_requested.connect(_on_equip_backpack_button_pressed)
	godmode_panel.unequip_backpack_requested.connect(_on_unequip_backpack_button_pressed)
	godmode_panel.equip_axe_requested.connect(_on_equip_axe_button_pressed)
	godmode_panel.unequip_axe_requested.connect(_on_unequip_axe_button_pressed)
	godmode_panel.add_stone_requested.connect(_on_add_stone_button_pressed)
	godmode_panel.add_scrap_requested.connect(_on_add_scrap_button_pressed)
	godmode_panel.print_equipment_requested.connect(_on_print_equipment_button_pressed)
	godmode_panel.print_backpack_requested.connect(_on_print_backpack_button_pressed)
	godmode_panel.gravity_field_mode_requested.connect(_on_gravity_field_mode_requested)
	godmode_panel.gravity_point_mode_requested.connect(_on_gravity_point_mode_requested)
	godmode_panel.gravity_strength_selected.connect(_on_gravity_strength_selected)
	godmode_panel.time_forward_requested.connect(_on_time_forward_requested)
	godmode_panel.time_backward_requested.connect(_on_time_backward_requested)


func toggle_console() -> void:
	set_console_visible(not is_console_open())
	queue_redraw_callback.call()


func set_console_visible(is_visible: bool) -> void:
	if console_panel == null or console_input == null:
		return

	console_panel.visible = is_visible

	if is_visible:
		console_input.text = ""
		console_input.grab_focus()
	else:
		console_input.release_focus()


func is_console_open() -> bool:
	return console_panel != null and console_panel.visible


func is_pointer_over_debug_ui(viewport_mouse_position: Vector2) -> bool:
	if console_panel != null and console_panel.visible and console_panel.get_global_rect().has_point(viewport_mouse_position):
		return true

	if godmode_panel != null and godmode_panel.visible and godmode_panel.get_global_rect().has_point(viewport_mouse_position):
		return true

	return false


func update_godmode_visibility() -> void:
	if godmode_panel == null:
		return
	godmode_panel.set_visible_state(debug_settings.godmode_enabled)


func refresh_godmode_ui() -> void:
	update_godmode_visibility()
	if godmode_panel == null:
		return
	godmode_panel.refresh(build_godmode_snapshot())


func build_time_hud_text() -> String:
	return time_debug_controller.build_time_hud_text(time_manager, map_handler)


func update_time_hud() -> void:
	time_debug_controller.update_hud(ui_root, time_manager, map_handler, get_build_mode_name_callback.call())


func build_godmode_snapshot() -> Dictionary:
	return godmode_snapshot_builder.build_snapshot(
		debug_settings,
		inventory_runtime,
		inventory_data,
		get_item_drop_data_callback.call(),
		get_gravity_field_system_callback.call(),
		player_equipment,
		backpack_container,
		player_cursor_controller,
		time_manager,
		map_handler,
		get_build_mode_name_callback.call(),
		is_player_inside_gravity_field_callback.call(),
		get_selected_material_name_callback.call(),
		get_shape_name_callback.call(debug_settings.mining_shape),
		build_time_hud_text()
	)


func _on_console_input_text_submitted(new_text: String) -> void:
	var command: String = new_text.strip_edges().to_lower()
	var result: Dictionary = godmode_action_handler.handle_console_command(command, {
		"backpack_container": backpack_container,
		"item_registry": item_registry,
		"basic_axe_item_definition": preload("res://resources/items/equipment/tools/basic_axe.tres"),
		"basic_backpack_item_definition": preload("res://resources/items/equipment/backpacks/basic_backpack.tres"),
		"basic_mining_tool_definition": preload("res://resources/items/equipment/tools/basic_mining_tool.tres"),
		"current_room_index": get_current_room_index_callback.call(),
		"debug_settings": debug_settings,
		"equip_backpack_item": equip_backpack_item_callback,
		"inventory_data": inventory_data,
		"inventory_runtime": inventory_runtime,
		"player_cursor_controller": player_cursor_controller,
		"player_equipment": player_equipment,
		"scrap_item_definition": preload("res://resources/items/salvage/scrap.tres"),
		"set_debug_enabled": Callable(self, "_set_debug_overlay_enabled"),
		"set_inventory_capacity": set_inventory_capacity_callback,
		"set_inventory_weight_capacity": set_inventory_weight_capacity_callback,
		"start_background_fade": start_background_fade_callback,
		"stone_item_definition": preload("res://resources/items/materials/stone.tres"),
		"time_manager": time_manager,
	})
	if bool(result.get("close_console", false)):
		set_console_visible(false)
	if bool(result.get("refresh_ui", false)):
		refresh_godmode_ui()
	if bool(result.get("clear_console", true)) and console_input != null:
		console_input.text = ""
	if bool(result.get("queue_redraw", false)):
		queue_redraw_callback.call()


func _on_godmode_mining_power_changed(value: float) -> void:
	godmode_action_handler.apply_mining_power(value, debug_settings)
	refresh_godmode_ui()
	queue_redraw_callback.call()


func _on_godmode_mining_radius_changed(value: int) -> void:
	godmode_action_handler.apply_mining_radius(value, debug_settings)
	refresh_godmode_ui()
	queue_redraw_callback.call()


func _on_godmode_mining_shape_changed(shape: int) -> void:
	godmode_action_handler.apply_mining_shape(shape, debug_settings)
	refresh_godmode_ui()
	queue_redraw_callback.call()


func _run_godmode_item_ui_command(command: String) -> void:
	var result: Dictionary = godmode_action_handler.handle_item_command(command, {
		"backpack_container": backpack_container,
		"item_registry": item_registry,
		"basic_axe_item_definition": preload("res://resources/items/equipment/tools/basic_axe.tres"),
		"basic_backpack_item_definition": preload("res://resources/items/equipment/backpacks/basic_backpack.tres"),
		"basic_mining_tool_definition": preload("res://resources/items/equipment/tools/basic_mining_tool.tres"),
		"current_room_index": get_current_room_index_callback.call(),
		"equip_backpack_item": equip_backpack_item_callback,
		"inventory_runtime": inventory_runtime,
		"player_cursor_controller": player_cursor_controller,
		"player_equipment": player_equipment,
		"scrap_item_definition": preload("res://resources/items/salvage/scrap.tres"),
		"start_background_fade": start_background_fade_callback,
		"stone_item_definition": preload("res://resources/items/materials/stone.tres"),
		"time_manager": time_manager,
	})
	if bool(result.get("refresh_ui", false)):
		refresh_godmode_ui()
	if bool(result.get("queue_redraw", false)):
		queue_redraw_callback.call()


func _on_equip_tool_button_pressed() -> void:
	_run_godmode_item_ui_command("equip_mining_tool")


func _on_unequip_tool_button_pressed() -> void:
	_run_godmode_item_ui_command("unequip_mining_tool")


func _on_equip_backpack_button_pressed() -> void:
	_run_godmode_item_ui_command("equip_backpack")


func _on_unequip_backpack_button_pressed() -> void:
	_run_godmode_item_ui_command("unequip_backpack")


func _on_equip_axe_button_pressed() -> void:
	_run_godmode_item_ui_command("equip_axe")


func _on_unequip_axe_button_pressed() -> void:
	_run_godmode_item_ui_command("unequip_axe")


func _on_add_stone_button_pressed() -> void:
	_run_godmode_item_ui_command("add_stone")


func _on_add_scrap_button_pressed() -> void:
	_run_godmode_item_ui_command("add_scrap")


func _on_print_equipment_button_pressed() -> void:
	_run_godmode_item_ui_command("print_equipment")


func _on_print_backpack_button_pressed() -> void:
	_run_godmode_item_ui_command("print_backpack")


func _on_gravity_field_mode_requested() -> void:
	set_build_mode_callback.call(BuildModeRuntimeClass.BuildMode.GRAVITY_FIELD)


func _on_gravity_point_mode_requested() -> void:
	set_build_mode_callback.call(BuildModeRuntimeClass.BuildMode.GRAVITY_POINT)


func _on_gravity_strength_selected(level_index: int) -> void:
	var result: Dictionary = select_gravity_strength_callback.call(level_index)
	print(String(result.get("log_message", "")))
	if not bool(result.get("success", false)):
		return
	refresh_godmode_ui()
	queue_redraw_callback.call()


func _on_time_forward_requested() -> void:
	var result: Dictionary = godmode_action_handler.handle_time_forward(
		time_manager,
		start_background_fade_callback,
		get_current_room_index_callback.call()
	)
	if bool(result.get("update_time_hud", false)):
		update_time_hud()
	if bool(result.get("refresh_ui", false)):
		refresh_godmode_ui()
	if bool(result.get("queue_redraw", false)):
		queue_redraw_callback.call()


func _on_time_backward_requested() -> void:
	time_manager.sun_cycle.set_hour(time_manager.sun_cycle.get_current_hour() - 1)
	update_time_hud()
	refresh_godmode_ui()
	queue_redraw_callback.call()


func _on_sun_cycle_hour_changed(new_hour: int) -> void:
	print("[SunCycle] hour changed: %d" % new_hour)
	update_time_hud()


func _on_sun_cycle_sun_room_changed(new_room_index: int) -> void:
	var current_room_index: int = get_current_room_index_callback.call()
	var sun_visual_position_text: String = "offscreen"
	if world_draw_controller.is_sun_visual_in_current_room(time_manager, current_room_index):
		sun_visual_position_text = str(
			world_draw_controller.get_sun_visual_world_position(
				get_room_world_rect_callback.call(),
				get_current_room_surface_cell_y_callback.call()
			)
		)
	print(time_debug_controller.format_sun_room_changed_message(
		new_room_index,
		sun_visual_position_text,
		current_room_index
	))


func _on_room_time_state_changed(room_index: int, old_state: int, new_state: int) -> void:
	print(time_debug_controller.format_room_time_state_changed_message(time_manager, room_index, old_state, new_state))
	if room_index == get_current_room_index_callback.call():
		print(time_debug_controller.format_player_room_time_state_message(time_manager, new_state))
		start_background_fade_callback.call(time_manager.get_room_light_color(room_index), "room time state changed")
		update_time_hud()


func _set_debug_overlay_enabled(is_enabled: bool) -> void:
	set_debug_enabled_callback.call(is_enabled)
