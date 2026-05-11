class_name GameplayTuning
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")


# Mining
# Base mining power used by the default tool profile and developer controls.
# Expected range: 1.0 to 100.0.
# Used by: `mining_tool_profiles.gd`, `runtime_debug_settings.gd`.
const DEFAULT_MINING_POWER: float = 150.0

# Base logical mining radius used by the default tool profile and developer controls.
# Expected range: 1 to 10.
# Used by: `mining_tool_profiles.gd`, `runtime_debug_settings.gd`.
const DEFAULT_MINING_RADIUS: int = 2

# Base logical placement radius used by the default placement tool behavior.
# Expected range: 1 to 10.
# Used by: `world_scene.gd`.
const DEFAULT_PLACEMENT_RADIUS: int = DEFAULT_MINING_RADIUS

# Maximum world-space mining reach from the player center, measured in logical cells.
# Used by: `world_scene.gd`.
const MINING_RANGE_CELLS: float = 12.0

# Distance-based excavation speed reduction for farther cells in traversal order.
# Lower values make far cells mine more slowly.
# Used by: `mining_tool_profiles.gd`, `world_scene.gd`.
const MINING_PROGRESS_FALLOFF: float = 0.90

# Controls whether directional traversal also applies speed falloff.
# `true`: nearer cells mine faster and farther cells mine slower.
# `false`: all cells mine at the same speed regardless of distance/order.
# Used by: `world_scene.gd`.
const MINING_USE_DIRECTIONAL_SPEED_FALLOFF: bool = false

# Default mining shape for the active mining tool and developer controls.
# Used by: `mining_tool_profiles.gd`, `runtime_debug_settings.gd`.
const DEFAULT_MINING_SHAPE: int = WorldConstantsClass.ToolShape.SQUARE

# Default placement shape used when returning materials to the world.
# Used by: `world_scene.gd`.
const DEFAULT_PLACEMENT_SHAPE: int = DEFAULT_MINING_SHAPE

# Allowed developer tuning bounds for runtime mining power edits.
# Used by: `runtime_debug_settings.gd`.
const MINING_POWER_MIN: float = 1.0
const MINING_POWER_MAX: float = 500.0

# Allowed developer tuning bounds for runtime mining radius edits.
# Used by: `runtime_debug_settings.gd`.
const MINING_RADIUS_MIN: int = 1
const MINING_RADIUS_MAX: int = 10

# Maximum total number of terrain tiles the player can carry.
# Used by: `inventory_data.gd`, `world_scene.gd`.
const INVENTORY_CAPACITY: int = 100

# Maximum total carried material weight.
# Used by: `inventory_data.gd`, `world_scene.gd`.
const INVENTORY_WEIGHT_CAPACITY: float = 100.0

# Minimum allowed inventory capacity for runtime debug edits.
# Used by: `world_scene.gd`.
const INVENTORY_CAPACITY_MIN: int = 0

# Maximum allowed inventory capacity for runtime debug edits.
# Used by: `world_scene.gd`.
const INVENTORY_CAPACITY_MAX: int = 9999

# Minimum allowed inventory weight capacity for runtime debug edits.
# Used by: `world_scene.gd`.
const INVENTORY_WEIGHT_CAPACITY_MIN: float = 0.0

# Maximum allowed inventory weight capacity for runtime debug edits.
# Used by: `world_scene.gd`.
const INVENTORY_WEIGHT_CAPACITY_MAX: float = 99999.0

# Default selected placement material when the scene starts.
# Used by: `world_scene.gd`.
const DEFAULT_SELECTED_MATERIAL: int = WorldConstantsClass.CellType.DIRT

# Movement
# Prototype player size in logical cells.
# Used by: `world_scene.gd`.
const PLAYER_SIZE_CELLS: Vector2i = Vector2i(3, 4)

# Horizontal player movement speed in world pixels per second.
# Used by: `world_scene.gd`.
const PLAYER_MOVE_SPEED: float = 260.0

# Time in seconds of continuous running needed to reach full speed boost.
# Used by: `world_scene.gd`.
const PLAYER_RUN_BOOST_TIME: float = 1.0

# Maximum continuous-running speed multiplier.
# `1.2` means 20 percent faster than base movement speed.
# Used by: `world_scene.gd`.
const PLAYER_RUN_BOOST_MULTIPLIER: float = 1.2

# Guaranteed ground step-up height in logical cells.
# Used by: `world_scene.gd`.
const PLAYER_STEP_UP_BASE_CELLS: int = 1

# Extra step-up height unlocked once the player has enough running speed.
# Used by: `world_scene.gd`.
const PLAYER_STEP_UP_FAST_CELLS: int = 2

