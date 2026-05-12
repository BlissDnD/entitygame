class_name WorldLawDebugFormatter
extends RefCounted


func format_entity(entity_data: WorldLawEntityData) -> String:
	if entity_data == null:
		return "WorldLawEntityData <null>"

	var lines: PackedStringArray = PackedStringArray()
	lines.append("identity: %s" % entity_data.identity)
	lines.append("properties: %s" % _format_dictionary(entity_data.properties))
	lines.append("visible_conditions: %s" % _format_string_name_array(entity_data.list_visible_conditions()))
	lines.append("hidden_conditions: %s" % _format_string_name_array(entity_data.list_hidden_conditions()))
	lines.append("temporary_states: %s" % _format_temporary_states(entity_data))
	lines.append("lifecycle: %s" % _format_lifecycle(entity_data))
	lines.append("fates: %s" % _format_fates(entity_data))
	return "\n".join(lines)


func _format_dictionary(dictionary: Dictionary) -> String:
	if dictionary.is_empty():
		return "{}"

	var parts: PackedStringArray = PackedStringArray()
	var keys: Array = dictionary.keys()
	keys.sort()
	for key in keys:
		parts.append("%s=%s" % [key, dictionary[key]])

	return "{%s}" % ", ".join(parts)


func _format_string_name_array(values: Array[StringName]) -> String:
	if values.is_empty():
		return "[]"

	var parts: PackedStringArray = PackedStringArray()
	for value in values:
		parts.append(String(value))
	return "[%s]" % ", ".join(parts)


func _format_temporary_states(entity_data: WorldLawEntityData) -> String:
	if entity_data.temporary_states.is_empty():
		return "[]"

	var parts: PackedStringArray = PackedStringArray()
	var state_ids: Array = entity_data.temporary_states.keys()
	state_ids.sort()
	for state_id in state_ids:
		var temporary_state: TemporaryStateData = entity_data.temporary_states[state_id]
		parts.append("%s %.1fs/%.1fs intensity %.2f" % [
			temporary_state.id,
			temporary_state.elapsed_time,
			temporary_state.duration,
			temporary_state.intensity,
		])

	return "[%s]" % ", ".join(parts)


func _format_lifecycle(entity_data: WorldLawEntityData) -> String:
	if entity_data.lifecycle_data == null:
		return "none"

	var lifecycle_data: LifecycleData = entity_data.lifecycle_data
	return "stage=%s terminal=%s age=%.1f lifespan=%.1f valid=%s" % [
		lifecycle_data.current_stage,
		lifecycle_data.terminal_stage,
		lifecycle_data.age,
		lifecycle_data.lifespan,
		str(lifecycle_data.validate().is_empty()),
	]


func _format_fates(entity_data: WorldLawEntityData) -> String:
	if entity_data.fates.is_empty():
		return "[]"

	var parts: PackedStringArray = PackedStringArray()
	for fate_data in entity_data.fates:
		parts.append("%s fulfilled=%s" % [fate_data.id, str(fate_data.has_been_fulfilled)])

	return "[%s]" % ", ".join(parts)
