extends CanvasLayer
class_name PauseMenu

@export var main_menu_scene: PackedScene # Drag MainMenu.tscn here

@onready var panel = $PanelContainer # Need a UI container grouping the pause menu elements

func _ready() -> void:
	# Start hidden!
	if panel:
		panel.visible = false

# Process unhandled input specifically for pausing the game
func _unhandled_input(event: InputEvent) -> void:
	# "ui_cancel" is mapped to Escape by default in Godot
	if event.is_action_pressed("ui_cancel"): 
		toggle_pause()

func toggle_pause() -> void:
	# Flip the tree's paused boolean
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	
	if panel:
		panel.visible = new_pause_state

func _on_resume_button_pressed() -> void:
	toggle_pause()

func _on_menu_button_pressed() -> void:
	# CRITICAL: We must unpause the Engine before going to the Main Menu, 
	# otherwise everything in the new scene will stay permanently frozen!
	get_tree().paused = false
	
	if main_menu_scene:
		get_tree().change_scene_to_packed(main_menu_scene)
