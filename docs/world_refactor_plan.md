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
17. `GodModeUiController`
   - File: `systems/debug/godmode_ui_controller.gd`
   - Owns GodMode panel signal wiring, console visibility flow, debug UI hit-testing, HUD refresh coordination, GodMode snapshot refresh orchestration, and debug command/button entrypoints.
   - `world_scene.gd` still owns the underlying gameplay callbacks and runtime state, but no longer assembles the GodMode UI flow directly.
18. `WorldRoomFlowController`
   - File: `systems/world/world_room_flow_controller.gd`
   - Owns active-room switch orchestration, room-transition flow, room-entry placement, transition collision resolution, void-fall handling, respawn flow, and world-boundary debug formatting.
   - `world_scene.gd` still owns the authoritative runtime fields and passes explicit callbacks/state into the controller.
19. `WorldInputInteractionController`
   - File: `systems/world/world_input_interaction_controller.gd`
   - Owns unhandled input routing for console toggle, interact/drop actions, world-item pickup, gravity build clicks, placement clicks, inspect clicks, and selected-material cycling.
   - `world_scene.gd` still owns the authoritative runtime fields and passes explicit scene callbacks, room/runtime state, and redraw hooks into the controller.
20. `WorldRuntime`, `WorldSceneRefs`, `WorldBootstrap`
   - Files: `systems/world/world_runtime.gd`, `systems/world/world_scene_refs.gd`, `systems/world/world_bootstrap.gd`
   - Introduce the next composition-root layer: runtime state container groundwork, scene-node reference capture, and `_ready()` bootstrap orchestration extraction.
   - `world_scene.gd` still keeps incremental compatibility aliases for existing state usage, but the setup flow no longer lives inline in the scene script.
21. `WorldTickPipeline`
   - File: `systems/world/world_tick_pipeline.gd`
   - Owns `_process()` orchestration flow for redraw decisions, transition-lock ticking, hover updates, item-drop ticking, camera tracking, and the high-level player/mining/transition tick order.
   - `world_scene.gd` still owns the underlying update callbacks and runtime fields, but the frame pipeline no longer lives inline in the scene script.
22. `WorldQueryFacade`
   - File: `systems/world/world_query_facade.gd`
   - Owns room/world/player/view query helpers such as room rects, void-fall rects, camera centering, viewport sizing, current-room queries, player rect/center/ground queries, and cell/world size conversions.
   - `world_scene.gd` keeps a few compatibility wrappers for callback-heavy code paths, but the helper math/query logic is no longer implemented inline.
23. `WorldBuildMiningFacade`
   - File: `systems/world/world_build_mining_facade.gd`
   - Owns mining/build preview queries, traversal ordering, placement validation, build-mode queries, gravity build interaction delegation, and mining/build naming helpers.
   - `world_scene.gd` still exposes a few callback bridges for UI and controller compatibility, but the mining/build helper block is no longer implemented inline.
24. `WorldDrawPipeline`
   - File: `systems/world/world_draw_pipeline.gd`
   - Owns `_draw()` orchestration and draw-context assembly handoff to `WorldDrawController`.
   - `world_scene.gd` now just hands the pipeline the scene callbacks/runtime values instead of assembling the full draw call inline.
25. `WorldStateSyncFacade`, `WorldSupportFacade`
   - Files: `systems/world/world_state_sync_facade.gd`, `systems/world/world_support_facade.gd`
   - Own state/write-back bridge helpers, crash-ship/backpack support helpers, room visibility updates, spawn support, player-follow support, and view-resolution support.
   - These keep compatibility with the current incremental refactor while moving more scene-local glue out of `world_scene.gd`.
26. `WorldSceneContextFactory`
   - File: `systems/world/world_scene_context_factory.gd`
   - Owns the large scene-level context assembly for `_ready()`, `_process()`, `_unhandled_input()`, and `_draw()`.
   - `world_scene.gd` still owns the orchestration entrypoints and gameplay helper methods, but no longer keeps the large inline dictionary-building blocks for those pipelines.
27. `Main` Scene Groundwork
   - Files: `scenes/main/main.tscn`, `scenes/main/main.gd`
   - Introduces a top-level `main` scene with separate `ui` and `world` children, and a small loader that instantiates the active level scene under `world`.
   - `world_scene.tscn` still contains its own HUD/debug UI for now, but the project now has the intended root architecture for moving menus/HUD spawning upward without redesigning level logic.
28. `Main` UI Mounting
   - File: `scenes/main/main.gd`
   - The active level now mounts its UI nodes (`console_layer`, `UIRoot`) under `main/ui` at runtime, while the level scene itself remains under `main/world`.
   - This preserves current gameplay/UI behavior while shifting actual UI tree ownership upward into the root scene architecture.
29. `WorldScene` Composition-Root Cutover
   - Files: `scenes/world/world_scene.gd`, `systems/world/world_scene_context_factory.gd`
   - The large room/build/mining/transition/support helper blocks were removed from `world_scene.gd` after their behavior was moved behind `WorldSceneContextFactory` and existing facades/controllers.
   - `world_scene.gd` is now a thin level-scene composition root again, focused on node references, runtime fields, and high-level delegation for `_ready()`, `_process()`, `_unhandled_input()`, and `_draw()`.

## Possible Next Extractions

1. `Scene-Level Cleanup And Final Consolidation`
2. `WorldDrawController` concern split
   - Separate world-space drawing concerns before more visuals are added.
   - Candidate slices: player/drop visuals, terrain/surface visuals, build-preview visuals, debug/label overlays, room-transition indicators.
3. `WorldSceneContextFactory` shrink pass
   - Reduce large dictionary assembly and repeated query wiring.
   - Prefer smaller per-pipeline context builders or feature-local context helpers where ownership is clearer.
4. `WorldSceneOperationHelpers` split by domain
   - Candidate slices: room flow helpers, mining/build helpers, spawn/support helpers, player/world query bridges.
5. `GameplayTuning` decentralization
   - Keep shared cross-feature constants centralized, but move feature-specific tuning toward local config/resources when the feature stabilizes.

## Rules

- Extract one responsibility per pass.
- Do not change gameplay behavior during extraction.
- Do not move ownership into UI.
- Do not add autoloads for world-local gameplay state.
- Keep `world_scene.gd` as the orchestrator until a larger runtime architecture is intentionally designed.

## Updated Assessment

The current refactor is working: `world_scene.gd` is much thinner than before, and the project can keep growing without immediately collapsing into a single giant script.

But the next scaling risk has moved:

- `world_scene.gd` is no longer the only hotspot.
- `world_scene_context_factory.gd` and `world_scene_operation_helpers.gd` are now the main glue accumulators.
- `world_draw_controller.gd` is close to becoming the next "everything file" for rendering concerns.

That means future work should not treat the current refactor state as the end state. It is a safer midpoint.

## Build-Forward Policy

Use this plan as the rule for adding future gameplay:

1. Keep scene scripts thin.
2. Add new gameplay through dedicated feature-local systems.
3. Let the world scene wire features together, but not own their logic.
4. Split files before they exceed roughly 500 lines.
5. Treat large callback/context dictionaries as transitional glue, not as the final gameplay API design.

## Preferred Feature Addition Pattern

When adding a new mechanic, try to follow this order:

1. Add feature definitions/resources if the mechanic is data-driven.
2. Add `systems/<feature>/` runtime/controller/query helpers.
3. Add or update thin `entity/` wrappers only when a scene actor is actually needed.
4. Connect the feature into `world_scene.gd` with minimal new wiring.
5. Add focused tests or debug hooks near the feature instead of stuffing more diagnostic behavior into unrelated world files.
