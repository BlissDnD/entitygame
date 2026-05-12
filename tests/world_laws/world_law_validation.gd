extends Node

const WorldLawEntityDataClass = preload("res://systems/world_laws/world_law_entity_data.gd")
const TemporaryStateDataClass = preload("res://systems/world_laws/temporary_state_data.gd")
const LifecycleDataClass = preload("res://systems/world_laws/lifecycle_data.gd")
const FateDataClass = preload("res://systems/world_laws/fate_data.gd")
const WorldLawEvaluatorClass = preload("res://systems/world_laws/world_law_evaluator.gd")
const WorldLawDebugFormatterClass = preload("res://systems/world_laws/world_law_debug_formatter.gd")


func _ready() -> void:
	print(run_validation())


static func run_validation() -> String:
	var formatter = WorldLawDebugFormatterClass.new()
	var evaluator = WorldLawEvaluatorClass.new()
	var sword: WorldLawEntityData = _create_sword()
	var tree: WorldLawEntityData = _create_tree()
	var output: PackedStringArray = PackedStringArray()

	output.append("[WorldLawValidation] initial sword")
	output.append(formatter.format_entity(sword))

	sword.add_visible_condition(&"broken")
	sword.remove_visible_condition(&"broken")
	sword.set_property(&"temperature", 820.0)
	evaluator.queue_entity(sword)
	evaluator.evaluate_queued()
	output.append("[WorldLawValidation] sword after fire fate")
	output.append(formatter.format_entity(sword))

	tree.add_visible_condition(&"scarred")
	tree.remove_visible_condition(&"scarred")
	evaluator.queue_entity(tree)
	evaluator.evaluate_queued(2.0)
	output.append("[WorldLawValidation] tree while burning")
	output.append(formatter.format_entity(tree))

	evaluator.queue_entity(tree)
	evaluator.evaluate_queued(2.0)
	output.append("[WorldLawValidation] tree after burning expires")
	output.append(formatter.format_entity(tree))

	output.append("[WorldLawValidation] sword lifecycle validation: %s" % _format_validation_errors(sword.validate()))
	output.append("[WorldLawValidation] tree lifecycle validation: %s" % _format_validation_errors(tree.validate()))
	return "\n\n".join(output)


static func _create_sword() -> WorldLawEntityData:
	var sword = WorldLawEntityDataClass.new(&"sword")
	sword.set_property(&"integrity", 1.0)
	sword.set_property(&"temperature", 20.0)
	sword.add_hidden_condition(&"item")
	sword.add_hidden_condition(&"placeable_on_ground")

	var lifecycle_data = LifecycleDataClass.new()
	lifecycle_data.has_lifespan = true
	lifecycle_data.current_stage = &"new"
	lifecycle_data.stages = [&"new", &"worn", &"ruined", &"destroyed"]
	lifecycle_data.terminal_stage = &"destroyed"
	lifecycle_data.lifespan = 100.0
	sword.set_lifecycle_data(lifecycle_data)

	var fire_fate = FateDataClass.new()
	fire_fate.id = &"touch_fire"
	fire_fate.property_minimums[&"temperature"] = 700.0
	fire_fate.add_effect({
		"type": "add_visible_condition",
		"condition": &"fireglazed",
	})
	sword.add_fate(fire_fate)
	sword.clear_dirty()
	return sword


static func _create_tree() -> WorldLawEntityData:
	var tree = WorldLawEntityDataClass.new(&"tree")
	tree.set_property(&"integrity", 1.0)
	tree.set_property(&"flammability", 0.9)
	tree.add_hidden_condition(&"surface_prop")
	tree.add_hidden_condition(&"placeable_on_ground")

	var lifecycle_data = LifecycleDataClass.new()
	lifecycle_data.has_lifespan = true
	lifecycle_data.current_stage = &"sapling"
	lifecycle_data.stages = [&"sapling", &"young", &"mature", &"ancient", &"dead"]
	lifecycle_data.terminal_stage = &"dead"
	lifecycle_data.lifespan = 240.0
	tree.set_lifecycle_data(lifecycle_data)

	var burning_state = TemporaryStateDataClass.new(&"burning", 3.0, 0.8)
	burning_state.add_expiration_effect({
		"type": "add_visible_condition",
		"condition": &"burned",
	})
	tree.add_temporary_state(burning_state)
	tree.clear_dirty()
	return tree


static func _format_validation_errors(errors: PackedStringArray) -> String:
	if errors.is_empty():
		return "valid"

	return ", ".join(errors)
