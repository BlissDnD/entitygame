class_name ConditionData
extends RefCounted

var id: StringName = &""
var is_hidden: bool = false
var metadata: Dictionary = {}


func _init(next_id: StringName = &"", next_is_hidden: bool = false, next_metadata: Dictionary = {}) -> void:
	id = next_id
	is_hidden = next_is_hidden
	metadata = next_metadata.duplicate(true)


func duplicate_condition() -> ConditionData:
	return ConditionData.new(id, is_hidden, metadata)
