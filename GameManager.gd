extends Node

# Global Game Manager Singleton

var selected_character: CharacterData = null

# Permanent Meta-Upgrades
var perm_health_bonus: int = 0
var perm_damage_mult: float = 1.0
var perm_speed_mult: float = 1.0

func _ready() -> void:
	# Default to 0x01 if nothing selected (for testing/direct scene runs)
	if selected_character == null:
		selected_character = CharacterRegistry.get_character("0x01")
	
	update_perm_bonuses()

func update_perm_bonuses() -> void:
	perm_health_bonus = SaveSystem.get_upgrade_level("health_boost")
	perm_damage_mult = 1.0 + (SaveSystem.get_upgrade_level("damage_boost") * 0.1)
	perm_speed_mult = 1.0 + (SaveSystem.get_upgrade_level("speed_boost") * 0.05)
