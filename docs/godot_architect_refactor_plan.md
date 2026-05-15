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

## Updated Direction

This document now describes historical groundwork, not the full current target shape.

The project has since moved toward a composition-root plus feature-system model:

- `world_scene.gd` should remain thin.
- Reusable gameplay logic should prefer `systems/<feature>/` modules over new manager-heavy scene ownership.
- New features should be added as bounded systems with explicit scene wiring, not by growing one large world script or one giant manager tree.

Manager Nodes are still useful when a scene-owned Node genuinely needs lifecycle or editor visibility, but they should not become the default place for unrelated gameplay logic.