# Minimum run multiplier needed before the larger step-up height is allowed.
# Used by: `world_scene.gd`.
const PLAYER_FAST_STEP_THRESHOLD: float = 1.12

# Small upward assist used when horizontal movement catches on voxel sides.
# Helps the player slide past rough side faces without feeling sticky.
# Used by: `world_scene.gd`.
const PLAYER_WALL_STEP_ASSIST_PIXELS: int = 4

# Upward jump launch speed for the prototype player.
# Used by: `world_scene.gd`.
const PLAYER_JUMP_VELOCITY: float = -360.0

# Downward gravity acceleration for the prototype player.
# Used by: `world_scene.gd`.
const PLAYER_GRAVITY: float = 980.0

# Initial player spawn position in world space for the prototype scene.
# Used by: `world_scene.gd`.
const PLAYER_SPAWN_WORLD_POSITION: Vector2 = Vector2(-12.0, 0.0)

# Target horizontal tile count visible in gameplay.
# Used by: `world_scene.gd`.
const CAMERA_VIEW_CELLS_X: int = 90

# Reference vertical tile count used for room sizing defaults.
# Used by: `world_scene.gd`.
const CAMERA_VIEW_CELLS_Y: int = 42

# Number of pre-generated rooms in the current prototype map.
# Used by: `world_scene.gd`.
const ROOM_COUNT: int = 24

# Minimum random room size in logical cells.
# Width is intentionally at least 3x the base camera width.
# Used by: `world_scene.gd`.
const ROOM_MIN_SIZE_CELLS: Vector2i = Vector2i(CAMERA_VIEW_CELLS_X * 3, CAMERA_VIEW_CELLS_Y * 2)

# Maximum random room size in logical cells.
# Kept moderate so prototype rooms stay roomy without getting too heavy.
# Used by: `world_scene.gd`.
const ROOM_MAX_SIZE_CELLS: Vector2i = Vector2i(CAMERA_VIEW_CELLS_X * 5, CAMERA_VIEW_CELLS_Y * 4)

# Room-edge transition trigger thickness in logical cells.
# Used by: `world_scene.gd`.
const ROOM_TRANSITION_MARGIN_CELLS: int = 2

# Player entry inset from a destination room edge, in logical cells.
# Used by: `world_scene.gd`.
const ROOM_ENTRY_INSET_CELLS: int = 4

# Draw color for room boundary debugging and room-transition arrows.
# Used by: `world_scene.gd`.
const ROOM_EDGE_COLOR: Color = Color(0.9, 0.92, 0.98, 0.45)

# Fill color for active room-transition arrows.
# Used by: `world_scene.gd`.
const ROOM_TRANSITION_ARROW_COLOR: Color = Color(0.98, 0.92, 0.5, 0.95)

# Horizontal void distance beyond an outer planet edge before fall-off triggers.
# Used by: `world_scene.gd`.
const VOID_FALL_MARGIN_CELLS: int = 5

# Vertical void distance below the room before fall-off triggers.
# Used by: `world_scene.gd`.
const VOID_FALL_DEPTH_CELLS: int = 16

# Extra camera follow range beyond the outer planet edges.
# Used by: `world_scene.gd`.
const VOID_CAMERA_MARGIN_CELLS: int = 24

# Surface prop generation density. Higher values spawn more props on the surface.
# Used by: `world_scene.gd`.
const SURFACE_PROP_DENSITY: float = 0.22

# Minimum horizontal gap between spawned surface props, in logical cells.
# Used by: `world_scene.gd`.
const SURFACE_PROP_SPACING_MIN_CELLS: int = 2

# Safe no-prop edge buffer so room transitions stay clear.
# Used by: `world_scene.gd`.
const SURFACE_PROP_EDGE_MARGIN_CELLS: int = 6

# Number of ground cells under a surface prop that cannot be mined.
# Used by: `world_scene.gd`.
const SURFACE_PROP_PROTECTED_DEPTH_CELLS: int = 3

# Bush color for prototype surface props.
# Used by: `world_scene.gd`.
const BUSH_COLOR: Color = Color(0.33, 0.62, 0.27, 1.0)

# Rock color for prototype surface props.
# Used by: `world_scene.gd`.
const ROCK_COLOR: Color = Color(0.55, 0.57, 0.62, 1.0)

# Camera rotation follow speed for planetary horizon alignment.
# Higher values feel snappier, lower values feel smoother.
# Used by: `world_scene.gd`.
const CAMERA_ROTATION_SMOOTH_SPEED: float = 10.0

# Draw color for the prototype player fill.
# Used by: `world_scene.gd`.
const PLAYER_DEBUG_COLOR: Color = Color(0.98, 0.84, 0.28, 0.92)

