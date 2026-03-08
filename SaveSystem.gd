extends Node

const SAVE_PATH = "user://save_data.json"

var save_data = {
	"total_memory_units": 0,
	"upgrades": {
		"health_boost": 0,
		"damage_boost": 0,
		"speed_boost": 0
	}
}

func _ready() -> void:
	load_game()

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.get_data()
			if data is Dictionary:
				# Merge to ensure new keys exist
				for key in data.keys():
					if key == "upgrades":
						for up_key in data[key].keys():
							save_data["upgrades"][up_key] = data[key][up_key]
					else:
						save_data[key] = data[key]
		file.close()

func add_memory_units(amount: int) -> void:
	save_data["total_memory_units"] += amount
	save_game()

func get_upgrade_level(upgrade_id: String) -> int:
	return save_data["upgrades"].get(upgrade_id, 0)

func buy_upgrade(upgrade_id: String, cost: int) -> bool:
	if save_data["total_memory_units"] >= cost:
		save_data["total_memory_units"] -= cost
		save_data["upgrades"][upgrade_id] = save_data["upgrades"].get(upgrade_id, 0) + 1
		save_game()
		return true
	return false
