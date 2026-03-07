extends CanvasLayer

func _ready() -> void:
	# Ensure mouse is visible and usable
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if has_node("VersionLabel"):
		$VersionLabel.text = "VER: MASTERWORK_V2.2 (STABILITY UPDATE)"

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://LevelGenerator.tscn")
