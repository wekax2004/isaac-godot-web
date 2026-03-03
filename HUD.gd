extends CanvasLayer
class_name HUD

@export var full_heart_texture: Texture2D
@export var empty_heart_texture: Texture2D

# The container where we dynamically spawn heart icons
@onready var heart_container = $MarginContainer/VBoxContainer/HeartsHBox

func _ready() -> void:
	# Connect the player's health signal manually if not done in editor inspector
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Using Callables in Godot 4
		if not player.health_changed.is_connected(update_health):
			player.health_changed.connect(update_health)

func update_health(current: int, maximum: int) -> void:
	# Clear existing hearts
	for child in heart_container.get_children():
		child.queue_free()
		
	# Rebuild the display based on max health capacity
	for i in range(maximum):
		var heart = TextureRect.new()
		
		if i < current:
			heart.texture = full_heart_texture
		else:
			heart.texture = empty_heart_texture
			
		# Optional setup: Set custom minimum size so it renders cleanly even if the source image is tiny
		heart.custom_minimum_size = Vector2(32, 32)
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		heart_container.add_child(heart)
