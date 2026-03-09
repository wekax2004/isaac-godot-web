extends CanvasLayer

var char_id: String = "0x01"
var char_label: Label
var desc_label: Label

func _ready() -> void:
	# Ensure mouse is visible and usable
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if has_node("VersionLabel"):
		$VersionLabel.text = "VER: 1.5.0 (THE OMEGA OVERHAUL)"
	
	_setup_character_select()

var char_select_node: Control

func _setup_character_select() -> void:
	# Create a simple UI container for character selection
	var container = VBoxContainer.new()
	char_select_node = container
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	container.position += Vector2(0, 100) # Move below main title
	add_child(container)
	
	char_label = Label.new()
	char_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(char_label)
	
	desc_label = Label.new()
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(400, 0)
	container.add_child(desc_label)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(btn_hbox)
	
	var prev_btn = Button.new()
	prev_btn.text = "< PREV"
	prev_btn.pressed.connect(_on_prev_char)
	btn_hbox.add_child(prev_btn)
	
	var next_btn = Button.new()
	next_btn.text = "NEXT >"
	next_btn.pressed.connect(_on_next_char)
	btn_hbox.add_child(next_btn)
	
	var upgrade_btn = Button.new()
	upgrade_btn.text = "[ PERSISTENT UPGRADES ]"
	upgrade_btn.custom_minimum_size = Vector2(250, 40)
	upgrade_btn.pressed.connect(_show_upgrade_menu)
	container.add_child(upgrade_btn)
	
	var achievements_btn = Button.new()
	achievements_btn.text = "[ CYBER ACHIEVEMENTS ]"
	achievements_btn.custom_minimum_size = Vector2(250, 40)
	achievements_btn.pressed.connect(_show_achievements_menu)
	container.add_child(achievements_btn)
	
	_update_char_preview()

func _show_upgrade_menu() -> void:
	if char_select_node:
		char_select_node.hide()
		
	var menu = Panel.new()
	menu.name = "UpgradeMenu"
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.custom_minimum_size = Vector2(400, 500)
	add_child(menu)
	
	var v_box = VBoxContainer.new()
	v_box.name = "VBoxContainer" # Add name for find_child
	v_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v_box.offset_left = 20
	v_box.offset_right = -20
	v_box.offset_top = 20
	v_box.offset_bottom = -20
	menu.add_child(v_box)
	
	var title = Label.new()
	title.text = "=== SYSTEM OPTIMIZATION ==="
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v_box.add_child(title)
	
	var mem_label = Label.new()
	mem_label.name = "MemCount"
	mem_label.text = "AVAILABLE MEMORY: " + str(SaveSystem.save_data.total_memory_units) + " UNITS"
	mem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mem_label.modulate = Color(0.2, 0.8, 1.0)
	v_box.add_child(mem_label)
	
	var upgrades = [
		{"id": "health_boost", "name": "KERNEL PATCH", "desc": "+1 Start HP", "cost": 50},
		{"id": "damage_boost", "name": "OVERCLOCK", "desc": "+10% Base DMG", "cost": 75},
		{"id": "speed_boost", "name": "FIBER LINK", "desc": "+5% Base SPD", "cost": 40}
	]
	
	for up in upgrades:
		var btn = Button.new()
		var level = SaveSystem.get_upgrade_level(up.id)
		btn.text = up.name + " (Lv. " + str(level) + ")\n" + up.desc + "\nCOST: " + str(up.cost)
		btn.custom_minimum_size = Vector2(300, 80)
		btn.pressed.connect(func(): _buy_upgrade(up.id, up.cost, menu))
		v_box.add_child(btn)
		
	var close_btn = Button.new()
	close_btn.text = "BACK TO TERMINAL"
	close_btn.pressed.connect(func(): 
		menu.queue_free()
		if char_select_node:
			char_select_node.show()
	)
	v_box.add_child(close_btn)

