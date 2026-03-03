extends CanvasLayer
class_name HUD

@export var full_heart_texture: Texture2D
@export var empty_heart_texture: Texture2D

# The container where we dynamically spawn heart icons
@onready var heart_container = $MarginContainer/VBoxContainer/HeartsHBox

# --- NEW: Phase 11 Boss UI ---
# Add a TextureProgressBar node to the CanvasLayer separately from the player hearts
@onready var boss_health_bar = $BossHealthBar 


@export var full_heart_texture: Texture2D
@export var empty_heart_texture: Texture2D

# The container where we dynamically spawn heart icons
@onready var heart_container = $MarginContainer/VBoxContainer/HeartsHBox

func _ready() -> void:
	# Hide boss bar by default
	if boss_health_bar:
		boss_health_bar.visible = false
		
	# Connect the player's health signal manually if not done in editor inspector
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Using Callables in Godot 4
		if not player.health_changed.is_connected(update_health):
			player.health_changed.connect(update_health)
			
	# Connect to any existing boss (though usually they spawn later, so we handle that event in LevelGenerator/Room)
	var boss = get_tree().get_first_node_in_group("boss")
	if boss:
		register_boss(boss)

# --- NEW: Phase 11 Boss UI ---
func register_boss(boss_node: Node) -> void:
	if not boss_health_bar: return
	
	boss_health_bar.visible = true
	# Connect the signal from the newly spawned boss
	if not boss_node.has_user_signal("boss_health_changed"):
		boss_node.boss_health_changed.connect(_on_boss_health_changed)
	
	# Connect death signal to hide the bar
	if not boss_node.has_user_signal("boss_defeated"):
		boss_node.boss_defeated.connect(_on_boss_defeated)
		
func _on_boss_health_changed(current: int, maximum: int) -> void:
	if boss_health_bar:
		boss_health_bar.max_value = maximum
		
		# Optional: Add a smooth Tween animation instead of snapping the value!
		var tween = create_tween()
		tween.tween_property(boss_health_bar, "value", current, 0.2).set_trans(Tween.TRANS_SINE)

func _on_boss_defeated() -> void:
	if boss_health_bar:
		boss_health_bar.visible = false


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
