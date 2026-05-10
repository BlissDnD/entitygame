# Input System

## Purpose

The input layer provides a consistent way for player intent to enter the game without tying gameplay code to specific keyboard keys, mouse buttons, or controller buttons.

Its role is to translate raw device input into named actions that gameplay, UI, and systems can respond to through Godot's `InputMap`.

## Action-Based Philosophy

All player input should be routed through named InputMap actions.

Gameplay code should ask whether an action happened, such as `move_left`, `jump`, or `confirm`, instead of checking hardcoded physical keys. This keeps the project flexible as controls expand across keyboards, controllers, accessibility settings, and future rebinding support.

Input actions should describe player intent rather than a specific device.

Examples:

- Use `move_left` instead of `a_key`
- Use `confirm` instead of `enter_key`
- Use `pause` instead of `escape_key`
- Use `primary_action` instead of `left_mouse_button`

## Planned Input Actions

The initial input map should support core movement, interaction, UI navigation, and game flow actions.

### Movement

- `move_left`
- `move_right`
- `move_up`
- `move_down`
- `jump`
- `dash`

### Interaction

- `interact`
- `primary_action`
- `secondary_action`
- `cancel_action`

### Camera

- `camera_left`
- `camera_right`
- `camera_up`
- `camera_down`

### UI

- `ui_up`
- `ui_down`
- `ui_left`
- `ui_right`
- `ui_confirm`
- `ui_cancel`

### Game Flow

- `pause`
- `open_inventory`
- `open_menu`

## Controller Compatibility Goals

The input system should support keyboard and controller use from the beginning.

Controller support should prioritize:

- Standard gamepad face buttons for confirm, cancel, and actions
- Left stick and directional pad support for movement and UI navigation
- Shoulder or trigger buttons for secondary actions where appropriate
- Consistent behavior across gameplay and UI contexts

Input actions should be named broadly enough that keyboard, mouse, and controller bindings can share the same gameplay path.

## Future Rebinding Support

Future input rebinding should build on the same action names rather than introducing device-specific gameplay logic.

Planned rebinding support should consider:

- Saving user-defined bindings through an approved save or settings system
- Resetting bindings to project defaults
- Preventing duplicate bindings when conflicts would break expected controls
- Separating gameplay bindings from UI navigation bindings when needed
- Displaying current bindings in user-facing settings screens

Rebinding should not require gameplay systems to know which physical device triggered an action.
