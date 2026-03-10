extends Node
class_name StatManager

signal stats_changed
signal familiar_added(item_data)
signal active_item_changed(item_data)
signal active_charge_changed(current_charge, max_charge)

# Base configuration
@export var base_damage: float = 3.5
@export var base_speed: float = 300.0
@export var base_max_health: int = 3
@export var base_fire_rate: float = 0.4 # Cooldown in seconds
@export var base_range: float = 400.0 # Distance bullets travel

# Calculated final values
var damage: float
var speed: float
var max_health: int
var fire_rate: float
var range: float

# Derived behaviors
var has_homing: bool = false
var has_piercing: bool = false
var has_shotgun: bool = false
var has_laser: bool = false
var has_knife: bool = false
var has_brimstone: bool = false
var has_parasite: bool = false
var has_rubber_cement: bool = false
var has_poison: bool = false
var has_explosive: bool = false
var has_boomerang: bool = false
var damage_ramp: float = 0.0
var has_split_on_range: bool = false
var has_orbital: bool = false
var tear_size_mult: float = 1.0
var current_tear_color: Color = Color.WHITE
var active_synergies: Dictionary = {}

# Global Floor Progress
var current_floor: int = 1

# Active Item System
var active_item: ItemData = null
var active_item_charge: int = 0

# Inventory array holding ItemData resources
var inventory: Array[ItemData] = []

func _ready() -> void:
	if GameManager.selected_character:
		var c = GameManager.selected_character
		base_max_health = c.health
		base_damage = c.damage
		base_speed = c.speed
		base_fire_rate = c.fire_rate
		base_range = c.range
		
	recalculate_stats()

func add_item(item: ItemData) -> void:
	if not item: return
	
	print("Item picked up: ", item.item_name)
	
	if item.is_active_item:
		active_item = item
		active_item_charge = item.max_charges # Starts fully charged? Or 0? Let's say 0
		active_item_changed.emit(active_item)
		active_charge_changed.emit(active_item_charge, active_item.max_charges)
		return # Note: Active items do NOT go into the passive inventory array
		
	inventory.append(item)
	
	if item.is_familiar:
		familiar_added.emit(item)
		
	recalculate_stats()

func recalculate_stats() -> void:
	# 1. Reset everything to base values
	damage = base_damage
	speed = base_speed
	max_health = base_max_health
	fire_rate = base_fire_rate
	range = base_range
	
	has_homing = false
	has_piercing = false
	has_shotgun = false
	has_laser = false
	has_knife = false
	has_brimstone = false
	has_parasite = false
	has_rubber_cement = false
	has_poison = false
	has_explosive = false
	has_boomerang = false
	damage_ramp = 0.0
	has_split_on_range = false
	has_orbital = false
	tear_size_mult = 1.0
	current_tear_color = Color.WHITE # Or whatever default
	active_synergies = {}
	
	var total_mult_damage = 1.0
	var total_mult_speed = 1.0
	var total_mult_fire_rate = 1.0
	var total_mult_range = 1.0
	
	# 2. Add all flat modifiers first
	for item in inventory:
		damage += item.flat_damage
		speed += item.flat_speed
		max_health += item.flat_health
		fire_rate += item.flat_fire_rate
		range += item.flat_range
		
		# Combine multipliers
		total_mult_damage *= item.mult_damage
		total_mult_speed *= item.mult_speed
		total_mult_fire_rate *= item.mult_fire_rate
		total_mult_range *= item.mult_range
		
		# Set boolean flags (Once it's true, it stays true)
		if item.is_homing: has_homing = true
		if item.is_piercing: has_piercing = true
		if item.is_shotgun: has_shotgun = true
		if item.is_laser: has_laser = true
		if item.is_knife: has_knife = true
		if item.is_brimstone: has_brimstone = true
		if item.is_parasite: has_parasite = true
		if item.is_rubber_cement: has_rubber_cement = true
		if item.is_poison: has_poison = true
		if item.is_explosive: has_explosive = true
		if item.is_boomerang: has_boomerang = true
		damage_ramp += item.damage_ramp
		if item.split_on_range: has_split_on_range = true
		if item.is_orbital: has_orbital = true
		tear_size_mult *= item.tear_size_mult
		
		# Naive color override (latest item wins)
		if item.tear_color_override != Color.WHITE:
			current_tear_color = item.tear_color_override

	# 3. Apply multipliers at the end
	damage *= total_mult_damage * GameManager.perm_damage_mult * GlitchManager.get_glitch_mult("DATA_CORRUPTION")
	speed *= total_mult_speed * GameManager.perm_speed_mult
	fire_rate *= total_mult_fire_rate * GlitchManager.get_glitch_mult("OVERCLOCK")
	range *= total_mult_range
	
	# Permanent Health Bonus
	max_health += GameManager.perm_health_bonus
	
	# Hard clamps to prevent crazy math breakage
	if fire_rate < 0.05: fire_rate = 0.05
	if range < 50.0: range = 50.0
	
	print("Recalculated Stats -> DMG: ", damage, " | SPD: ", speed, " | FIRE RATE: ", fire_rate, " | RANGE: ", range)
	
	# 4. Synergy Detection
	if has_laser and has_homing:
		active_synergies["laser_homing"] = true
	if has_explosive and has_rubber_cement:
		active_synergies["explosive_ricochet"] = true
	if has_knife and has_poison:
		active_synergies["toxic_blade"] = true
	if has_parasite and has_explosive:
		active_synergies["explosive_parasite"] = true
		
	stats_changed.emit()
	if AchievementManager:
		AchievementManager.check_stats(self)
