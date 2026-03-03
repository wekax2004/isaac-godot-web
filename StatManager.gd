extends Node
class_name StatManager

# Base configuration
@export var base_damage: float = 3.5
@export var base_speed: float = 300.0
@export var base_max_health: int = 3
@export var base_fire_rate: float = 0.4 # Cooldown in seconds

# Calculated final values
var damage: float
var speed: float
var max_health: int
var fire_rate: float

# Derived behaviors
var has_homing: bool = false
var has_piercing: bool = false
var current_tear_color: Color = Color.WHITE

# Inventory array holding ItemData resources
var inventory: Array[ItemData] = []

func _ready() -> void:
	recalculate_stats()

func add_item(item: ItemData) -> void:
	if not item: return
	
	inventory.append(item)
	print("Item picked up: ", item.item_name)
	recalculate_stats()

func recalculate_stats() -> void:
	# 1. Reset everything to base values
	damage = base_damage
	speed = base_speed
	max_health = base_max_health
	fire_rate = base_fire_rate
	
	has_homing = false
	has_piercing = false
	current_tear_color = Color.WHITE # Or whatever default
	
	var total_mult_damage = 1.0
	var total_mult_speed = 1.0
	var total_mult_fire_rate = 1.0
	
	# 2. Add all flat modifiers first
	for item in inventory:
		damage += item.flat_damage
		speed += item.flat_speed
		max_health += item.flat_health
		fire_rate += item.flat_fire_rate
		
		# Combine multipliers
		total_mult_damage *= item.mult_damage
		total_mult_speed *= item.mult_speed
		total_mult_fire_rate *= item.mult_fire_rate
		
		# Set boolean flags (Once it's true, it stays true)
		if item.is_homing: has_homing = true
		if item.is_piercing: has_piercing = true
		
		# Naive color override (latest item wins)
		if item.tear_color_override != Color.WHITE:
			current_tear_color = item.tear_color_override

	# 3. Apply multipliers at the end
	damage *= total_mult_damage
	speed *= total_mult_speed
	fire_rate *= total_mult_fire_rate
	
	# Hard clamps to prevent crazy math breakage
	if fire_rate < 0.05: fire_rate = 0.05
	
	print("Recalculated Stats -> DMG: ", damage, " | SPD: ", speed, " | FIRE RATE: ", fire_rate)
