extends Node
class_name ItemRegistry

# Helper to create an ItemData resource from an ID
static func get_item_data(id: int) -> ItemData:
	var item = ItemData.new()
	
	# Mapping from Item.gd database
	match id:
		14: # Neural Tracker
			item.item_name = "Neural Tracker"
			item.description = "Homing Bullets\nProjectiles seek enemies"
			item.is_homing = true
			item.tear_color_override = Color(0.9, 0.4, 1.0)
		36: # Energy Shield
			item.item_name = "Energy Shield"
			item.description = "Blocks all damage once"
			item.is_active_item = true
			item.max_charges = 3
		21: # Hyper-Accelerator (Placeholder for Liquid Cooling for now)
			item.item_name = "Hyper-Accelerator"
			item.description = "Improved cooling leads to faster fire."
			item.mult_fire_rate = 0.5
		# Add other mappings as needed for starting loadouts
		
	return item
