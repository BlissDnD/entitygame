class_name AtlasWorkerSpawnPoint
extends Node2D

signal group_activated(spawn_point, workers)

@export var npc_scene: PackedScene = preload("res://entity/npc/atlas_worker/atlas_worker.tscn")
@export var spawn_count: int = 3
@export var spawn_radius: float = 22.0
@export var spawn_on_ready: bool = true

var player_target: Node2D = null
var spawned_workers: Array[AtlasWorker] = []
var is_group_activated: bool = false


func _ready() -> void:
	if spawn_on_ready:
		spawn_group()


func set_player_target(next_player_target: Node2D) -> void:
	player_target = next_player_target


func spawn_group() -> Array[AtlasWorker]:
	if npc_scene == null:
		return spawned_workers
	if not spawned_workers.is_empty():
		return spawned_workers

	for index in range(spawn_count):
		var worker_node: Node = npc_scene.instantiate()
		add_child(worker_node)
		if not worker_node is AtlasWorker:
			continue

		var worker: AtlasWorker = worker_node
		worker.global_position = global_position + _get_spawn_offset(index)
		var follow_target: Node2D = player_target
		if index > 0 and index - 1 < spawned_workers.size():
			follow_target = spawned_workers[index - 1]
		worker.configure_worker(index, player_target, follow_target)
		worker.group_activation_requested.connect(_activate_group)
		spawned_workers.append(worker)

	print("spawned %d AtlasWorkers at spawn point %s" % [spawned_workers.size(), global_position])
	_assign_follow_chain()
	return spawned_workers


func _assign_follow_chain() -> void:
	for index in range(spawned_workers.size()):
		var worker: AtlasWorker = spawned_workers[index]
		if index == 0:
			worker.follow_target = player_target
		else:
			worker.follow_target = spawned_workers[index - 1]

	print("worker follow chain assigned")


func _activate_group() -> void:
	if is_group_activated:
		return

	is_group_activated = true
	for worker in spawned_workers:
		worker.activate_group()

	print("AtlasWorker group activated")
	group_activated.emit(self, spawned_workers)


func _get_spawn_offset(index: int) -> Vector2:
	var angle: float = (TAU / float(maxi(spawn_count, 1))) * float(index)
	var radius: float = spawn_radius * (0.45 + (0.18 * float(index)))
	return Vector2(cos(angle), sin(angle)) * radius
