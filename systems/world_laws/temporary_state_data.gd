class_name TemporaryStateData
extends RefCounted

var id: StringName = &""
var duration: float = 0.0
var elapsed_time: float = 0.0
var intensity: float = 1.0
var expiration_effects: Array[Dictionary] = []


func _init(next_id: StringName = &"", next_duration: float = 0.0, next_intensity: float = 1.0) -> void:
	id = next_id
	duration = maxf(next_duration, 0.0)
	intensity = next_intensity


func tick(delta: float) -> bool:
	elapsed_time = minf(elapsed_time + maxf(delta, 0.0), duration)
	return is_expired()


func is_expired() -> bool:
	return duration <= 0.0 or elapsed_time >= duration


func get_remaining_time() -> float:
	return maxf(duration - elapsed_time, 0.0)


func add_expiration_effect(effect_definition: Dictionary) -> void:
	expiration_effects.append(effect_definition.duplicate(true))
