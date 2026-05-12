class_name WorldLawEvaluator
extends RefCounted

var evaluation_queue: Array[WorldLawEntityData] = []
var queued_entity_ids: Dictionary = {}


func queue_entity(entity_data: WorldLawEntityData) -> void:
	if entity_data == null:
		return

	var entity_id: int = entity_data.get_instance_id()
	if queued_entity_ids.has(entity_id):
		return

	entity_data.is_dirty = true
	queued_entity_ids[entity_id] = true
	evaluation_queue.append(entity_data)


func queue_if_dirty(entity_data: WorldLawEntityData) -> void:
	if entity_data != null and entity_data.is_dirty:
		queue_entity(entity_data)


func evaluate_queued(delta: float = 0.0) -> Array[WorldLawEntityData]:
	var changed_entities: Array[WorldLawEntityData] = []
	var queued_entities: Array[WorldLawEntityData] = []
	queued_entities.append_array(evaluation_queue)
	evaluation_queue.clear()
	queued_entity_ids.clear()

	for entity_data in queued_entities:
		if entity_data == null:
			continue

		var changed: bool = false
		if delta > 0.0:
			changed = entity_data.tick_temporary_states(delta) or changed
		changed = entity_data.evaluate_fates() or changed
		if entity_data.is_dirty or changed:
			changed_entities.append(entity_data)
		entity_data.clear_dirty()

	return changed_entities


func has_queued_entities() -> bool:
	return not evaluation_queue.is_empty()
