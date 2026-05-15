extends Node2D

var definition: PlaceableObjectDefinition = null


func setup_from_definition(next_definition: PlaceableObjectDefinition) -> void:
	definition = next_definition