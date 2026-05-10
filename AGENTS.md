# PROJECT ARCHITECTURE RULES

## Core Architecture

- Gameplay entity logic lives in `entity/`
- Reusable systems live in `systems/`
- Shared helper scripts live in `scripts/`
- UI logic lives in `ui/`
- Structured gameplay data lives in `data/`
- Godot Resources live in `resources/`

---

## Folder Rules

Do not create new top-level folders.

Allowed root folders:

- addons/
- assets/
- data/
- docs/
- entity/
- prototypes/
- resources/
- scenes/
- scripts/
- systems/
- tests/
- ui/

---

## Gameplay Rules

- UI must not contain gameplay ownership logic
- Input must always use InputMap actions
- Avoid hardcoded keyboard keys
- Use signals for loose coupling
- Use Resources for gameplay definitions and balancing

---

## Autoload Rules

Autoloads are only allowed for global services.

Allowed examples:
- SaveManager
- AudioManager
- SettingsManager
- SceneFlowManager

Forbidden examples:
- PlayerManager
- EnemyManager
- GameplayGlobal
- CombatEverything

---

## Naming Rules

Use snake_case everywhere.

Examples:
- player_controller.gd
- enemy_slime.tscn
- inventory_system.gd

---

## AI Safety Rules

Do not:
- restructure architecture
- rename root folders
- change save formats
- create random globals
- move files without reason

Always:
- preserve folder structure
- preserve naming conventions
- keep systems modular
- update documentation when architecture changes