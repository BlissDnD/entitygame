class_name WorldSpawnController
extends RefCounted

const WorldUtilsClass = preload("res://systems/world/world_utils.gd")

var spawn_manager: SpawnManager = null
var persistent_followers: Node2D = null
var player_follow_target: Node2D = null
var max_atlas_worker_followers: int = 0
var active_atlas_workers: Array[AtlasWorker] = []


func _init(
	next_spawn_manager: SpawnManager = null,
	next_persistent_followers: Node2D = null,
	next_player_follow_target: Node2D = null,
	next_max_atlas_worker_followers: int = 0
) -> void:
	spawn_manager = next_spawn_manager
	persistent_followers = next_persistent_followers
	player_follow_target = next_player_follow_target
	max_atlas_worker_followers = next_max_atlas_worker_followers


func create_atlas_worker_spawn_point_for_room(
	atlas_worker_spawn_point_scene: PackedScene,
	room_index: int,
	room_size_cells: Vector2i,
	room_npc_container: Node2D,
	surface_edge_margin_cells: int,
	surface_cell_y: int
) -> void:
	if atlas_worker_spawn_point_scene == null or room_npc_container == null or spawn_manager == null:
		return

	var spawn_cell: Vector2i = Vector2i(
		clampi(room_size_cells.x / 2 + (room_index * 9) - 9, surface_edge_margin_cells, room_size_cells.x - surface_edge_margin_cells),
		surface_cell_y - 6
	)
	var spawn_point: Node = spawn_manager.spawn_scene(
		atlas_worker_spawn_point_scene,
		room_npc_container,
		WorldUtilsClass.cell_to_world(spawn_cell),
		&"atlas_worker_spawn_point"
	)
	if not spawn_point is AtlasWorkerSpawnPoint:
		return

	var atlas_spawn_point: AtlasWorkerSpawnPoint = spawn_point
	atlas_spawn_point.set_player_target(player_follow_target)
	atlas_spawn_point.group_activated.connect(_on_atlas_worker_group_activated)
	print("room %d received AtlasWorker spawn point at %s" % [room_index, atlas_spawn_point.global_position])


func update_player_follow_target(player_ground_world: Vector2) -> void:
	if player_follow_target == null:
		return

	player_follow_target.global_position = player_ground_world


func reposition_active_atlas_workers_after_transition(exit_edge: String, player_ground_position: Vector2) -> void:
	if active_atlas_workers.is_empty():
		return

	var direction_sign: float = 1.0
	if exit_edge == "right":
		direction_sign = -1.0

	for index in range(active_atlas_workers.size()):
		var atlas_worker: AtlasWorker = active_atlas_workers[index]
		if atlas_worker == null:
			continue
		atlas_worker.global_position = player_ground_position + Vector2(direction_sign * float(26 + (index * 18)), 0.0)
		atlas_worker.velocity = Vector2.ZERO

	_assign_active_atlas_worker_follow_chain()
	print("AtlasWorkers repositioned after room transition")


func update_active_atlas_worker_grounding(player_ground_world: Vector2, cell_height: float) -> void:
	for atlas_worker in active_atlas_workers:
		if atlas_worker == null:
			continue
		if atlas_worker.global_position.y > player_ground_world.y + cell_height:
			atlas_worker.global_position.y = player_ground_world.y


func _on_atlas_worker_group_activated(_spawn_point, workers: Array) -> void:
	var added_count: int = 0
	var overflow_count: int = 0

	for worker in workers:
		if worker == null or not worker is AtlasWorker:
			continue
		var atlas_worker: AtlasWorker = worker

		if active_atlas_workers.size() >= max_atlas_worker_followers:
			atlas_worker.deactivate_group()
			overflow_count += 1
			continue

		atlas_worker.reparent(persistent_followers, true)
		active_atlas_workers.append(atlas_worker)
		added_count += 1

	if added_count > 0:
		_assign_active_atlas_worker_follow_chain()

	print(
		"AtlasWorker followers updated: added %d, total %d/%d, non-followers left in place %d" % [
			added_count,
			active_atlas_workers.size(),
			max_atlas_worker_followers,
			overflow_count,
		]
	)


func _assign_active_atlas_worker_follow_chain() -> void:
	for index in range(active_atlas_workers.size()):
		var atlas_worker: AtlasWorker = active_atlas_workers[index]
		if atlas_worker == null:
			continue
		if index == 0:
			atlas_worker.follow_target = player_follow_target
		else:
			atlas_worker.follow_target = active_atlas_workers[index - 1]
		atlas_worker.activation_target = player_follow_target
		atlas_worker.activate_group()

	print("persistent AtlasWorker follow chain assigned")
