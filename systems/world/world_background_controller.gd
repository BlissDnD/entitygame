class_name WorldBackgroundController
extends RefCounted

var fade_duration: float = 1.4
var background_start_color: Color = Color(0.07, 0.08, 0.1, 1.0)
var background_current_color: Color = Color(0.07, 0.08, 0.1, 1.0)
var background_target_color: Color = Color(0.07, 0.08, 0.1, 1.0)
var background_fade_elapsed: float = fade_duration
var fade_state_name: String = ""


func configure(next_fade_duration: float) -> void:
	fade_duration = maxf(next_fade_duration, 0.001)
	background_fade_elapsed = fade_duration


func update(delta: float) -> bool:
	if background_fade_elapsed >= fade_duration:
		return false

	background_fade_elapsed = minf(background_fade_elapsed + delta, fade_duration)
	var fade_t: float = background_fade_elapsed / fade_duration
	background_current_color = background_start_color.lerp(background_target_color, fade_t)
	if background_fade_elapsed >= fade_duration:
		background_current_color = background_target_color
		print("[SunCycle] background fade completed: %s" % fade_state_name)

	return true


func start_fade(next_color: Color, reason: String, state_name: String = "") -> void:
	if background_target_color == next_color and background_fade_elapsed < fade_duration:
		return

	background_start_color = background_current_color
	background_target_color = next_color
	background_fade_elapsed = 0.0
	fade_state_name = state_name
	print("[SunCycle] background fade started (%s): %s" % [reason, fade_state_name])


func set_color_immediate(next_color: Color) -> void:
	background_start_color = next_color
	background_current_color = next_color
	background_target_color = next_color
	background_fade_elapsed = fade_duration


func get_current_color() -> Color:
	return background_current_color


func get_target_color() -> Color:
	return background_target_color


func is_fading() -> bool:
	return background_fade_elapsed < fade_duration
