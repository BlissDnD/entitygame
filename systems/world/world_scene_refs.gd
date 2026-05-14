class_name WorldSceneRefs
extends RefCounted

var camera_2d: Camera2D = null
var time_manager: TimeManager = null
var spawn_manager: SpawnManager = null
var map_handler: MapHandler = null
var crash_ship: CrashShip = null
var placeable_objects: Node2D = null
var world_items: Node2D = null
var npc_objects: Node2D = null
var persistent_followers: Node2D = null
var player_follow_target: Node2D = null
var console_layer: CanvasLayer = null
var console_panel: Panel = null
var console_input: LineEdit = null
var godmode_panel: GodModePanel = null
var ui_root: UIRoot = null


static func capture(world: Node) -> WorldSceneRefs:
	var refs := WorldSceneRefs.new()
	refs.camera_2d = world.get_node("camera_2d")
	refs.time_manager = world.get_node("time_manager")
	refs.spawn_manager = world.get_node("spawn_manager")
	refs.map_handler = world.get_node("map_handler")
	refs.crash_ship = world.get_node("crash_ship")
	refs.placeable_objects = world.get_node("placeable_objects")
	refs.world_items = world.get_node("world_items")
	refs.npc_objects = world.get_node("npc_objects")
	refs.persistent_followers = world.get_node("npc_objects/persistent_followers")
	refs.player_follow_target = world.get_node("player_follow_target")
	refs.console_layer = world.get_node("console_layer")
	refs.console_panel = world.get_node("console_layer/console_panel")
	refs.console_input = world.get_node("console_layer/console_panel/console_input")
	refs.godmode_panel = world.get_node("console_layer/godmode_panel")
	refs.ui_root = world.get_node("UIRoot")
	return refs
