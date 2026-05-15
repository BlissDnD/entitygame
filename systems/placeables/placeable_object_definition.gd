class_name PlaceableObjectDefinition
extends Resource

enum PlacementMode {
	BACKGROUND,
	FLOOR,
	WALL,
	TILE_SIDE,
	TILE_UNDERSIDE,
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var scene: PackedScene
@export var placement_mode: PlacementMode = PlacementMode.FLOOR
@export var has_collision: bool = false
@export var footprint_tiles: Vector2i = Vector2i.ONE
@export var placement_offset: Vector2 = Vector2.ZERO
@export var requires_support_tile: bool = true
@export_group("Interaction")
@export var interaction_enabled: bool = false
@export var required_passive_item_ids: Array[StringName] = []
@export var interaction_yield_item: ItemDefinition
@export var interaction_yield_amount: int = 0
@export var interaction_consumes_object: bool = true
