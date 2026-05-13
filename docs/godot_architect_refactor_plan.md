# Godot Architect Refactor Plan

## Node Hierarchy

```text
world_scene
  time_manager
  spawn_manager
  map_handler
  camera_2d
  crash_ship
  placeable_objects
  world_items
  npc_objects
    persistent_followers
  player_follow_target
  console_layer
  UIRoot
```

## Manager Boundaries

- `TimeManager`: owns canonical time flow through `PlanetSunCycle`, emits day/night/hour signals upward.
- `SpawnManager`: owns scene instancing helpers and spawn-table driven spawning, emits spawned entities upward.
- `MapHandler`: owns room/map query helpers and future AStar rebuild ownership.
- `world_scene.gd`: remains the current gameplay runtime while logic is moved manager-by-manager.

## Resource Direction

- `SpawnEntry`: one weighted spawn definition.
- `SpawnTable`: weighted collection of spawn entries.
- `WorldLevelDefinition`: room count/range and spawn table holder for future room generation data.

## Migration Rule

Do not move all behavior in one inheritance-chain pass. Move one ownership slice at a time into manager Nodes, connect signals upward, and only delete `world_scene.gd` code after the manager is driving the live scene.
