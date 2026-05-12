# Editor-Facing Component Layer

The project keeps backend/domain rules in `systems/`, but gameplay should also be composable in the Godot editor through scenes and Node components.

## Split

- `systems/`: backend data and rules. These remain the source of gameplay logic.
- `entity/`: scene actors and actor-local ownership.
- `entity/components/`: thin Node wrappers around backend systems, with exported Inspector values and signals.
- `resources/`: editable gameplay definitions and data assets.
- `ui/`: display only. UI should bind to components/systems and avoid owning gameplay rules.

## Current Components

- `InventoryComponent` wraps `InventoryData`.
- `StatsComponent` exposes editable movement/gravity/health-style values.
- `InteractionComponent` tracks nearby interactables and calls their `interact()` method.
- `PlayerController` composes `PlayerEquipment`, `PlayerCursorController`, `InventoryComponent`, `StatsComponent`, and `InteractionComponent`.
- `ItemPickup` is an editor-placeable pickup scene backed by `ItemDefinition`.

## Rules

- Do not duplicate backend rules inside components.
- Do not delete existing systems just because a component exists.
- Use `@export` for values designers should edit in the Inspector.
- Use signals for events.
- Use scenes for full actors.
- Keep components small and actor-local.
- Avoid autoloads for actor ownership.

## Example

`entity/player/player.tscn` is a scene-first actor. It owns visible child components in the node tree, while still using existing backend systems:

- `PlayerEquipment`
- `PlayerCursorController`
- `InventoryComponent`
- `StatsComponent`
- `InteractionComponent`

This allows future gameplay scenes to instance a player and tune values in Godot without rewriting `systems/`.
