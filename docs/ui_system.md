# UI System

The UI foundation is scene-first and intentionally lightweight. UI scenes observe gameplay state through bindings and signals; they do not own equipment, cursor, inventory, mining, or world state.

## Folder Structure

- `ui/root/` contains `ui_root.tscn`, the top-level UI layer scene.
- `ui/hud/` contains HUD compositions such as `hud.tscn`, `equipment_hud.tscn`, and `cursor_state_widget.tscn`.
- `ui/widgets/` contains reusable widgets such as `item_icon_slot.tscn`, `outline_button.tscn`, and `keybind_hint.tscn`.
- `ui/themes/` contains `default_ui_theme.tres`.
- `systems/ui/` contains UI helpers that do not own gameplay state.
- `assets/ui/icons/`, `assets/ui/panels/`, and `assets/ui/cursors/` are reserved for imported replacement art.

## UIRoot Layers

`ui/root/ui_root.tscn` is a `CanvasLayer` with these child layers:

- `HUDLayer`
- `OverlayLayer`
- `MenuLayer`
- `TooltipLayer`
- `DebugLayer`

`UIRoot` exposes:

- `show_hud()`
- `hide_hud()`
- `set_hud_visible(value)`
- `register_widget(widget_id, widget)`
- `get_widget(widget_id)`
- `bind_equipment(player_equipment)`
- `bind_cursor_controller(cursor_controller)`

Bindings are forwarded to child widgets that implement matching methods.

## Widget Rules

- Widgets should be standalone scenes.
- Widgets should use exported textures or child `TextureRect` nodes for art that can be replaced in Godot.
- Widgets should update through signals or explicit refresh calls.
- Widgets should not poll every frame unless there is no signal-based alternative.
- Widgets should not mutate gameplay state.
- Widgets should not rely on hardcoded absolute player paths.

## Screen Layout

The runtime UI is split into compact bars:

- The bottom HUD bar contains small always-on information: time, room/status, equipment slots, cursor state, and keybind hints.
- The GodMode overlay uses the same theme as a compact top developer bar. Future debug controls should be added to that bar or to small popup panels, not as large floating menus.

Keep both bars shallow and readable. Avoid full-height debug panels unless they are temporary inspection tools.

## Default Style

The default style is black/white and high contrast:

- dark translucent panels
- white outlines
- white text
- compact spacing
- simple rectangular icon slots

The shared theme is `ui/themes/default_ui_theme.tres`. It uses `StyleBoxFlat` resources so it can be replaced later with a `Theme`, `StyleBoxTexture`, or imported PNG panel art.

## Asset Replacement Workflow

1. Import PNG assets into `assets/ui/icons/`, `assets/ui/panels/`, or `assets/ui/cursors/`.
2. Open the relevant widget scene in Godot.
3. Replace a `TextureRect.texture`, button `icon`, style resource, or the shared `Theme`.
4. Keep the script logic unchanged.

## EquipmentHUD

`ui/hud/equipment_hud.gd` binds to `PlayerEquipment`:

```gdscript
ui_root.bind_equipment(player_equipment)
```

It listens to `equipped_item_changed` and updates `ItemIconSlot` widgets for backpack, primary tool, and weapon. `ItemIconSlot` shows `ItemDefinition.icon` when present, otherwise it falls back to `display_name` or `id`.

## CursorStateWidget

`ui/hud/cursor_state_widget.gd` binds to `PlayerCursorController`:

```gdscript
ui_root.bind_cursor_controller(player_cursor_controller)
```

It listens to `cursor_behavior_changed` and displays the current behavior name, such as `HAND`, `MINE_CONE`, or `PLACE`.

## InputActionDisplay

`systems/ui/input_action_display.gd` reads `InputMap` directly:

```gdscript
InputActionDisplay.get_action_label(&"interact")
```

`KeybindHintWidget` uses this helper so UI hints reflect the actual project input bindings instead of hardcoded keys.

## Do Not Put In UI Scripts

- Gameplay ownership
- Inventory mutation
- Equipment equip/unequip logic
- Cursor behavior decisions
- Mining/building rules
- Save/load behavior
- Autoload-style global state

UI should display state, emit UI intent when needed, and stay easy to reskin.
