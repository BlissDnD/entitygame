class_name StatsComponent
extends Node

signal stat_changed(stat_name: StringName, value: float)

const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")

@export var move_speed: float = GameplayTuningClass.PLAYER_MOVE_SPEED
@export var gravity: float = GameplayTuningClass.PLAYER_GRAVITY
@export var jump_velocity: float = GameplayTuningClass.PLAYER_JUMP_VELOCITY
@export var max_health: float = 100.0
@export var current_health: float = 100.0


func set_stat(stat_name: StringName, value: float) -> void:
	match stat_name:
		&"move_speed":
			move_speed = value
		&"gravity":
			gravity = value
		&"jump_velocity":
			jump_velocity = value
		&"max_health":
			max_health = value
		&"current_health":
			current_health = clampf(value, 0.0, max_health)
		_:
			return

	stat_changed.emit(stat_name, value)
