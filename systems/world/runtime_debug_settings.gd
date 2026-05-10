class_name RuntimeDebugSettings
extends RefCounted

const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")

var mining_power: float = GameplayTuningClass.GODMODE_DEFAULT_MINING_POWER
var mining_shape: int = GameplayTuningClass.GODMODE_DEFAULT_SHAPE
var mining_radius: int = GameplayTuningClass.GODMODE_DEFAULT_RADIUS
var godmode_enabled: bool = GameplayTuningClass.GODMODE_DEFAULT_ENABLED


func apply_tool_profile(tool_profile: Dictionary) -> void:
	set_mining_power(float(tool_profile.get("mining_power", GameplayTuningClass.GODMODE_DEFAULT_MINING_POWER)))
	set_mining_shape(int(tool_profile.get("mining_shape", GameplayTuningClass.GODMODE_DEFAULT_SHAPE)))
	set_mining_radius(int(tool_profile.get("mining_radius", GameplayTuningClass.GODMODE_DEFAULT_RADIUS)))


func set_mining_power(value: float) -> void:
	mining_power = clampf(value, GameplayTuningClass.MINING_POWER_MIN, GameplayTuningClass.MINING_POWER_MAX)


func set_mining_shape(value: int) -> void:
	if value == GameplayTuningClass.WorldConstantsClass.ToolShape.CIRCLE:
		mining_shape = GameplayTuningClass.WorldConstantsClass.ToolShape.CIRCLE
		return

	mining_shape = GameplayTuningClass.WorldConstantsClass.ToolShape.SQUARE


func set_mining_radius(value: int) -> void:
	mining_radius = clampi(value, GameplayTuningClass.MINING_RADIUS_MIN, GameplayTuningClass.MINING_RADIUS_MAX)


func set_godmode_enabled(value: bool) -> void:
	godmode_enabled = value
