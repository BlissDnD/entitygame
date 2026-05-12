class_name FateData
extends RefCounted

var id: StringName = &""
var required_visible_conditions: Array[StringName] = []
var required_hidden_conditions: Array[StringName] = []
var required_any_conditions: Array[StringName] = []
var property_minimums: Dictionary = {}
var property_maximums: Dictionary = {}
var effect_definitions: Array[Dictionary] = []
var has_been_fulfilled: bool = false


func is_fulfilled(entity_data) -> bool:
	for condition_id in required_visible_conditions:
		if not entity_data.has_visible_condition(condition_id):
			return false
	for condition_id in required_hidden_conditions:
		if not entity_data.has_hidden_condition(condition_id):
			return false
	for condition_id in required_any_conditions:
		if not entity_data.has_condition(condition_id):
			return false
	for property_id in property_minimums.keys():
		if float(entity_data.get_property(StringName(property_id), 0.0)) < float(property_minimums[property_id]):
			return false
	for property_id in property_maximums.keys():
		if float(entity_data.get_property(StringName(property_id), 0.0)) > float(property_maximums[property_id]):
			return false

	return true


func apply_effects(entity_data) -> bool:
	if has_been_fulfilled:
		return false
	if not is_fulfilled(entity_data):
		return false

	for effect_definition in effect_definitions:
		entity_data.apply_effect(effect_definition)
	has_been_fulfilled = true
	return true


func add_effect(effect_definition: Dictionary) -> void:
	effect_definitions.append(effect_definition.duplicate(true))
