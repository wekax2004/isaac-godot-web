extends Area2D

# Snapshot of the player's stats at the moment the bullet was fired
@export var speed: float = 500.0
var direction: Vector2 = Vector2.ZERO

var damage: float = 3.5
var is_homing: bool = false
var is_piercing: bool = false
var color_override: Color = Color.WHITE

@export var shoot_sound: AudioStream # E.g., a "pew.wav"

@onready var sprite = $Sprite2D

func _ready() -> void:
	# Apply visual item synergy changes (e.g. Spoon Bender turning tears purple)
	if sprite and color_override != Color.WHITE:
		sprite.modulate = color_override

	var notifier = $VisibleOnScreenNotifier2D
	if notifier:
		notifier.screen_exited.connect(_on_screen_exited)
		
	# Play shoot sound on spawn
	if shoot_sound:
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = shoot_sound
		audio_player.bus = "SFX"
		add_child(audio_player)
		audio_player.play()

func _physics_process(delta: float) -> void:
	# Add logic for Spoon Bender homing effect!
	if is_homing:
		var enemies = get_tree().get_nodes_in_group("enemies")
		if enemies.size() > 0:
			var closest = _find_closest_node(enemies)
			var dir_to_target = (closest.global_position - global_position).normalized()
			# Curve trajectory toward the enemy (slerp or lerp direction)
			direction = direction.lerp(dir_to_target, delta * 5.0).normalized()
			
	position += direction * speed * delta

func _find_closest_node(nodes: Array) -> Node2D:
	var closest_node = null
	var min_dist = INF
	for node in nodes:
		var dist = global_position.distance_squared_to(node.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_node = node
	return closest_node

func _on_screen_exited() -> void:
	queue_free()

# Make sure you connect the area_entered signal to yourself if you want Tear 
# to handle its own destruction, OR let Enemy.gd handle it like we did in Phase 8!
func _on_area_entered(area: Area2D) -> void:
	# If we hit an enemy, do we pierce or die?
	if area.get_parent().is_in_group("enemies"):
		if not is_piercing:
			queue_free() # Standard Isaac tear splats on first enemy hit
