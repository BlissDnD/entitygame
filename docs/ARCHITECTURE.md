## Placeable Objects

Non-material scene objects use the prototype placeables system:

- `systems/placeables/placeable_object_definition.gd` defines data-driven placement rules.
- `systems/placeables/placeable_placement_service.gd` validates tile support and spawns objects.
- `entity/placeable/placeable_object.tscn` is the generic base scene for simple props.
- `resources/placeables/` contains editable example definitions.

The service is intentionally not an autoload. Create it with the current `world_data` and a parent `Node` when world generation, tests, or future editor tools need to place props.

## NPCs

Prototype NPC scenes live under `entity/npc/`.

- `entity/npc/npc_base.gd` is the tiny shared foundation for moving NPCs.
- `entity/npc/atlas_worker/` contains the AtlasWorker creature and its spawn point.
- Room generation owns per-room NPC containers and enables processing only for the active room.

## Items, Equipment, And Backpacks

The item foundation is data-driven and separate from the current material prototype inventory.

- `systems/items/item_definition.gd` defines broad item data, categories, capabilities, and specialization flags.
- `systems/equipment/player_equipment.gd` tracks equipped tools, weapons, and backpacks.
- `systems/backpack/backpack_definition.gd` and `backpack_container.gd` provide the physical backpack foundation.
- `systems/cursor/player_cursor_controller.gd` maps equipped item cursor behavior to debug state.
- Example editable item resources live under `resources/items/`, `resources/equipment/`, `resources/backpacks/`, and `resources/cursor/`.

Placeable item definitions reference existing `PlaceableObjectDefinition` resources; placement validation remains owned by `systems/placeables/`.

## Room Time And World Influences

Room-local day/night state is owned by the lightweight sun-cycle system:

- `systems/time/cycle_influence.gd` is reusable runtime data for moving world influence objects such as the sun, moon, events, or storms.
- `systems/time/planet_sun_cycle.gd` tracks in-game time, sun room movement, and cached `DAY` / `DUSK` / `NIGHT` / `DAWN` states.
- `world_scene.gd` queries the cycle for the current room background color and debug readout.

The cycle updates room state caches only when the hour changes, not every frame. Future gameplay systems should query `PlanetSunCycle` instead of hardcoding day/night rules.

The sun starts at 12 AM in zero-based room index `12` for the 24-room prototype. The sun moves left to right by increasing room index. The 8-room `DAY` band is centered on the sun using offsets `-3..+4`; rooms ahead of the moving sun become `DAWN`, and rooms behind it become `DUSK`.

## World Laws

World Law data lives under `systems/world_laws/` as a standalone RefCounted foundation layer.

- `world_law_entity_data.gd` stores stable identity, physical properties, visible conditions, hidden conditions, temporary states, lifecycle data, and fates.
- Conditions, temporary states, lifecycle, and fates are separate concepts and should not be collapsed into a generic status list.
- `world_law_evaluator.gd` evaluates an explicit dirty queue only; callers must queue entities when data changes or when temporary states need ticking.
- `world_law_debug_formatter.gd` provides compact text output for future GodMode/debug visualization.

Validation examples live in `tests/world_laws/`. This system does not create scene actors, autoloads, UI, save/load, or gameplay ownership by itself.

## Debug UI

Reusable debug UI lives under `ui/debug/`.

- `ui/debug/godmode_panel.tscn` and `godmode_panel.gd` own the compact GodMode controls and labels.
- Gameplay state remains owned by `world_scene.gd`; the panel receives snapshot dictionaries through `refresh()` and emits request signals for debug actions.
- Debug UI must not directly mutate gameplay systems or become runtime ownership for mining, inventory, equipment, backpack, sun-cycle, or world-law data.
- `scenes/debug/godmode_world.tscn` instances the real `scenes/world/world_scene.tscn` with `starts_in_godmode = true`; it must not own a separate world simulation.

## Editor-Facing Components

Backend/domain logic remains in `systems/`. Scene actors and thin editor-facing Node wrappers live under `entity/` and `entity/components/`. See `docs/editor_component_layer.md`.

## Gravity Fields

- `systems/world/gravity_field_system.gd` and `gravity_field_data.gd` provide local gravity-field test data for the playable world runtime.
- `world_scene.gd` owns room-local gravity field systems and exposes GodMode placement modes for field bounds and gravity points.
- Gravity fields are local modifiers; global player/world gravity remains unchanged outside a field.

## Build-Forward Rules

The project is now in an early gameplay-foundation stage rather than a pure empty-shell stage. New work should preserve the current modular direction and avoid regrowing a monolithic world scene.

- `scenes/world/world_scene.gd` should stay a composition root: node refs, runtime fields, and high-level delegation only.
- New gameplay features should usually enter through a dedicated folder under `systems/` with small focused files such as runtime, controller, query, rendering, or data helpers.
- Prefer adding feature-local resources or definitions over adding more hardcoded branching to shared orchestrators.
- If a new mechanic needs scene wiring, keep the scene change thin and let the feature own its own behavior.
- Avoid turning large callback dictionaries into the long-term ownership model for gameplay logic; use them as transitional glue only.

## File Size Guidance

The repo can still scale while keeping files under roughly 500 lines, but only if new responsibilities are split early.

Recommended practical rule:

- under `250` lines: ideal for small helpers and single-purpose controllers
- `250-400` lines: acceptable for feature runtimes or orchestration with one clear concern
- `400-500` lines: warning zone; split before adding major new behavior
- over `500` lines: treat as a refactor target unless there is a strong reason not to

Current hotspots worth watching:

- `systems/world/world_draw_controller.gd`
- `systems/config/gameplay_tuning.gd`
- `systems/world/world_data.gd`
- `systems/world/world_scene_operation_helpers.gd`
- `scenes/world/world_scene.gd`

## Where To Add New Things

Prefer this pattern when extending the game:

1. Add definitions/resources first if the feature is content- or tuning-driven.
2. Add a feature-local runtime/controller in `systems/<feature>/`.
3. Let scene actors in `entity/` stay thin and reactive.
4. Keep UI display and debug controls in `ui/` and `systems/debug/`, never as gameplay owners.
5. Touch `world_scene.gd` only to connect the feature into the existing frame/input/bootstrap flow.
