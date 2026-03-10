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
@export var flat_range: float = 0.0

# Multiplicative Math Modifiers (Percentages)
# E.g., 1.5 = +50% extra, 0.8 = -20% slower
@export var mult_damage: float = 1.0
@export var mult_speed: float = 1.0
@export var mult_fire_rate: float = 1.0
@export var mult_range: float = 1.0

# Tear Synergy Behavior Flags
@export var is_homing: bool = false
@export var is_piercing: bool = false
@export var is_shotgun: bool = false
@export var is_poison: bool = false
@export var is_explosive: bool = false
@export var is_laser: bool = false
@export var is_knife: bool = false
@export var is_brimstone: bool = false
@export var is_parasite: bool = false
@export var is_rubber_cement: bool = false
@export var is_boomerang: bool = false
@export var damage_ramp: float = 0.0 # 0.0 = none, positive = increase with dist, negative = falloff
@export var split_on_range: bool = false
@export var is_orbital: bool = false
@export var tear_size_mult: float = 1.0
@export var tear_color_override: Color = Color.WHITE

# Familiars
@export var is_familiar: bool = false
@export var familiar_name: String = ""

# Active Items
@export var is_active_item: bool = false
@export var max_charges: int = 1

# Performance Upgrades
@export var double_shot_chance: float = 0.0
@export var dash_dist_mult: float = 1.0
