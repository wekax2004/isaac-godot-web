extends CanvasLayer

var char_id: String = "0x01"
var char_label: Label
var desc_label: Label

func _ready() -> void:
	# Ensure mouse is visible and usable
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if has_node("VersionLabel"):
		$VersionLabel.text = "VER: MASTERWORK_V3.1 (ROOT ACCESS UPDATE)"
	
	_setup_character_select()

func _setup_character_select() -> void:
	# Create a simple UI container for character selection
	var container = VBoxContainer.new()
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
	
	_update_char_preview()

func _on_prev_char() -> void:
	var ids = ["0x01", "0x02", "0x03"]
	var idx = ids.find(char_id)
	idx = (idx - 1 + ids.size()) % ids.size()
	char_id = ids[idx]
	_update_char_preview()

func _on_next_char() -> void:
	var ids = ["0x01", "0x02", "0x03"]
	var idx = ids.find(char_id)
	idx = (idx + 1) % ids.size()
	char_id = idx #ids[idx] - Wait, fixed typo below
	char_id = ids[idx]
	_update_char_preview()

func _update_char_preview() -> void:
	var c = CharacterRegistry.get_character(char_id)
	GameManager.selected_character = c
	char_label.text = "[ SELECT INSTANCE: " + c.character_name + " ]"
	desc_label.text = c.description + "\n\nPASSIVE: " + c.passive_description
	
	# Preview color on version label or similar? 
	# Let's just update the label color
	char_label.modulate = c.sprite_color

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://LevelGenerator.tscn")
