# Interaction System Plan

This document turns the current interaction idea into a repo-native architecture plan we can keep extending as implementation progresses.

It is intentionally written as a living plan, not a one-time brainstorm dump.

## Goal

Build a modular systemic interaction framework for the game.

This is not just a generic "press interact" feature. The intended direction is:

- world manipulation
- traversal infrastructure
- route optimization
- worker cooperation
- physical problem solving
- future time/lifecycle/world-law integration

The long-term game goal is that the player gradually reshapes planets and traversal routes instead of only mining resources.

## What The Source Plan Is Really Asking For

The source text describes a unified interaction layer with multiple world-facing modes.

The important design idea is not the list of modes by itself. The important idea is:

1. the player has a current interaction intent
2. the world can expose different kinds of valid targets
3. each mode resolves targeting, validation, execution, and feedback differently
4. the shared framework must stay modular enough that new interaction types do not bloat `world_scene.gd`

That makes this feature closer to an interaction architecture than to a single mechanic.

## Interaction Modes

These are the intended mode meanings for the current plan.

### `HAND`

Default lightweight interaction.

Use for:

- pickup
- activate
- inspect
- talk/use/open
- simple contextual world actions

This should become the fallback mode when the equipped item does not force a more specialized interaction.

### `PLACE`

Validated free placement on terrain surfaces.

Use for:

- floor placement
- wall placement
- ceiling placement
- side placement

This should reuse the existing placeable/object-definition direction instead of creating a second placement architecture.

### `ATTACH`

Socket-based constrained placement.

Use for:

- rope/vine/cable to hook
- crystal to crystal socket
- future infrastructure pieces with explicit compatibility rules

This differs from `PLACE` because success depends on socket compatibility, not just surface support.

### `PULL`

Physics-driven manipulation.

Use for:

- dragging heavy objects
- shifting route pieces
- moving physics bodies into useful configurations
- future cooperation and infrastructure setup

This should use real Godot physics constraints/joints when implemented, not fake transform snapping.

### `SCAN`

Future informational mode.

Use for:

- readout
- analysis
- hidden-state discovery
- law/time/environment inspection

### `MINE_CONE`

Future mining mode.

Mining already exists as a prototype interaction path, but this plan treats it as one specialized mode inside a broader interaction architecture, not as the architecture itself.

## Fit With The Current Repo

The current codebase already has some pieces we should build on instead of replacing:

- `systems/cursor/player_cursor_controller.gd`
  - already tracks the player-facing cursor behavior
- `systems/cursor/cursor_behavior_definition.gd`
  - already provides a data-facing cursor behavior concept
- `systems/items/item_definition.gd`
  - already supports item capabilities, tool/equipment flags, world scenes, and optional placement/cursor references
- `systems/items/item_interaction_controller.gd`
  - already handles some world interaction flows for dropped items and backpacks
- `systems/placeables/placeable_placement_service.gd`
  - already provides validated placeable placement rules
- `systems/world/world_input_interaction_controller.gd`
  - already owns scene-level input routing for interact/click actions

That means we do **not** need to restart from zero.

We need to grow from the existing cursor/item/placeable/input foundations into a general interaction architecture.

## Architectural Direction

The interaction system should follow the repo's current build-forward rules:

- keep `scenes/world/world_scene.gd` thin
- put gameplay ownership in `systems/` and `entity/`, not UI
- use resources/definitions for compatibility rules and tunable data
- split files early enough to keep them small and readable

## Proposed Folder Structure

This adapts the source plan to the current repo and naming rules.

```text
systems/interactions/
  interaction_manager.gd
  interaction_context.gd
  interaction_registry.gd
  interaction_types.gd
  interaction_target.gd

systems/interactions/player/
  player_hand_interaction_provider.gd

systems/interactions/base/
  interactable_component.gd

systems/interactions/hand/
  hand_interaction_controller.gd

systems/interactions/place/
  place_interaction_controller.gd
  place_interaction_query.gd

systems/interactions/attach/
  attach_interaction_controller.gd
  socket_component.gd
  attachable_component.gd

systems/interactions/pull/
  pull_interaction_controller.gd
  pullable_component.gd

systems/interactions/scan/
  scan_interaction_controller.gd

resources/interactions/
  socket_definition.gd
  attach_rule_definition.gd
```

Notes:

