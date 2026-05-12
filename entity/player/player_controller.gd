class_name PlayerController
extends CharacterBody2D

signal interacted

@export var equipment_component_path: NodePath = ^"PlayerEquipment"
@export var cursor_controller_path: NodePath = ^"PlayerCursorController"
@export var inventory_component_path: NodePath = ^"InventoryComponent"
@export var stats_component_path: NodePath = ^"StatsComponent"
@export var interaction_component_path: NodePath = ^"InteractionComponent"

@onready var player_equipment: PlayerEquipment = get_node_or_null(equipment_component_path)
@onready var player_cursor_controller: PlayerCursorController = get_node_or_null(cursor_controller_path)
@onready var inventory_component: InventoryComponent = get_node_or_null(inventory_component_path)
@onready var stats_component: StatsComponent = get_node_or_null(stats_component_path)
@onready var interaction_component: InteractionComponent = get_node_or_null(interaction_component_path)


func _ready() -> void:
	if player_cursor_controller != null and player_equipment != null:
		player_cursor_controller.bind_equipment(player_equipment)


func _physics_process(delta: float) -> void:
	var move_speed: float = 260.0
	var gravity: float = 980.0
	var jump_velocity: float = -360.0
	if stats_component != null:
		move_speed = stats_component.move_speed
		gravity = stats_component.gravity
		jump_velocity = stats_component.jump_velocity

	var input_axis: float = Input.get_axis("move_left", "move_right")
	velocity.x = input_axis * move_speed
	velocity.y += gravity * delta

	if Input.is_action_just_pressed("move_up") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

	if Input.is_action_just_pressed("interact"):
		if interaction_component != null and interaction_component.try_interact(self):
			interacted.emit()


func get_player_equipment() -> PlayerEquipment:
	return player_equipment


func get_cursor_controller() -> PlayerCursorController:
	return player_cursor_controller


func get_inventory_component() -> InventoryComponent:
	return inventory_component