func _show_achievements_menu() -> void:
	if char_select_node:
		char_select_node.hide()
		
	var menu = Panel.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.custom_minimum_size = Vector2(500, 600)
	add_child(menu)
	
	var v_box = VBoxContainer.new()
	v_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v_box.offset_left = 30
	v_box.offset_right = -30
	v_box.offset_top = 30
	v_box.offset_bottom = -30
	menu.add_child(v_box)
	
	var title = Label.new()
	title.text = "=== ACHIEVEMENT DATABASE ==="
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v_box.add_child(title)
	v_box.add_child(HSeparator.new())
	
	if AchievementManager:
		for id in AchievementManager.achievements_def.keys():
			var ach = AchievementManager.achievements_def[id]
			var unlocked = SaveSystem.has_achievement(id)
			
			var h_box = HBoxContainer.new()
			v_box.add_child(h_box)
			
			var status_label = Label.new()
			status_label.text = "[X] " if unlocked else "[ ] "
			status_label.modulate = Color(0, 1, 0) if unlocked else Color(0.4, 0.4, 0.4)
			h_box.add_child(status_label)
			
			var info_vbox = VBoxContainer.new()
			h_box.add_child(info_vbox)
			
			var name_label = Label.new()
			name_label.text = ach.title
			name_label.modulate = Color(1, 0.9, 0.2) if unlocked else Color(0.6, 0.6, 0.6)
			info_vbox.add_child(name_label)
			
			var desc_lbl = Label.new()
			desc_lbl.text = ach.desc
			desc_lbl.add_theme_font_size_override("font_size", 12)
			desc_lbl.modulate = Color(0.8, 0.8, 0.8) if unlocked else Color(0.3, 0.3, 0.3)
			info_vbox.add_child(desc_lbl)
			
			v_box.add_child(HSeparator.new())
			
	var close_btn = Button.new()
	close_btn.text = "DISCONNECT"
	close_btn.pressed.connect(func(): 
		menu.queue_free()
		if char_select_node:
			char_select_node.show()
	)
	v_box.add_child(close_btn)

func _buy_upgrade(id: String, cost: int, menu: Panel) -> void:
	if SaveSystem.buy_upgrade(id, cost):
		GameManager.update_perm_bonuses()
		menu.queue_free()
		_show_upgrade_menu() # Refresh
	else:
		# Flash red if can't afford
		var label = menu.find_child("MemCount")
		if label:
			label.modulate = Color.RED
			get_tree().create_timer(0.5).timeout.connect(label.set_modulate.bind(Color(0.2, 0.8, 1.0)))

func _on_prev_char() -> void:
	var ids = ["0x01", "0x02", "0x03", "0x04", "0x05"]
	var idx = ids.find(char_id)
	idx = (idx - 1 + ids.size()) % ids.size()
	char_id = ids[idx]
	_update_char_preview()

func _on_next_char() -> void:
	var ids = ["0x01", "0x02", "0x03", "0x04", "0x05"]
	var idx = ids.find(char_id)
	idx = (idx + 1) % ids.size()
	char_id = ids[idx]
	_update_char_preview()

func _update_char_preview() -> void:
	var c = CharacterRegistry.get_character(char_id)
	GameManager.selected_character = c
	
	var is_unlocked = true
	if c.unlocked_by_achievement != "":
		is_unlocked = SaveSystem.has_achievement(c.unlocked_by_achievement)
		
	if is_unlocked:
		char_label.text = "[ SELECT INSTANCE: " + c.character_name + " ]"
		desc_label.text = c.description + "\n\nPASSIVE: " + c.passive_description
		char_label.modulate = c.sprite_color
	else:
		char_label.text = "[ INSTANCE LOCKED ]"
		var req = c.unlocked_by_achievement.to_upper().replace("_", " ")
		desc_label.text = "ERROR: ACCESS DENIED\nREQUIREMENT: UNLOCK " + req + " ACHIEVEMENT"
		char_label.modulate = Color(0.4, 0.4, 0.4)
		
	# Find start button in children or by name
	for child in get_children():
		if child is Button and (child.text.contains("EXECUTE") or child.text.contains("LOCKED")):
			child.disabled = not is_unlocked
			child.text = "EXECUTE: " + c.character_name if is_unlocked else "SYSTEM LOCKED"
			break

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://LevelGenerator.tscn")
