extends Node


@export var initial_level_scene: PackedScene

@onready var ui: Control = $ui
@onready var world: Node2D = $world

var active_level: Node = null
var active_level_ui_nodes: Array[Node] = []


func _ready() -> void:
	if initial_level_scene != null:
		load_level(initial_level_scene)


func load_level(level_scene: PackedScene) -> Node:
	clear_level()

	if level_scene == null:
		return null

	active_level = level_scene.instantiate()
	world.add_child(active_level)
	call_deferred("_mount_level_ui", active_level)
	return active_level


func clear_level() -> void:
	for ui_node in active_level_ui_nodes:
		if is_instance_valid(ui_node):
			ui_node.queue_free()
	active_level_ui_nodes.clear()

	if active_level == null:
		return
	active_level.queue_free()
	active_level = null


func _mount_level_ui(level_root: Node) -> void:
	if level_root == null:
		return

	for node_name in ["console_layer", "UIRoot"]:
		var ui_node: Node = level_root.get_node_or_null(node_name)
		if ui_node == null:
			continue
		var current_parent: Node = ui_node.get_parent()
		if current_parent != null:
			current_parent.remove_child(ui_node)
		ui.add_child(ui_node)
		active_level_ui_nodes.append(ui_node)
