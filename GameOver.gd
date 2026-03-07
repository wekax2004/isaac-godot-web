extends Control
class_name GameOver

@export var level_scene: PackedScene # Drag LevelGenerator.tscn here
@export var main_menu_scene: PackedScene # Drag MainMenu.tscn here

func _ready() -> void:
	# Note: If your level design used process modes aggressively, ensure we are unpaused
	get_tree().paused = false

func _on_restart_button_pressed() -> void:
	if level_scene:
		get_tree().change_scene_to_packed(level_scene)
		
func _on_menu_button_pressed() -> void:
	if main_menu_scene:
		get_tree().change_scene_to_packed(main_menu_scene)
