class_name GodModePanel
extends Panel

signal mining_power_changed(value: float)
signal mining_radius_changed(value: int)
signal mining_shape_changed(shape: int)
signal equip_tool_requested
signal unequip_tool_requested
signal equip_backpack_requested
signal unequip_backpack_requested
signal add_stone_requested
signal add_scrap_requested
signal print_equipment_requested
signal print_backpack_requested
signal gravity_field_mode_requested
signal gravity_point_mode_requested
signal gravity_strength_selected(level_index: int)
signal time_forward_requested
signal time_backward_requested

var square_shape_value: int = 0
var circle_shape_value: int = 1
var is_refreshing: bool = false

@onready var mining_power_slider: HSlider = $mining_power_slider
@onready var mining_power_value: Label = $mining_power_value
@onready var mining_radius_slider: HSlider = $mining_radius_slider
@onready var mining_radius_value: Label = $mining_radius_value
@onready var square_button: Button = $square_button
@onready var circle_button: Button = $circle_button
@onready var selected_material_value: Label = $selected_material_value
@onready var inventory_value: Label = $inventory_value
@onready var material_counts_value: Label = $material_counts_value
@onready var placement_value: Label = $placement_value
@onready var build_mode_value: Label = $build_mode_value
@onready var gravity_status_value: Label = $gravity_status_value
@onready var gravity_strength_popup: Panel = $gravity_strength_popup
@onready var equipment_status_value: Label = $equipment_status_value
@onready var backpack_contents_value: Label = $backpack_contents_value
@onready var sun_cycle_status_value: Label = $sun_cycle_status_value
@onready var world_laws_status_value: Label = $world_laws_status_value


func set_visible_state(enabled: bool) -> void:
	visible = enabled


func refresh(snapshot: Dictionary) -> void:
	is_refreshing = true
	square_shape_value = int(snapshot.get("square_shape", square_shape_value))
	circle_shape_value = int(snapshot.get("circle_shape", circle_shape_value))

	mining_power_slider.min_value = float(snapshot.get("mining_power_min", mining_power_slider.min_value))
	mining_power_slider.max_value = float(snapshot.get("mining_power_max", mining_power_slider.max_value))
	mining_radius_slider.min_value = float(snapshot.get("mining_radius_min", mining_radius_slider.min_value))
	mining_radius_slider.max_value = float(snapshot.get("mining_radius_max", mining_radius_slider.max_value))

	var mining_power: float = float(snapshot.get("mining_power", mining_power_slider.value))
	var mining_radius: int = int(snapshot.get("mining_radius", int(mining_radius_slider.value)))
	var mining_shape: int = int(snapshot.get("mining_shape", square_shape_value))

	mining_power_slider.value = mining_power
	mining_power_value.text = "Mining %d" % int(round(mining_power))
	mining_radius_slider.value = mining_radius
	mining_radius_value.text = "Size %d" % mining_radius
	square_button.button_pressed = mining_shape == square_shape_value
	circle_button.button_pressed = mining_shape == circle_shape_value

	selected_material_value.text = String(snapshot.get("selected_material_text", "Selected -"))
	inventory_value.text = String(snapshot.get("inventory_text", "Inventory -"))
	material_counts_value.text = String(snapshot.get("material_counts_text", "Materials -"))
	placement_value.text = String(snapshot.get("placement_text", "Placement -"))
	build_mode_value.text = String(snapshot.get("build_mode_text", "Mode NONE"))
	gravity_status_value.text = String(snapshot.get("gravity_text", "Gravity fields 0"))
	equipment_status_value.text = String(snapshot.get("equipment_text", "Equipment -"))
	backpack_contents_value.text = String(snapshot.get("backpack_text", "Bag: -"))
	sun_cycle_status_value.text = String(snapshot.get("current_time_text", snapshot.get("sun_cycle_text", "Time -")))
	world_laws_status_value.text = String(snapshot.get("world_laws_text", "World Laws: not implemented yet"))
	is_refreshing = false


func _on_mining_power_slider_value_changed(value: float) -> void:
	if is_refreshing:
		return
	mining_power_changed.emit(value)


func _on_mining_radius_slider_value_changed(value: float) -> void:
	if is_refreshing:
		return
	mining_radius_changed.emit(int(round(value)))


func _on_square_button_pressed() -> void:
	if is_refreshing:
		return
	mining_shape_changed.emit(square_shape_value)


func _on_circle_button_pressed() -> void:
	if is_refreshing:
		return
	mining_shape_changed.emit(circle_shape_value)


func _on_equip_tool_button_pressed() -> void:
	equip_tool_requested.emit()


func _on_unequip_tool_button_pressed() -> void:
	unequip_tool_requested.emit()


func _on_equip_backpack_button_pressed() -> void:
	equip_backpack_requested.emit()


func _on_unequip_backpack_button_pressed() -> void:
	unequip_backpack_requested.emit()


func _on_add_stone_button_pressed() -> void:
	add_stone_requested.emit()


func _on_add_scrap_button_pressed() -> void:
	add_scrap_requested.emit()


func _on_print_equipment_button_pressed() -> void:
	print_equipment_requested.emit()


func _on_print_backpack_button_pressed() -> void:
	print_backpack_requested.emit()


func _on_gravity_field_button_pressed() -> void:
	gravity_field_mode_requested.emit()


func _on_gravity_point_button_pressed() -> void:
	gravity_point_mode_requested.emit()


func show_gravity_strength_popup() -> void:
	gravity_strength_popup.visible = true


func hide_gravity_strength_popup() -> void:
	gravity_strength_popup.visible = false


func _select_gravity_strength(level_index: int) -> void:
	gravity_strength_selected.emit(level_index)
	hide_gravity_strength_popup()


func _on_gravity_strength_1_button_pressed() -> void:
	_select_gravity_strength(0)


func _on_gravity_strength_2_button_pressed() -> void:
	_select_gravity_strength(1)


func _on_gravity_strength_3_button_pressed() -> void:
	_select_gravity_strength(2)


func _on_gravity_strength_4_button_pressed() -> void:
	_select_gravity_strength(3)


func _on_gravity_strength_5_button_pressed() -> void:
	_select_gravity_strength(4)


func _on_time_forward_button_pressed() -> void:
	time_forward_requested.emit()


func _on_time_backward_button_pressed() -> void:
	time_backward_requested.emit()
