class_name MiningToolProfiles
extends RefCounted

const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")

const PROFILES := {
	"starter_pickaxe": {
		"mining_power": GameplayTuningClass.DEFAULT_MINING_POWER,
		"mining_shape": GameplayTuningClass.DEFAULT_MINING_SHAPE,
		"mining_radius": GameplayTuningClass.DEFAULT_MINING_RADIUS,
		"mining_falloff_multiplier": GameplayTuningClass.MINING_PROGRESS_FALLOFF,
	}
}


static func get_profile(profile_name: String) -> Dictionary:
	return PROFILES.get(profile_name, PROFILES["starter_pickaxe"]).duplicate(true)
