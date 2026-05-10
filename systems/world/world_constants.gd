class_name WorldConstants
extends RefCounted


const CELL_SIZE := Vector2i(8, 8)
const CHUNK_SIZE_CELLS := Vector2i(32, 32)
const PLAYER_SIZE_CELLS := Vector2i(3, 6)


enum CellType {
	AIR,
	DIRT,
	STONE,
}


enum ToolShape {
	SQUARE,
	CIRCLE,
}