- `placeable_placement_service.gd` should remain the lower-level placement validator for free placement.
- `place_interaction_controller.gd` should orchestrate player-facing targeting and placement requests, not replace the placeable service.
- `MINE_CONE` can continue to live through the existing mining/build stack until we intentionally fold it into the broader interaction manager.

## Ownership Boundaries

### `interaction_manager.gd`

Owns:

- active interaction mode resolution
- interaction request entrypoints
- interaction target resolution handoff
- dispatch to mode-specific controllers

Does not own:

- UI
- world scene orchestration
- per-mode validation details
- physics implementation details

## Interactable Contract

The intended `HAND` interaction contract is:

1. resolve a candidate target
2. ask the target if it is interactable for this user right now
3. if yes, call the target's own interaction code

In practical repo terms, interactable targets should move toward this shape:

- `can_interact(user := null, interaction_context := null) -> bool`
- `interact(user := null, interaction_context := null)`

Important rule:

- the target decides whether interaction is allowed
- the target defines what interaction actually does
- the interaction layer should resolve targets and route calls, not own the target-specific gameplay outcome

## Targeting And Restrictions

Current `HAND` behavior should follow these rules:

1. require a hovered valid target
2. let the target decide whether the current user is allowed to interact
3. keep highlight and actual interaction aligned so off-target interactions do not fire silently

Current restriction support is intentionally simple and data-driven:

- interactable placeables can define `required_passive_item_ids`
- the current user satisfies those requirements through shared equipment state in `InteractionContext`
- target-specific requirements should stay on the target definition or target script, not in world-scene special cases

This is the current pattern for tool-gated world objects such as trees requiring an axe.

This is also the future-facing rule for NPCs:

- NPCs should be able to use the same interaction contract
- the target can allow or reject interaction based on who the user is
- user-specific restrictions should live with the interactable target or its rules, not in world-scene special cases

## Player vs NPC Ownership

Player interaction and NPC interaction should not collapse into one giant owner.

Preferred direction:

- shared interaction contracts stay in `systems/interactions/`
- player-side candidate gathering and player-specific input/selection rules live in player-focused interaction helpers
- NPC-side interaction choice, permission checks, and task-driven use should later live in their own NPC-facing interaction system

That means the player and NPCs can share:

- `can_interact(user, interaction_context)`
- `interact(user, interaction_context)`
- interaction mode/type vocabulary

But they should not be forced to share the same decision-making system for how they discover or prioritize targets.

### `interaction_context.gd`

Owns:

- the minimal bundle of runtime references needed by interaction controllers
- player state snapshots needed for queries
- room/world access bridges

This should help reduce giant raw dictionaries over time, but it must stay focused and not become a new dump-everything container.

### `interactable_component.gd`

Owns:

- exposing that an entity can be interacted with
- interaction capabilities or tags
- signals for availability/state changes

Does not own:

- player input
- global target scanning every frame

### `place_interaction_controller.gd`

Owns:

- player-facing place targeting flow
- placement request packaging
- validation handoff to existing placement systems
- mode-specific result handling and feedback data

Does not own:

- freehand scene spawning rules
- placeable definition authoring

### `attach_interaction_controller.gd`

Owns:

- socket target validation
- compatible connection checks
- attach request execution

### `pull_interaction_controller.gd`

Owns:

- pull-mode request lifecycle
- allowed body selection
- active joint/constraint setup and teardown
- weight/resistance rule handoff

This should stay separate from generic world input logic because it will grow fast once real physics behavior exists.

## Non-Goals For The First Pass

To keep the system grounded, the first implementation pass should **not** try to solve everything at once.

Do not try to fully implement:

- worker cooperation
- route optimization AI
- full scan gameplay
- world-law integration
- generalized multi-user networking behavior
- every interaction mode at production depth in one pass

The first milestone should prove the architecture, not finish the whole feature family.

## Recommended Implementation Phases

## Current Status

Current implementation progress:

