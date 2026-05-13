class_name GravityInteractionController
extends RefCounted


func set_build_mode(build_mode_runtime: BuildModeRuntime, next_build_mode: int) -> Dictionary:
	build_mode_runtime.set_build_mode(next_build_mode)
	return {
		"block_mining_until_left_released": true,
		"build_mode_name": build_mode_runtime.get_build_mode_name(),
	}


func clear_build_mode(build_mode_runtime: BuildModeRuntime) -> Dictionary:
	if not build_mode_runtime.clear_build_mode():
		return {
			"changed": false,
			"block_mining_until_left_released": false,
		}

	return {
		"changed": true,
		"block_mining_until_left_released": true,
	}


func handle_gravity_build_click(
	build_mode_runtime: BuildModeRuntime,
	mining_center_cell: Vector2i,
	ordered_preview_cells: Array[Vector2i],
	get_gravity_field_preview_rect: Callable,
	get_cell_center_world: Callable
) -> Dictionary:
	var click_result: int = build_mode_runtime.handle_gravity_build_click(mining_center_cell, ordered_preview_cells)
	match click_result:
		BuildModeRuntime.BuildClickResult.GRAVITY_FIELD_PLACED:
			return {
				"click_result": click_result,
				"log_message": "[GodModeGravity] gravity field placed: %s" % get_gravity_field_preview_rect.call(),
				"block_mining_until_left_released": true,
				"show_strength_popup": false,
			}
		BuildModeRuntime.BuildClickResult.GRAVITY_POINT_SET:
			return {
				"click_result": click_result,
				"log_message": "[GodModeGravity] gravity point set: %s" % get_cell_center_world.call(mining_center_cell),
				"block_mining_until_left_released": true,
				"show_strength_popup": true,
			}
		BuildModeRuntime.BuildClickResult.GRAVITY_POINT_FAILED:
			return {
				"click_result": click_result,
				"log_message": "[GodModeGravity] Cannot place gravity point outside a gravity field",
				"block_mining_until_left_released": false,
				"show_strength_popup": false,
			}
		_:
			return {
				"click_result": click_result,
				"log_message": "",
				"block_mining_until_left_released": false,
				"show_strength_popup": false,
			}


func select_gravity_strength(build_mode_runtime: BuildModeRuntime, level_index: int) -> Dictionary:
	var strength: float = build_mode_runtime.select_pending_gravity_strength(level_index)
	if strength < 0.0:
		return {
			"success": false,
			"log_message": "[GodModeGravity] No pending gravity point to tune",
			"strength": strength,
		}

	return {
		"success": true,
		"log_message": "[GodModeGravity] gravity point strength: level %d/5 %.0f" % [level_index + 1, strength],
		"strength": strength,
	}
