extends Node

# Global Game Manager Singleton

var selected_character: CharacterData = null

func _ready() -> void:
	# Default to 0x01 if nothing selected (for testing/direct scene runs)
	if selected_character == null:
		selected_character = CharacterRegistry.get_character("0x01")