# Draw color for the prototype player outline.
# Used by: `world_scene.gd`.
const PLAYER_DEBUG_OUTLINE_COLOR: Color = Color(1.0, 0.96, 0.62, 1.0)

# Vertical offset for the carried material pile visual above the player.
# Used by: `world_scene.gd`.
const PLAYER_CARRIED_PILE_OFFSET_Y: float = -10.0

# Maximum world-space height of the carried material pile visual.
# Used by: `world_scene.gd`.
const PLAYER_CARRIED_PILE_MAX_HEIGHT: float = 18.0

# Maximum world-space width of the carried material pile visual.
# Used by: `world_scene.gd`.
const PLAYER_CARRIED_PILE_MAX_WIDTH: float = 16.0

# Minimum world-space height of the carried material pile visual.
# Used by: `world_scene.gd`.
const PLAYER_CARRIED_PILE_MIN_HEIGHT: float = 4.0

# Minimum world-space width of the carried material pile visual.
# Used by: `world_scene.gd`.
const PLAYER_CARRIED_PILE_MIN_WIDTH: float = 6.0


# Developer Debug
# Whether the godmode developer panel starts enabled by default.
# Used by: `runtime_debug_settings.gd`.
const GODMODE_DEFAULT_ENABLED: bool = false

# Default mining power shown in the godmode developer controls.
# Expected range: 1.0 to 100.0.
# Used by: `runtime_debug_settings.gd`.
const GODMODE_DEFAULT_MINING_POWER: float = DEFAULT_MINING_POWER

# Default mining radius shown in the godmode developer controls.
# Expected range: 1 to 10.
# Used by: `runtime_debug_settings.gd`.
const GODMODE_DEFAULT_RADIUS: int = DEFAULT_MINING_RADIUS

# Default mining shape shown in the godmode developer controls.
# Used by: `runtime_debug_settings.gd`.
const GODMODE_DEFAULT_SHAPE: int = DEFAULT_MINING_SHAPE

# Whether the debug overlay text/visualization starts enabled by default.
# Used by: `world_scene.gd`.
const DEBUG_OVERLAY_DEFAULT_ENABLED: bool = false

# Hovered cell outline color for debug visualization.
# Used by: `world_scene.gd`.
const DEBUG_HOVER_CELL_COLOR: Color = Color(1.0, 1.0, 1.0, 0.16)

# Placement preview color when the selected material can be placed.
# Used by: `world_scene.gd`.
const PLACEMENT_PREVIEW_VALID_FILL_COLOR: Color = Color(0.42, 1.0, 0.52, 0.24)

# Placement preview outline when the selected material can be placed.
# Used by: `world_scene.gd`.
const PLACEMENT_PREVIEW_VALID_OUTLINE_COLOR: Color = Color(0.42, 1.0, 0.52, 0.95)

# Placement preview color when placement is blocked.
# Used by: `world_scene.gd`.
const PLACEMENT_PREVIEW_INVALID_FILL_COLOR: Color = Color(1.0, 0.3, 0.3, 0.22)

# Placement preview outline when placement is blocked.
# Used by: `world_scene.gd`.
const PLACEMENT_PREVIEW_INVALID_OUTLINE_COLOR: Color = Color(1.0, 0.3, 0.3, 0.95)

# Radius of a dropped material pile visual in world pixels.
# Used by: `world_scene.gd`.
const DROPPED_MATERIAL_VISUAL_RADIUS: float = 3.0

# Vertical offset between stacked dropped-material circles.
# Used by: `world_scene.gd`.
const DROPPED_MATERIAL_STACK_OFFSET: float = 2.0

# Outline color for the hovered dropped material cell.
# Used by: `world_scene.gd`.
const DROPPED_MATERIAL_HOVER_OUTLINE_COLOR: Color = Color(1.0, 0.95, 0.72, 0.95)

# Gravity applied to dropped item piles.
# Used by: `world_scene.gd`, `item_drop_data.gd`.
const DROPPED_ITEM_GRAVITY: float = 980.0

# Pixel radius used when hovering or clicking a dropped item pile.
# Used by: `world_scene.gd`.
const DROPPED_ITEM_HOVER_RADIUS_PIXELS: float = 14.0

# Pixel radius in which same-type nearby dropped items attract one another.
# Used by: `world_scene.gd`, `item_drop_data.gd`.
const DROPPED_ITEM_PULL_RADIUS_PIXELS: float = 56.0

# Pixel radius at which same-type dropped items merge into one pile.
# Used by: `world_scene.gd`, `item_drop_data.gd`.
const DROPPED_ITEM_MERGE_RADIUS_PIXELS: float = 18.0

