class_name TimeManager
extends Node

signal hour_changed(new_hour)
signal sun_room_changed(new_room_index)
signal room_time_state_changed(room_index, old_state, new_state)
signal day_started(room_index)
signal night_started(room_index)

const PlanetSunCycleClass = preload("res://systems/time/planet_sun_cycle.gd")

var sun_cycle = PlanetSunCycleClass.new()


func configure(room_count: int, hour_duration_seconds: float = PlanetSunCycleClass.DEFAULT_HOUR_DURATION_SECONDS) -> void:
	sun_cycle.hour_changed.connect(_on_hour_changed)
	sun_cycle.sun_room_changed.connect(_on_sun_room_changed)
	sun_cycle.room_time_state_changed.connect(_on_room_time_state_changed)
	sun_cycle.configure(room_count, hour_duration_seconds)


func advance(delta: float) -> bool:
	return sun_cycle.advance(delta)


func advance_one_hour() -> void:
	sun_cycle.advance_one_hour()


func reset_to_midnight() -> void:
	sun_cycle.reset_to_midnight()


func get_current_hour() -> int:
	return sun_cycle.get_current_hour()


func get_sun_room_index() -> int:
	return sun_cycle.get_sun_room_index()


func get_room_time_state_name(room_index: int) -> String:
	return sun_cycle.get_room_time_state_name(room_index)


func get_time_state_name(state: int) -> String:
	return sun_cycle.get_time_state_name(state)


func get_room_light_color(room_index: int) -> Color:
	return sun_cycle.get_room_light_color(room_index)


func _on_hour_changed(new_hour: int) -> void:
	hour_changed.emit(new_hour)


func _on_sun_room_changed(new_room_index: int) -> void:
	sun_room_changed.emit(new_room_index)


func _on_room_time_state_changed(room_index: int, old_state: int, new_state: int) -> void:
	room_time_state_changed.emit(room_index, old_state, new_state)
	var state_name: String = sun_cycle.get_time_state_name(new_state)
	if state_name == "DAY":
		day_started.emit(room_index)
	elif state_name == "NIGHT":
		night_started.emit(room_index)
