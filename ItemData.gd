extends Resource
class_name ItemData

@export var item_name: String = "Unknown Item"
@export var description: String = "Provides mysterious buffs."
@export var icon: Texture2D

# Additive Math Modifiers (Flats)
@export var flat_damage: float = 0.0
@export var flat_speed: float = 0.0
@export var flat_health: int = 0
@export var flat_fire_rate: float = 0.0 

# Multiplicative Math Modifiers (Percentages)
# E.g., 1.5 = +50% extra, 0.8 = -20% slower
@export var mult_damage: float = 1.0
@export var mult_speed: float = 1.0
@export var mult_fire_rate: float = 1.0

# Tear Synergy Behavior Flags
@export var is_homing: bool = false
@export var is_piercing: bool = false
@export var tear_color_override: Color = Color.WHITE
