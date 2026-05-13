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

## Possible Next Extractions

1. `WorldBackpackController`
2. `WorldItemDropController`
3. `WorldNpcController`
4. `WorldRoomController`
5. `WorldMiningController`
6. `WorldPlayerController`
7. `WorldRenderController`
8. `GravityRuntime`

## Rules

- Extract one responsibility per pass.
- Do not change gameplay behavior during extraction.
- Do not move ownership into UI.
- Do not add autoloads for world-local gameplay state.
- Keep `world_scene.gd` as the orchestrator until a larger runtime architecture is intentionally designed.
