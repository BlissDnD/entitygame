class_name PlanetSunCycle
extends RefCounted

signal hour_changed(new_hour)
signal sun_room_changed(new_room_index)
signal room_time_state_changed(room_index, old_state, new_state)

const CycleInfluenceClass = preload("res://systems/time/cycle_influence.gd")

enum RoomTimeState {
	DAY,
	DUSK,
	NIGHT,
	DAWN,
}

const DEFAULT_HOUR_DURATION_SECONDS: float = 60.0
const DAY_BAND_SIZE: int = 8
const DUSK_BAND_SIZE: int = 4
const NIGHT_BAND_SIZE: int = 8
const DAWN_BAND_SIZE: int = 4
const DAY_COLOR: Color = Color(0.55, 0.78, 1.0, 1.0)
const DUSK_COLOR: Color = Color(0.92, 0.32, 0.14, 1.0)
const NIGHT_COLOR: Color = Color(0.0, 0.0, 0.0, 1.0)
const DAWN_COLOR: Color = Color(1.0, 0.67, 0.25, 1.0)

var room_count: int = 24
var hour_duration_seconds: float = DEFAULT_HOUR_DURATION_SECONDS
var current_time_minutes: float = 0.0
var current_hour: int = 0
var active_influences: Array[CycleInfluence] = []
var room_time_state_cache: Array[int] = []
var start_sun_room_index: int = 0

var sun_influence: CycleInfluence = null


func configure(next_room_count: int, next_hour_duration_seconds: float = DEFAULT_HOUR_DURATION_SECONDS) -> void:
	room_count = maxi(next_room_count, 1)
	hour_duration_seconds = maxf(next_hour_duration_seconds, 0.01)
	current_time_minutes = 0.0
	current_hour = 0
	start_sun_room_index = int(room_count / 2)
	active_influences.clear()
	room_time_state_cache.clear()

	sun_influence = CycleInfluenceClass.new()
	sun_influence.id = &"sun"
	sun_influence.influence_type = CycleInfluenceClass.InfluenceType.SUN
	sun_influence.influence_radius = DAY_BAND_SIZE
	sun_influence.day_band_size = DAY_BAND_SIZE
	sun_influence.movement_direction = 1
	sun_influence.movement_speed_hours = 1.0
	sun_influence.move_to_room(start_sun_room_index, room_count)
	active_influences.append(sun_influence)

	_recalculate_room_time_states(false)
	print("[SunCycle] current hour %d sun room %d; 12 AM start uses midpoint room index %d" % [current_hour, get_sun_room_index(), start_sun_room_index])


func advance(delta: float) -> bool:
	if room_count <= 0:
		return false

	var minutes_per_second: float = 60.0 / hour_duration_seconds
	current_time_minutes = fposmod(current_time_minutes + (delta * minutes_per_second), float(room_count) * 60.0)
	var next_hour: int = int(floor(current_time_minutes / 60.0)) % room_count
	if next_hour == current_hour:
		return false

	current_hour = next_hour
	hour_changed.emit(current_hour)
	_update_sun_room_from_hour()
	_recalculate_room_time_states(false)
	print("[SunCycle] current hour %d sun room %d" % [current_hour, get_sun_room_index()])
	return true


func set_hour(hour: int, force_refresh: bool = false) -> void:
	if room_count <= 0:
		return

	var next_hour: int = posmod(hour, room_count)
	if next_hour == current_hour and not force_refresh:
		return

	current_hour = next_hour
	current_time_minutes = float(current_hour) * 60.0

	hour_changed.emit(current_hour)
	_update_sun_room_from_hour()
	_recalculate_room_time_states(force_refresh)

	print("[SunCycle] current hour %d sun room %d" % [
		current_hour,
		get_sun_room_index()
	])


func advance_one_hour() -> void:
	set_hour(current_hour + 1)


func rewind_one_hour() -> void:
	set_hour(current_hour - 1)


func reset_to_midnight() -> void:
	set_hour(0, true)


func get_current_hour() -> int:
	return current_hour


func get_sun_room_index() -> int:
	if sun_influence == null:
		return 0

	return sun_influence.current_room_index


func get_sun_visual_room_position() -> float:
	var hour_progress: float = current_time_minutes / 60.0
	return fposmod(float(start_sun_room_index) + hour_progress, float(room_count))


func get_room_time_state(room_index: int) -> int:
	if room_time_state_cache.is_empty():
		return RoomTimeState.DAY

	return room_time_state_cache[posmod(room_index, room_time_state_cache.size())]


func get_room_time_state_name(room_index: int) -> String:
	return get_time_state_name(get_room_time_state(room_index))


func get_room_light_color(room_index: int) -> Color:
	match get_room_time_state(room_index):
		RoomTimeState.DAY:
			return DAY_COLOR
		RoomTimeState.DUSK:
			return DUSK_COLOR
		RoomTimeState.NIGHT:
			return NIGHT_COLOR
		RoomTimeState.DAWN:
			return DAWN_COLOR
		_:
			return DAY_COLOR


func is_room_day(room_index: int) -> bool:
	return get_room_time_state(room_index) == RoomTimeState.DAY


func is_room_night(room_index: int) -> bool:
	return get_room_time_state(room_index) == RoomTimeState.NIGHT


func get_time_state_name(time_state: int) -> String:
	match time_state:
		RoomTimeState.DAY:
			return "DAY"
		RoomTimeState.DUSK:
			return "DUSK"
		RoomTimeState.NIGHT:
			return "NIGHT"
		RoomTimeState.DAWN:
			return "DAWN"
		_:
			return "UNKNOWN"


func _update_sun_room_from_hour() -> void:
	if sun_influence == null:
		return

	var previous_room_index: int = sun_influence.current_room_index
	sun_influence.move_to_room(start_sun_room_index + (current_hour * sun_influence.movement_direction), room_count)
	if sun_influence.current_room_index != previous_room_index:
		sun_room_changed.emit(sun_influence.current_room_index)


func _recalculate_room_time_states(force_emit: bool) -> void:
	if room_time_state_cache.size() != room_count:
		room_time_state_cache.resize(room_count)
		for room_index in range(room_count):
			room_time_state_cache[room_index] = RoomTimeState.DAY

	for room_index in range(room_count):
		var old_state: int = room_time_state_cache[room_index]
		var new_state: int = _resolve_room_time_state(room_index)
		room_time_state_cache[room_index] = new_state
		if force_emit or old_state != new_state:
			room_time_state_changed.emit(room_index, old_state, new_state)


func _resolve_room_time_state(room_index: int) -> int:
	var sun_room_index: int = get_sun_room_index()
	var offset_from_sun: int = _get_signed_room_offset(room_index, sun_room_index)

	# Directional meaning:
	# - The sun moves left to right by increasing room index.
	# - DAY is centered on the sun. With an even 8-room band, that means offsets -3..+4.
	# - Positive offsets are ahead of the moving sun, so they become DAWN before DAY.
	# - Negative offsets are behind the moving sun, so they become DUSK after DAY.
	if offset_from_sun >= -3 and offset_from_sun <= 4:
		return RoomTimeState.DAY
	if offset_from_sun >= -7 and offset_from_sun <= -4:
		return RoomTimeState.DUSK
	if offset_from_sun >= 5 and offset_from_sun <= 8:
		return RoomTimeState.DAWN

	return RoomTimeState.NIGHT


func _get_signed_room_offset(room_index: int, center_room_index: int) -> int:
	var half_room_count: int = int(room_count / 2)
	return posmod(room_index - center_room_index + half_room_count, room_count) - half_room_count
