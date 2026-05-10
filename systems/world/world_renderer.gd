class_name WorldRenderer
extends RefCounted

const WorldUtilsClass = preload("res://systems/world/world_utils.gd")
const ChunkRendererClass = preload("res://systems/world/chunk_renderer.gd")

var world_data = null
var chunk_renderer = ChunkRendererClass.new()
var chunk_cache: Dictionary = {}
var render_margin_chunks: int = 2
var profiling_info: Dictionary = {
	"visible_chunk_count": 0,
	"rendered_chunk_count": 0,
	"visible_cell_count": 0,
	"dirty_chunk_count": 0,
	"chunk_rebuild_count": 0,
	"estimated_frame_time_ms": 0.0,
}


func _init(next_world_data = null) -> void:
	world_data = next_world_data


func set_world_data(next_world_data) -> void:
	world_data = next_world_data
	clear_cache()


func clear_cache() -> void:
	chunk_cache.clear()


func draw_visible_chunks(canvas_item: CanvasItem, view_origin: Vector2, view_size: Vector2, draw_origin_world: Vector2 = Vector2.ZERO) -> Dictionary:
	if world_data == null:
		return profiling_info

	var frame_start_usec: int = Time.get_ticks_usec()
	var rebuild_count: int = 0
	var rendered_chunk_count: int = 0
	var visible_cell_count: int = 0
	var view_rect: Rect2 = Rect2(view_origin, view_size)
	var visible_chunk_positions: Array[Vector2i] = get_visible_chunk_positions(view_rect)

	for chunk_position in visible_chunk_positions:
		var chunk_data = world_data.get_chunk(chunk_position)
		if chunk_data == null:
			continue
		var cache_entry: Dictionary = {}
		if chunk_cache.has(chunk_position):
			cache_entry = chunk_cache[chunk_position]

		if chunk_data.dirty or cache_entry.is_empty() or world_data.dirty_chunk_system.is_chunk_dirty(chunk_position):
			cache_entry = chunk_renderer.rebuild_chunk_texture(chunk_data)
			chunk_cache[chunk_position] = cache_entry
			world_data.clear_chunk_dirty(chunk_position)
			rebuild_count += 1

		var chunk_texture: Texture2D = null
		if cache_entry.has("texture"):
			chunk_texture = cache_entry["texture"]
		if chunk_texture == null:
			continue

		var texture_world_position: Vector2 = WorldUtilsClass.chunk_to_world(chunk_position)
		if cache_entry.has("world_position"):
			texture_world_position = cache_entry["world_position"]
		var texture_rect: Rect2 = Rect2(texture_world_position - draw_origin_world, chunk_texture.get_size())
		canvas_item.draw_texture_rect(chunk_texture, texture_rect, false)
		rendered_chunk_count += 1
		if cache_entry.has("visible_cell_count"):
			visible_cell_count += int(cache_entry["visible_cell_count"])

	profiling_info = {
		"visible_chunk_count": visible_chunk_positions.size(),
		"rendered_chunk_count": rendered_chunk_count,
		"visible_cell_count": visible_cell_count,
		"dirty_chunk_count": world_data.get_dirty_chunk_count(),
		"chunk_rebuild_count": rebuild_count,
		"estimated_frame_time_ms": float(Time.get_ticks_usec() - frame_start_usec) / 1000.0,
	}
	return profiling_info


func get_visible_chunk_positions(view_rect: Rect2) -> Array[Vector2i]:
	var min_chunk: Vector2i = WorldUtilsClass.world_to_chunk(view_rect.position) - Vector2i(render_margin_chunks, render_margin_chunks)
	var max_chunk: Vector2i = WorldUtilsClass.world_to_chunk(view_rect.end - Vector2.ONE) + Vector2i(render_margin_chunks, render_margin_chunks)
	return world_data.get_existing_chunk_positions_in_rect(min_chunk, max_chunk)


func get_profiling_info() -> Dictionary:
	return profiling_info
