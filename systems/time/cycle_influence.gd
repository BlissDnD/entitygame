class_name CycleInfluence
extends RefCounted

enum InfluenceType {
	SUN,
	MOON,
	SPECIAL,
	EVENT,
}

var id: StringName = &""
var influence_type: InfluenceType = InfluenceType.SPECIAL
var current_room_index: int = 0
var influence_radius: int = 0
var day_band_size: int = 0
var movement_direction: int = 1
var movement_speed_hours: float = 1.0
var active_states: Array[int] = []
var color_tint: Color = Color.WHITE
var priority: int = 0


func move_to_room(room_index: int, room_count: int) -> void:
	current_room_index = posmod(room_index, maxi(room_count, 1))
