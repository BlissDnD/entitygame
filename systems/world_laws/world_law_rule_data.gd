class_name WorldLawRuleData
extends RefCounted

var id: StringName = &""
var description: String = ""
var enabled: bool = true
var trigger_definition: Dictionary = {}
var effect_definitions: Array[Dictionary] = []


func _init(next_id: StringName = &"", next_description: String = "") -> void:
	id = next_id
	description = next_description


func add_effect(effect_definition: Dictionary) -> void:
	effect_definitions.append(effect_definition.duplicate(true))
