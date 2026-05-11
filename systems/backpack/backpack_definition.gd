class_name BackpackDefinition
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var capacity_slots: int = 8
@export var max_weight: float = 25.0
@export var value: int = 0
@export var visual_scene: PackedScene
@export var allowed_item_categories: Array[int] = []
@export var movement_penalty: float = 0.0
