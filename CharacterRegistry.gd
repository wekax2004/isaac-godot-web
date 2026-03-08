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
			data.starting_items = [14] # Neural Tracker (assuming ID 14 based on previous logic)
			data.description = "High-speed packet interceptor."
			data.passive_description = "Dashing through enemies scrambles their logic."
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
			data.description = "Hardened deep-web sentinel."
			data.passive_description = "Takes halved damage but loses speed per empty Memory Unit."
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
			data.description = "Corrupted buffer overflow exploit."
			data.passive_description = "Tears leave a trail of corrosive blue coolant."
			
	return data
