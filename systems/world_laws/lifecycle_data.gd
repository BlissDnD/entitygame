class_name LifecycleData
extends RefCounted

var has_lifespan: bool = false
var current_stage: StringName = &""
var stages: Array[StringName] = []
var terminal_stage: StringName = &""
var age: float = 0.0
var lifespan: float = 0.0
var milestone_definitions: Dictionary = {}


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if not has_lifespan:
		return errors
	if stages.is_empty():
		errors.append("lifespan entity requires lifecycle stages")
	if terminal_stage == &"":
		errors.append("lifespan entity requires terminal_stage")
	elif not stages.has(terminal_stage):
		errors.append("terminal_stage must exist in lifecycle stages")
	if current_stage == &"":
		errors.append("lifespan entity requires current_stage")
	elif not stages.has(current_stage):
		errors.append("current_stage must exist in lifecycle stages")
	return errors


func set_stage(next_stage: StringName) -> bool:
	if not stages.has(next_stage):
		return false

	current_stage = next_stage
	return true


func advance_age(delta: float) -> void:
	age = maxf(age + delta, 0.0)


func is_terminal() -> bool:
	return has_lifespan and current_stage == terminal_stage