- Phase 1 is started.
- The repo now has `interaction_types.gd`, `interaction_target.gd`, `interaction_context.gd`, and `interaction_manager.gd`.
- Current `interact` input in the world scene is routed through `InteractionManager`.
- `HAND` mode now resolves an explicit target before interaction instead of only trying a hardcoded chain.
- `HAND` now resolves against the hovered valid target so highlight and interaction use the same target rule.
- Existing backpack and crash-ship interactions are now owned more directly by the interactable targets themselves.
- Candidate gathering for `HAND` is now routed through context-provided candidate collection instead of being hardcoded inside the hand query.
- Player-side hand candidate gathering now lives in a dedicated `player_hand_interaction_provider.gd` instead of a world bootstrap helper.
- Shared interactable storage now has a local `interaction_registry.gd` so player and future NPC systems can query the same world interactables without using an autoload.
- Placeable interactables can now define passive-equipment restrictions and simple yield behavior in `PlaceableObjectDefinition`.
- Prototype trees now use that path: they are registered interactables, require a passive axe, and yield wood.

Still missing before Phase 1 and Phase 2 feel solid:

- richer target acquisition/query structure
- explicit interaction target preview/debugging
- broader reuse of `interactable_component.gd`
- place/attach/pull mode routing
- cleanup of remaining direct interaction branches outside the new layer

### Phase 1: Interaction Foundation

Goal:

Create the shared interaction vocabulary and routing layer.

Deliverables:

- `interaction_types.gd`
- `interaction_target.gd`
- `interaction_context.gd`
- `interaction_manager.gd`

Success condition:

- one place in code can ask "what interaction mode is active?"
- one place can ask "what target is under consideration?"
- input routing no longer needs to hardcode every current/future interaction path inline

### Phase 2: Hand Mode Consolidation

Goal:

Move existing lightweight interact behavior into the new architecture.

Likely first integrations:

- backpack pickup/equip interaction
- crash-ship interaction
- inspect/readout hand target support

Success condition:

- current `interact` behavior routes through `HAND` mode logic
- existing gameplay still works
- `world_input_interaction_controller.gd` becomes thinner, not thicker

### Phase 3: Place Mode Integration

Goal:

Bring free placement under the interaction architecture without replacing the placeable system.

Deliverables:

- `place_interaction_controller.gd`
- placement query helper if needed
- integration with `PlaceablePlacementService`
- item-to-placeable bridge rules using existing `ItemDefinition.placeable_definition`

Success condition:

- free placement is treated as an interaction mode
- placement validation still comes from reusable placeable systems

### Phase 4: Attach Foundations

Goal:

Introduce sockets and compatibility-driven placement.

Deliverables:

- `socket_component.gd`
- `attachable_component.gd`
- `socket_definition.gd`
- `attach_rule_definition.gd`
- `attach_interaction_controller.gd`

Success condition:

- a simple attachable object can connect to a compatible socket
- compatibility is data-driven

### Phase 5: Pull Prototype

Goal:

Prove that physics manipulation belongs in the same interaction framework.

Deliverables:

- `pullable_component.gd`
- `pull_interaction_controller.gd`
- one prototype object with real pull behavior

Success condition:

- the player can begin/end a pull interaction on a valid target
- the result uses physics, not fake drag teleporting

## Current Integration Strategy

To fit the present project shape, use this path:

1. keep `PlayerCursorController` as the visible active-mode mirror
2. let `interaction_manager.gd` become the gameplay owner of mode dispatch
3. let `world_input_interaction_controller.gd` call into the interaction layer instead of directly growing more branches
4. reuse `ItemDefinition` and cursor behavior definitions where they already fit
5. keep `world_scene.gd` limited to wiring references into context/runtime setup

## Open Design Questions

These should stay visible while we build:

1. Should `interaction_manager.gd` be a plain RefCounted service or a scene-owned Node?
2. Should target acquisition be fully centralized, or partly owned by each mode?
3. How much of `MINE_CONE` should migrate into the interaction layer early versus later?
4. Do sockets belong mainly on scene actors under `entity/components/`, or under interaction base components in `systems/interactions/attach/` with thin wrappers?
5. How should item-equipped mode selection interact with contextual override cases, such as a hand interaction being allowed while a place-capable tool is equipped?

## Recommended First Step

Start with the interaction foundation and hand-mode consolidation, not with pull physics.

Reason:

- it exercises the architecture with the lowest risk
- it reuses existing interactions immediately
- it gives us a cleaner place to plug in place/attach/pull later
- it avoids overcommitting to a physics design before the shared interaction contracts are stable

## Working Rules For Future Updates

When this document changes, keep these rules:

- update the phase list when scope changes
- record when a phase becomes partly implemented
- note when a temporary shortcut should later be replaced
- keep the architecture aligned with actual repo structure
- do not quietly drift back toward large scene-owned interaction code
