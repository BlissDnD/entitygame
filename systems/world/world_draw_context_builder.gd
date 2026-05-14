class_name WorldDrawContextBuilder
extends RefCounted


func build_context(base: Dictionary, overrides: Dictionary = {}) -> Dictionary:
	var context: Dictionary = base.duplicate()
	for key in overrides.keys():
		context[key] = overrides[key]
	return context
