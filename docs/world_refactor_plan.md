# World Scene Refactor Plan

`scenes/world/world_scene.gd` is being reduced through small, safe controller extractions. Each extraction should move one responsibility at a time while preserving gameplay behavior.

## Extracted

1. `WorldBackgroundController`
   - File: `systems/world/world_background_controller.gd`
   - Owns current/target background color, fade interpolation, fade timing, and fade debug logs.
   - `world_scene.gd` still owns the sun cycle, room state, drawing lifecycle, and redraw decisions.
2. `BuildModeRuntime`
   - File: `systems/build/build_mode_runtime.gd`
   - Owns build mode state, gravity field preview bounds, gravity field/point placement requests, and pending gravity strength selection.
   - `world_scene.gd` still owns input routing, drawing calls, GodMode popup orchestration, and redraw/UI refresh decisions.
3. `InventoryRuntime`
   - File: `systems/inventory/inventory_runtime.gd`
   - Owns selected material state, material pickup acceptance, inventory capacity tuning, backpack equip/unequip coordination, and inventory/equipment debug printing.
   - `world_scene.gd` still owns world item spawning, hover targeting, UI refreshes, and redraw decisions.
4. `TimeDebugController`
   - File: `systems/time/time_debug_controller.gd`
   - Owns time HUD formatting, room status text formatting, and sun-cycle debug message formatting.
   - `world_scene.gd` still owns time advancement orchestration and UI refresh timing.
5. `GodModeSnapshotBuilder`
   - File: `systems/debug/godmode_snapshot_builder.gd`
   - Owns GodMode snapshot dictionary assembly, equipment labels, and backpack summary formatting.
   - `world_scene.gd` still owns GodMode signal wiring and gameplay-side actions.
6. `ItemInteractionController`
   - File: `systems/items/item_interaction_controller.gd`
   - Owns dropped item physics coordination, hovered drop queries, drop pickup flow, backpack world-item spawning, backpack pickup, and backpack drop placement.
   - `world_scene.gd` still owns input routing, player/world query inputs, and UI refresh decisions.
7. `WorldSpawnController`
   - File: `systems/world/world_spawn_controller.gd`
   - Owns AtlasWorker spawn point creation, persistent follower adoption, follow-chain assignment, transition repositioning, and grounding updates.
   - `world_scene.gd` still owns room generation timing, NPC room container lifecycle, and scene-level transition flow.
8. `WorldRoomController`
   - File: `systems/world/world_room_controller.gd`
   - Owns per-room runtime storage for world data, drops, gravity systems, room sizes, surface props, protected cells, active room index, adjacency queries, and room container visibility state.
   - `world_scene.gd` still owns room generation orchestration, room transition trigger flow, crash-ship behavior, and player placement.
9. `WorldDrawController`
   - File: `systems/world/world_draw_controller.gd`
   - Owns world-space draw delegation for player, room bounds, room tooltip, sun, surface props, drops, gravity fields, mining previews, placement previews, labels, and win overlay.
   - `world_scene.gd` still owns shared draw context assembly and passes explicit callables/data into the controller.
10. `RoomTransitionController`
   - File: `systems/world/room_transition_controller.gd`
   - Owns room-transition edge detection, void-fall geometry checks, entry placement geometry, player room clamping rules, and room-entry clear-rect calculation.
   - `world_scene.gd` still owns transition side effects, room switching, respawn sequencing, and collision-resolution loops.
11. `WorldPlayerController`
   - File: `systems/world/world_player_controller.gd`
   - Owns player movement update flow, gravity-field movement, grounded stepping, wall-step assist, floor settling, run-speed boost state, player/world rect helpers, and snap-to-ground behavior.
   - `world_scene.gd` still owns player state storage, collision callbacks, room clamp callback wiring, and higher-level process orchestration.
12. `MiningRuntime`
   - File: `systems/mining/mining_runtime.gd`
   - Owns mining update flow, target-range checks, preview-cell ordering, traversal scoring, tool eligibility checks, placement validation, and preview-cell placement.
   - `world_scene.gd` still owns input routing, selected runtime state storage, debug/UI refresh side effects, and explicit callback wiring.
13. `GravityInteractionController`
   - File: `systems/gravity/gravity_interaction_controller.gd`
   - Owns gravity build-mode result interpretation, gravity click result packaging, and pending gravity-strength selection result packaging.
   - `world_scene.gd` still owns UI refreshes, popup display, and scene-level signal callbacks.
14. `GodModeActionHandler`
   - File: `systems/debug/godmode_action_handler.gd`
   - Owns console command execution, GodMode item command execution, mining debug setting application, and GodMode time command result packaging.
   - `world_scene.gd` still owns direct UI widget updates, redraw calls, and signal entrypoints.
15. `CrashShipInteractionController`
   - File: `systems/world/crash_ship_interaction_controller.gd`
   - Owns crash-ship spawn-position resolution, world placement, room-based visibility, and overlap-based interaction checks.
   - `world_scene.gd` still owns scene references, player rect assembly, and orchestration callbacks.
16. `WorldGenerationSurfaceController`
   - File: `systems/world/world_generation_surface_controller.gd`
   - Owns room generation pipeline setup, room-size generation, terrain fill generation, room container creation, surface prop generation, tree placement attempts, and protected-cell construction.
   - `world_scene.gd` still owns world reset orchestration, room registration into `WorldRoomController`, and spawn-point callback wiring.

## Possible Next Extractions

1. `Scene-Level Cleanup And Final Consolidation`

## Rules

- Extract one responsibility per pass.
- Do not change gameplay behavior during extraction.
- Do not move ownership into UI.
- Do not add autoloads for world-local gameplay state.
- Keep `world_scene.gd` as the orchestrator until a larger runtime architecture is intentionally designed.
