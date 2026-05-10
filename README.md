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

Foundation phase.

The repository is currently focused on:
- architecture
- tooling
- workflow
- development pipeline
- AI-safe structure

Gameplay systems will be implemented later.