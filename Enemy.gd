extends CharacterBody2D
class_name Enemy

enum State { WANDER, CHASE }

@export var move_speed: float = 120.0
@export var max_health: int = 3
@export var chase_range: float = 300.0

# --- NEW: Phase 12 Game Feel ---
@export var splatter_scene: PackedScene # Drag BloodSplatter.tscn here
@export var hit_sound: AudioStream # E.g., a fleshy "thwack.wav"

var current_health: int
var current_state: State = State.WANDER
var player_ref: Node2D

@onready var anim = $AnimationPlayer # Assuming sprite sheet animations
@onready var sprite = $Sprite2D

var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	current_health = max_health
	
	# Try to find the player in the scene tree (adjust the group name if needed)
	player_ref = get_tree().get_first_node_in_group("player")
	
	# Start with a random wander direction
	pick_new_wander_direction()

func _physics_process(delta: float) -> void:
	# 1. State Transitions
	check_state_transitions()
	
	# 2. Execute State Logic
	match current_state:
		State.WANDER:
			handle_wander(delta)
		State.CHASE:
			handle_chase()
			
	move_and_slide()
	update_animation()

func check_state_transitions() -> void:
	if not player_ref: return
	
	var dist_to_player = global_position.distance_to(player_ref.global_position)
	
	if dist_to_player <= chase_range:
		current_state = State.CHASE
	else:
		current_state = State.WANDER

func handle_wander(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0:
		pick_new_wander_direction()
		
	# Apply slight smoothing to wander velocity
	velocity = velocity.lerp(wander_direction * move_speed * 0.5, 0.1)

func pick_new_wander_direction() -> void:
	# Pick a random angle
	var angle = randf() * PI * 2
	wander_direction = Vector2(cos(angle), sin(angle))
	wander_timer = randf_range(1.0, 3.0) # Wander for 1 to 3 seconds

func handle_chase() -> void:
	if player_ref:
		var dir_to_player = (player_ref.global_position - global_position).normalized()
		velocity = dir_to_player * move_speed

func update_animation() -> void:
	if velocity.length() > 5:
		if velocity.x < 0:
			sprite.flip_h = true
		elif velocity.x > 0:
			sprite.flip_h = false
			
# Note: You need an Area2D child node (Hitbox) connected to this function via signal
func _on_hitbox_area_entered(area: Area2D) -> void:
	# If the area that hit us is a Tear
	if area.is_in_group("player_tear"):
		# In a full ECS, tear.damage would be read, but we'll use 1 flat for MVP testing
		take_damage(1)
		
		# Destroy the tear visually
		area.queue_free()

func take_damage(amount: int) -> void:
	current_health -= amount
	
	# --- NEW: Phase 12 Game Feel ---
	# 1. Spawn Visual Blood Splatter
	if splatter_scene:
		var splatter = splatter_scene.instantiate()
		splatter.global_position = global_position
		# Add to the root level instead of the enemy so it doesn't move with the enemy or vanish when the enemy queue_frees
		get_tree().root.add_child(splatter)
		
	# 2. Play Audio Impact
	# We can use a temporary AudioStreamPlayer2D to play the sound and free itself
	if hit_sound:
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = hit_sound
		audio_player.bus = "SFX" # Ensure this matches your Audio Bus layout!
		audio_player.global_position = global_position
		# Auto-destroy when sound finishes
		audio_player.finished.connect(audio_player.queue_free)
		get_tree().root.add_child(audio_player)
		audio_player.play()
	
	# Visual feedback: Flash red briefly
	sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1)
	
	if current_health <= 0:
		die()

func die() -> void:
	print("Enemy defeated!")
	queue_free()
