# AI-Assisted Godot Development System

Scalable Godot 4 project architecture optimized for:

- AI-assisted development
- GitHub workflow
- Codex integration
- Long-term maintainability
- Entity + System hybrid architecture
- Data-driven design

---

# Core Stack

- Godot 4.x
- GDScript
- GitHub
- ChatGPT
- Codex

---

# Project Structure

```text
res://

addons/
assets/
data/
docs/
entity/
prototypes/
resources/
scenes/
scripts/
systems/
tests/
ui/
```

---

# Architecture Rules

## Entity Layer

`entity/`

Contains gameplay actors and gameplay ownership logic.

Examples:
- player
- enemy
- npc
- projectile

---

## Systems Layer

`systems/`

Contains reusable game systems.

Examples:
- input
- save
- combat
- audio
- inventory

---

## UI Layer

`ui/`

Contains UI-only logic.

UI must not own gameplay systems.

---

## Data Layer

`data/` and `resources/`

Contains:
- gameplay definitions
- balancing
- configs
- localization
- Resources

---

# Development Rules

- snake_case naming
- action-based input only
- minimal autoload usage
- modular systems
- no random global state
- no architecture drift

---

# AI Rules

Codex and AI tooling must:

- preserve architecture
- preserve naming conventions
- avoid random folder creation
- avoid unnecessary autoloads
- update docs when systems change

See:
- AGENTS.md
- docs/

---

# Current Status

Early gameplay foundation phase.

The repository already contains playable prototype systems for:
- world generation and room flow
- mining and placement
- dropped items, equipment, and backpacks
- debug tooling
- UI/HUD groundwork

The project is still intentionally small, but it is no longer "empty". Future work should optimize for safe continued growth rather than for one more large all-in-one prototype script.

## How We Continue Building

- Keep `scenes/world/world_scene.gd` as a thin composition root.
- Add new gameplay as small feature-local modules under `systems/<feature>/`.
- Prefer data/resources for tunable content and item/world definitions.
- Keep UI in `ui/` and gameplay ownership in `systems/` or `entity/`.
- Avoid adding new responsibilities to `world_scene.gd`, `world_scene_context_factory.gd`, or `world_scene_operation_helpers.gd` unless the change is strictly scene wiring.
- Keep new files under roughly 500 lines when possible by splitting runtime, queries, rendering, and debug helpers by concern.

## Current Scaling Risk

The main scaling risk is the world orchestration layer under `systems/world/`.

In particular:
- `world_scene.gd` has become the dependency hub for many systems.
- `world_scene_context_factory.gd` is acting as a large callback/context API surface.
- `world_scene_operation_helpers.gd` is becoming a second orchestration layer.
- `world_draw_controller.gd` is the first likely file to outgrow the preferred file-size limit if more drawing concerns are added there directly.

That is manageable now, but future features should be extracted into feature-local systems before those files absorb more ownership.
