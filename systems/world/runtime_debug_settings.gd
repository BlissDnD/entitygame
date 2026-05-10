class_name RuntimeDebugSettings
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")

const MINING_POWER_MIN := 1.0
const MINING_POWER_MAX := 100.0
const MINING_RADIUS_MIN := 1
const MINING_RADIUS_MAX := 10

var mining_power: float = 10.0
var mining_shape: int = WorldConstantsClass.ToolShape.SQUARE
var mining_radius: int = 2
var godmode_enabled: bool = false


func apply_tool_profile(tool_profile: Dictionary) -> void:
	set_mining_power(float(tool_profile.get("mining_power", mining_power)))
	set_mining_shape(int(tool_profile.get("mining_shape", mining_shape)))
	set_mining_radius(int(tool_profile.get("mining_radius", mining_radius)))


func set_mining_power(value: float) -> void:
	mining_power = clampf(value, MINING_POWER_MIN, MINING_POWER_MAX)


func set_mining_shape(value: int) -> void:
	if value == WorldConstantsClass.ToolShape.CIRCLE:
		mining_shape = WorldConstantsClass.ToolShape.CIRCLE
		return

	mining_shape = WorldConstantsClass.ToolShape.SQUARE


func set_mining_radius(value: int) -> void:
	mining_radius = clampi(value, MINING_RADIUS_MIN, MINING_RADIUS_MAX)


func set_godmode_enabled(value: bool) -> void:
	godmode_enabled = value
