class_name InteractionTypes
extends RefCounted

const CursorBehaviorDefinitionClass = preload("res://systems/cursor/cursor_behavior_definition.gd")

enum InteractionMode {
	NONE,
	HAND,
	PLACE,
	ATTACH,
	PULL,
	SCAN,
	MINE_CONE,
}

enum InteractionTargetType {
	NONE,
	WORLD_ITEM,
	ACTOR,
	SURFACE,
	SOCKET,
	PHYSICS_BODY,
}


static func from_cursor_behavior(cursor_behavior: int) -> int:
	match cursor_behavior:
		CursorBehaviorDefinitionClass.CursorBehavior.PLACE:
			return InteractionMode.PLACE
		CursorBehaviorDefinitionClass.CursorBehavior.SCAN:
			return InteractionMode.SCAN
		CursorBehaviorDefinitionClass.CursorBehavior.MINE_CONE:
			return InteractionMode.MINE_CONE
		CursorBehaviorDefinitionClass.CursorBehavior.INTERACT:
			return InteractionMode.HAND
		CursorBehaviorDefinitionClass.CursorBehavior.HAND:
			return InteractionMode.HAND
		_:
			return InteractionMode.HAND


static func get_mode_name(interaction_mode: int) -> String:
	match interaction_mode:
		InteractionMode.NONE:
			return "NONE"
		InteractionMode.HAND:
			return "HAND"
		InteractionMode.PLACE:
			return "PLACE"
		InteractionMode.ATTACH:
			return "ATTACH"
		InteractionMode.PULL:
			return "PULL"
		InteractionMode.SCAN:
			return "SCAN"
		InteractionMode.MINE_CONE:
			return "MINE_CONE"
		_:
			return "UNKNOWN"


static func get_target_type_name(target_type: int) -> String:
	match target_type:
		InteractionTargetType.NONE:
			return "NONE"
		InteractionTargetType.WORLD_ITEM:
			return "WORLD_ITEM"
		InteractionTargetType.ACTOR:
			return "ACTOR"
		InteractionTargetType.SURFACE:
			return "SURFACE"
		InteractionTargetType.SOCKET:
			return "SOCKET"
		InteractionTargetType.PHYSICS_BODY:
			return "PHYSICS_BODY"
		_:
			return "UNKNOWN"
