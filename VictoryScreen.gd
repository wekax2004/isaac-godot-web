extends Control

func _ready() -> void:
	# Enable mouse for clicking the restart button
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_button_pressed() -> void:
	# Reload the main game loop
	get_tree().change_scene_to_file("res://LevelGenerator.tscn")
