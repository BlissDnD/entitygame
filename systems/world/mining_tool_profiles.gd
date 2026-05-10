class_name MiningToolProfiles
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")

const PROFILES := {
	"starter_pickaxe": {
		"mining_power": 10.0,
		"mining_shape": WorldConstantsClass.ToolShape.SQUARE,
		"mining_radius": 2,
		"mining_falloff_multiplier": 0.45,
	}
}


static func get_profile(profile_name: String) -> Dictionary:
	return PROFILES.get(profile_name, PROFILES["starter_pickaxe"]).duplicate(true)
