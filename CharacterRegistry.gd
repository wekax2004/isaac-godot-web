extends Node

static func get_character(id: String) -> CharacterData:
	var data = CharacterData.new()
	
	match id:
		"0x01":
			data.character_name = "SCRAMBLE.EXE"
			data.character_id = "0x01"
			data.health = 2
			data.damage = 3.0
			data.speed = 340.0
			data.fire_rate = 0.4
			data.range = 400.0
			data.sprite_color = Color(0.3, 0.9, 1.0) # Cyan
			data.starting_items = [5] # Neural Tracker (ID 5)
			data.description = "High-velocity packet interceptor optimized for node traversal."
			data.passive_description = "DASH: Colliding with enemy processes causes a BUFFER_OVERFLOW, scrambling their logic/AI."
		"0x02":
			data.character_name = "ENCRYPTOR"
			data.character_id = "0x02"
			data.health = 5
			data.damage = 4.0
			data.speed = 240.0
			data.fire_rate = 0.6
			data.range = 350.0
			data.sprite_color = Color(0.2, 0.8, 0.2) # Green
			data.starting_items = [] # Shield cell (ID TBD)
			data.description = "Reinforced deep-web firewall with high-density data buffers."
			data.passive_description = "PASSIVE: 50% Damage reduction. Speed decays as Memory Units (HP) are depleted."
		"0x03":
			data.character_name = "OVERFLOW"
			data.character_id = "0x03"
			data.health = 3
			data.damage = 3.5
			data.speed = 300.0
			data.fire_rate = 0.45
			data.range = 450.0
			data.sprite_color = Color(1.0, 0.2, 0.2) # Red
			data.starting_items = [] # Liquid cooling (ID TBD)
			data.description = "Unstable buffer overflow exploit. Volatile and high-throughput."
			data.passive_description = "PASSIVE: Movement leaves a persistent trail of corrosive coolant fluid."
		"0x04":
			data.character_name = "OVERCLOCKER"
			data.character_id = "0x04"
			data.health = 1
			data.damage = 3.0
			data.speed = 360.0
			data.fire_rate = 0.15
			data.range = 380.0
			data.sprite_color = Color(1.0, 0.8, 0.0) # Gold/Yellow
			data.unlocked_by_achievement = "overclocker"
			data.description = "Illegal high-voltage experimental core. Unstable but lethal."
			data.passive_description = "PASSIVE: Fire rate surpasses all safety limiters. 1 HP cap (CORE_CRITICAL)."
		"0x05":
			data.character_name = "SYSTEM ADMIN"
			data.character_id = "0x05"
			data.health = 3
			data.damage = 4.0
			data.speed = 300.0
			data.fire_rate = 0.4
			data.range = 400.0
			data.sprite_color = Color(1.0, 1.0, 1.0) # White/Silver
			data.starting_items = [32] # Debug Console
			data.unlocked_by_achievement = "root_access"
			data.description = "Root-level administrative presence. Full authorization granted."
			data.passive_description = "PASSIVE: Starts with full floor data visualization (Debug Console)."
			
	return data
