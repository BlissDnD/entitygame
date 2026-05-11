class_name CursorBehaviorDefinition
extends Resource

enum CursorBehavior {
	NONE,
	INTERACT,
	MINE_CONE,
	MELEE,
	RANGED,
	PLACE,
	SCAN,
	HAND,
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var behavior: CursorBehavior = CursorBehavior.NONE
