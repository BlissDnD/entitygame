class_name WorldRuntime
extends RefCounted

const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")
const WorldDataClass = preload("res://systems/world/world_data.gd")
const WorldRendererClass = preload("res://systems/world/world_renderer.gd")
const RuntimeDebugSettingsClass = preload("res://systems/world/runtime_debug_settings.gd")
const MiningRuntimeClass = preload("res://systems/mining/mining_runtime.gd")
const ItemDropDataClass = preload("res://systems/items/item_drop_data.gd")
const InventoryDataClass = preload("res://systems/inventory/inventory_data.gd")
const InventoryRuntimeClass = preload("res://systems/inventory/inventory_runtime.gd")
const PlayerEquipmentClass = preload("res://systems/equipment/player_equipment.gd")
const BackpackContainerClass = preload("res://systems/backpack/backpack_container.gd")
const PlayerCursorControllerClass = preload("res://systems/cursor/player_cursor_controller.gd")
const GravityFieldSystemClass = preload("res://systems/world/gravity_field_system.gd")
const BuildModeRuntimeClass = preload("res://systems/build/build_mode_runtime.gd")

var debug_settings = RuntimeDebugSettingsClass.new()
var world_data = WorldDataClass.new()
var world_renderer = WorldRendererClass.new(world_data)
var mining_runtime = MiningRuntimeClass.new()
var item_drop_data = ItemDropDataClass.new()
var inventory_data = InventoryDataClass.new(
	GameplayTuningClass.INVENTORY_CAPACITY,
	GameplayTuningClass.INVENTORY_WEIGHT_CAPACITY
)
var player_equipment = PlayerEquipmentClass.new()
var backpack_container = BackpackContainerClass.new()
var inventory_runtime = InventoryRuntimeClass.new(inventory_data, player_equipment, backpack_container)
var player_cursor_controller = PlayerCursorControllerClass.new()
var gravity_field_system: GravityFieldSystem = GravityFieldSystemClass.new()
var build_mode_runtime = BuildModeRuntimeClass.new(gravity_field_system)

var player_world_position: Vector2 = GameplayTuningClass.PLAYER_SPAWN_WORLD_POSITION
var player_velocity: Vector2 = Vector2.ZERO
var hovered_cell: Vector2i = Vector2i.ZERO
var mining_center_cell: Vector2i = Vector2i.ZERO
var hovered_drop_index: int = -1
var has_won: bool = false
var room_transition_lock_time: float = 0.0
