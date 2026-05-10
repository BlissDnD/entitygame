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

# Allowed developer tuning bounds for runtime mining power edits.
# Used by: `runtime_debug_settings.gd`.
const MINING_POWER_MIN: float = 1.0
const MINING_POWER_MAX: float = 500.0

# Allowed developer tuning bounds for runtime mining radius edits.
# Used by: `runtime_debug_settings.gd`.
const MINING_RADIUS_MIN: int = 1
const MINING_RADIUS_MAX: int = 10


# Movement
# Prototype player size in logical cells.
# Used by: `world_scene.gd`.
const PLAYER_SIZE_CELLS: Vector2i = Vector2i(3, 4)

# Horizontal player movement speed in world pixels per second.
# Used by: `world_scene.gd`.
const PLAYER_MOVE_SPEED: float = 260.0

# Upward jump launch speed for the prototype player.
# Used by: `world_scene.gd`.
const PLAYER_JUMP_VELOCITY: float = -360.0

# Downward gravity acceleration for the prototype player.
# Used by: `world_scene.gd`.
const PLAYER_GRAVITY: float = 980.0

# Initial player spawn position in world space for the prototype scene.
# Used by: `world_scene.gd`.
const PLAYER_SPAWN_WORLD_POSITION: Vector2 = Vector2(-12.0, -96.0)

# Number of logical cells visible horizontally in the prototype camera framing.
# Used by: `world_scene.gd`.
const CAMERA_VIEW_CELLS_X: int = 72

# Number of logical cells visible vertically in the prototype camera framing.
# Used by: `world_scene.gd`.
const CAMERA_VIEW_CELLS_Y: int = 42

# Draw color for the prototype player fill.
# Used by: `world_scene.gd`.
const PLAYER_DEBUG_COLOR: Color = Color(0.98, 0.84, 0.28, 0.92)

# Draw color for the prototype player outline.
# Used by: `world_scene.gd`.
const PLAYER_DEBUG_OUTLINE_COLOR: Color = Color(1.0, 0.96, 0.62, 1.0)


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
