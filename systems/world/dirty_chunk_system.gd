class_name DirtyChunkSystem
extends RefCounted

var dirty_chunks: Dictionary = {}


func mark_chunk_dirty(chunk_position: Vector2i) -> void:
	dirty_chunks[chunk_position] = true


func clear_chunk_dirty(chunk_position: Vector2i) -> void:
	dirty_chunks.erase(chunk_position)


func is_chunk_dirty(chunk_position: Vector2i) -> bool:
	return dirty_chunks.has(chunk_position)


func get_dirty_chunk_count() -> int:
	return dirty_chunks.size()


func clear() -> void:
	dirty_chunks.clear()
