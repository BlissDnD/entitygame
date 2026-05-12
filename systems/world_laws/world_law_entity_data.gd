class_name WorldLawEntityData
extends RefCounted

const ConditionDataClass = preload("res://systems/world_laws/condition_data.gd")
const TemporaryStateDataClass = preload("res://systems/world_laws/temporary_state_data.gd")
const LifecycleDataClass = preload("res://systems/world_laws/lifecycle_data.gd")

var identity: StringName = &""
var properties: Dictionary = {}
var visible_conditions: Dictionary = {}
var hidden_conditions: Dictionary = {}
var temporary_states: Dictionary = {}
var lifecycle_data: LifecycleData = null
var fates: Array[FateData] = []
var is_dirty: bool = false
var last_change_notes: PackedStringArray = PackedStringArray()


func _init(next_identity: StringName = &"") -> void:
	identity = next_identity


func set_property(property_id: StringName, value) -> void:
	properties[property_id] = value
	mark_dirty("property %s set" % property_id)


func get_property(property_id: StringName, fallback = null):
	return properties.get(property_id, fallback)


func add_visible_condition(condition_id: StringName, metadata: Dictionary = {}) -> bool:
	return _add_condition(condition_id, false, metadata)


func add_hidden_condition(condition_id: StringName, metadata: Dictionary = {}) -> bool:
	return _add_condition(condition_id, true, metadata)


func remove_visible_condition(condition_id: StringName) -> bool:
	if not visible_conditions.has(condition_id):
		return false

	visible_conditions.erase(condition_id)
	mark_dirty("visible condition %s removed" % condition_id)
	return true


func remove_hidden_condition(condition_id: StringName) -> bool:
	if not hidden_conditions.has(condition_id):
		return false

	hidden_conditions.erase(condition_id)
	mark_dirty("hidden condition %s removed" % condition_id)
	return true


func remove_condition(condition_id: StringName) -> bool:
	var removed_visible: bool = remove_visible_condition(condition_id)
	var removed_hidden: bool = remove_hidden_condition(condition_id)
	return removed_visible or removed_hidden


func has_visible_condition(condition_id: StringName) -> bool:
	return visible_conditions.has(condition_id)


func has_hidden_condition(condition_id: StringName) -> bool:
	return hidden_conditions.has(condition_id)


func has_condition(condition_id: StringName) -> bool:
	return has_visible_condition(condition_id) or has_hidden_condition(condition_id)


func list_visible_conditions() -> Array[StringName]:
	return _get_condition_ids(visible_conditions)


func list_hidden_conditions() -> Array[StringName]:
	return _get_condition_ids(hidden_conditions)


func add_temporary_state(temporary_state: TemporaryStateData) -> bool:
	if temporary_state == null or temporary_state.id == &"":
		return false

	temporary_states[temporary_state.id] = temporary_state
	mark_dirty("temporary state %s added" % temporary_state.id)
	return true


func remove_temporary_state(state_id: StringName) -> bool:
	if not temporary_states.has(state_id):
		return false

	temporary_states.erase(state_id)
	mark_dirty("temporary state %s removed" % state_id)
	return true


func has_temporary_state(state_id: StringName) -> bool:
	return temporary_states.has(state_id)


func list_temporary_states() -> Array[StringName]:
	var state_ids: Array[StringName] = []
	for state_id in temporary_states.keys():
		state_ids.append(StringName(state_id))
	state_ids.sort()
	return state_ids


func set_lifecycle_data(next_lifecycle_data: LifecycleData) -> void:
	lifecycle_data = next_lifecycle_data
	mark_dirty("lifecycle data set")


func add_fate(fate_data: FateData) -> void:
	if fate_data == null:
		return

	fates.append(fate_data)
	mark_dirty("fate %s added" % fate_data.id)


func tick_temporary_states(delta: float) -> bool:
	var changed: bool = false
	var expired_state_ids: Array[StringName] = []

	for state_id in temporary_states.keys():
		var temporary_state: TemporaryStateData = temporary_states[state_id]
		if temporary_state.tick(delta):
			for effect_definition in temporary_state.expiration_effects:
				apply_effect(effect_definition)
			expired_state_ids.append(StringName(state_id))
			changed = true

	for state_id in expired_state_ids:
		temporary_states.erase(state_id)
		mark_dirty("temporary state %s expired" % state_id)

	return changed


func evaluate_fates() -> bool:
	var changed: bool = false
	for fate_data in fates:
		if fate_data.apply_effects(self):
			mark_dirty("fate %s fulfilled" % fate_data.id)
			changed = true

	return changed


func apply_effect(effect_definition: Dictionary) -> bool:
	var effect_type: String = String(effect_definition.get("type", ""))
	var condition_id: StringName = StringName(effect_definition.get("condition", &""))

	match effect_type:
		"add_visible_condition":
			return add_visible_condition(condition_id)
		"add_hidden_condition":
			return add_hidden_condition(condition_id)
		"remove_visible_condition":
			return remove_visible_condition(condition_id)
		"remove_hidden_condition":
			return remove_hidden_condition(condition_id)
		"set_property":
			var property_id: StringName = StringName(effect_definition.get("property", &""))
			set_property(property_id, effect_definition.get("value"))
			return true
		"set_lifecycle_stage":
			if lifecycle_data == null:
				return false
			var next_stage: StringName = StringName(effect_definition.get("stage", &""))
			if lifecycle_data.set_stage(next_stage):
				mark_dirty("lifecycle stage set to %s" % next_stage)
				return true
			return false
		_:
			return false


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if identity == &"":
		errors.append("identity is required")
	if lifecycle_data != null:
		errors.append_array(lifecycle_data.validate())
	return errors


func clear_dirty() -> void:
	is_dirty = false
	last_change_notes.clear()


func mark_dirty(change_note: String = "") -> void:
	is_dirty = true
	if change_note != "":
		last_change_notes.append(change_note)


func _add_condition(condition_id: StringName, is_hidden: bool, metadata: Dictionary) -> bool:
	if condition_id == &"":
		return false

	var target_conditions: Dictionary = hidden_conditions if is_hidden else visible_conditions
	if target_conditions.has(condition_id):
		return false

	target_conditions[condition_id] = ConditionDataClass.new(condition_id, is_hidden, metadata)
	mark_dirty("%s condition %s added" % ["hidden" if is_hidden else "visible", condition_id])
	return true


func _get_condition_ids(condition_dictionary: Dictionary) -> Array[StringName]:
	var condition_ids: Array[StringName] = []
	for condition_id in condition_dictionary.keys():
		condition_ids.append(StringName(condition_id))
	condition_ids.sort()
	return condition_ids
