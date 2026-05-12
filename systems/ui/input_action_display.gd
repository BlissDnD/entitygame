class_name InputActionDisplay
extends RefCounted


static func get_action_label(action_name: StringName) -> String:
	var labels: Array[String] = get_action_labels(action_name)
	if labels.is_empty():
		return String(action_name)
	return " / ".join(PackedStringArray(labels))


static func get_action_labels(action_name: StringName) -> Array[String]:
	var labels: Array[String] = []
	if not InputMap.has_action(action_name):
		return labels

	for event in InputMap.action_get_events(action_name):
		var label: String = _format_event(event)
		if label.is_empty():
			continue
		if not labels.has(label):
			labels.append(label)

	return labels


static func _format_event(event: InputEvent) -> String:
	if event == null:
		return ""

	var event_text: String = event.as_text().strip_edges()
	if event_text.is_empty():
		return ""

	event_text = event_text.replace("(Physical)", "")
	event_text = event_text.replace("Keycode", "")
	event_text = event_text.replace("Mouse Button", "Mouse")
	return event_text.strip_edges()