# Minimum visual scale applied to dropped item piles.
# Used by: `world_scene.gd`.
const DROPPED_ITEM_PILE_MIN_SCALE: float = 1.0

# Maximum visual scale applied to dropped item piles.
# Used by: `world_scene.gd`.
const DROPPED_ITEM_PILE_MAX_SCALE: float = 2.1

# Item count at which the dropped pile reaches its maximum visual size.
# Used by: `world_scene.gd`.
const DROPPED_ITEM_PILE_MAX_VISUAL_COUNT: int = 24

# Fill color for the dropped material hover tooltip.
# Used by: `world_scene.gd`.
const DROPPED_MATERIAL_TOOLTIP_FILL_COLOR: Color = Color(0.08, 0.09, 0.12, 0.92)

# Outline color for the dropped material hover tooltip.
# Used by: `world_scene.gd`.
const DROPPED_MATERIAL_TOOLTIP_OUTLINE_COLOR: Color = Color(0.95, 0.9, 0.72, 0.95)


# Terrain
# First logical dirt row generated in the prototype terrain.
# Used by: `world_scene.gd`.
const SURFACE_START_DEPTH: int = 8

# Number of dirt rows generated at the prototype surface.
# Used by: `world_scene.gd`.
const SURFACE_DEPTH: int = 3

# First logical row that begins the stone layer.
# Used by: `world_scene.gd`.
const STONE_LAYER_START_DEPTH: int = 11

# Last logical row included in the prototype stone layer.
# Used by: `world_scene.gd`.
const STONE_LAYER_END_DEPTH: int = 23

# Horizontal half-width of generated surface terrain in logical cells.
# Used by: `world_scene.gd`.
const SURFACE_HALF_WIDTH_CELLS: int = 48

# Horizontal half-width of generated stone terrain in logical cells.
# Used by: `world_scene.gd`.
const STONE_HALF_WIDTH_CELLS: int = 50


# Materials
# Mining resistance for dirt cells.
# Used by: `world_materials.gd`.
const DIRT_MINING_RESISTANCE: float = 10.0

# Mining resistance for stone cells.
# Used by: `world_materials.gd`.
const STONE_MINING_RESISTANCE: float = 50.0

# Draw-based terrain colors for developer visualization.
# Used by: `world_materials.gd`.
const DIRT_DEBUG_COLOR: Color = Color(0.56, 0.35, 0.22, 1.0)
const STONE_DEBUG_COLOR: Color = Color(0.5, 0.54, 0.6, 1.0)

# Inventory carry weight per dirt tile.
# Used by: `world_materials.gd`, `inventory_data.gd`.
const DIRT_INVENTORY_WEIGHT: float = 0.2

# Inventory carry weight per stone tile.
# Used by: `world_materials.gd`, `inventory_data.gd`.
const STONE_INVENTORY_WEIGHT: float = 0.7


# Mining Visualization
# Range indicator color for debug overlay rendering.
# Used by: `world_scene.gd`.
const MINING_RANGE_COLOR: Color = Color(0.34, 0.66, 1.0, 0.72)

# Valid mining preview base color.
# Used by: `world_scene.gd`.
const MINING_PREVIEW_VALID_FILL_COLOR: Color = Color(0.2, 0.95, 1.0, 0.28)

# Valid mining preview outline color.
# Used by: `world_scene.gd`.
const MINING_PREVIEW_VALID_OUTLINE_COLOR: Color = Color(0.2, 0.95, 1.0, 0.95)

# Invalid mining preview base color.
# Used by: `world_scene.gd`.
const MINING_PREVIEW_INVALID_FILL_COLOR: Color = Color(1.0, 0.25, 0.25, 0.28)

# Invalid mining preview outline color.
# Used by: `world_scene.gd`.
const MINING_PREVIEW_INVALID_OUTLINE_COLOR: Color = Color(1.0, 0.35, 0.35, 0.95)

# Traversal preview brightness for the first cells in excavation order.
# Used by: `world_scene.gd`.
const MINING_PREVIEW_NEAR_BRIGHTNESS: float = 1.0

# Traversal preview brightness for the farthest cells in excavation order.
# Used by: `world_scene.gd`.
const MINING_PREVIEW_FAR_BRIGHTNESS: float = 0.42

# Terrain brightness multiplier at 25 percent damage.
# Used by: `world_scene.gd`.
const DAMAGE_STAGE_25_BRIGHTNESS: float = 0.88

# Terrain brightness multiplier at 50 percent damage.
# Used by: `world_scene.gd`.
const DAMAGE_STAGE_50_BRIGHTNESS: float = 0.72

# Terrain brightness multiplier at 75 percent damage.
# Used by: `world_scene.gd`.
const DAMAGE_STAGE_75_BRIGHTNESS: float = 0.56
