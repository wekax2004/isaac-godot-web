extends CharacterBody2D

# Base player stats
@export var bullet_scene: PackedScene

# --- NEW: Signals for Phase 10 HUD ---
signal health_changed(current_health: int, max_health: int)

var can_shoot: bool = true
var current_health: int = 3 # We will sync this with StatManager later


@onready var anim = $AnimationPlayer 
@onready var sprite = $Sprite2D 
@onready var stats = $StatManager # Ensure you added this custom Node as a child of Player!

func _ready() -> void:
	if stats:
		current_health = stats.max_health
		# Delay sending the initial signal until the frame after ready
		call_deferred("emit_signal", "health_changed", current_health, stats.max_health)

func _physics_process(_delta: float) -> void:
	if not stats: return # Don't crash if setup is wrong

	
	handle_movement()
	handle_shooting()
	update_animation()

func handle_movement() -> void:
	var move_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Use the dynamically calculated speed from the StatManager
	velocity = move_dir * stats.speed
	move_and_slide()

func handle_shooting() -> void:
	var shoot_dir := Input.get_vector("shoot_left", "shoot_right", "shoot_up", "shoot_down")
	
	if shoot_dir != Vector2.ZERO and can_shoot:
		fire_tear(shoot_dir.normalized())

func update_animation() -> void:
	if not anim: return
		
	if velocity.length() == 0:
		anim.play("idle")
	elif velocity.x < 0:
		sprite.flip_h = true
		anim.play("walk_side")
	elif velocity.x > 0:
		sprite.flip_h = false
		anim.play("walk_side")
	elif velocity.y < 0:
		anim.play("walk_up")
	elif velocity.y > 0:
		anim.play("walk_down")

func fire_tear(direction: Vector2) -> void:
	if not bullet_scene: return
		
	can_shoot = false
	
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = direction
	
	bullet.damage = stats.damage
	bullet.is_homing = stats.has_homing
	bullet.is_piercing = stats.has_piercing
	bullet.color_override = stats.current_tear_color
	
	get_tree().root.add_child(bullet) 
	
	await get_tree().create_timer(stats.fire_rate).timeout
	can_shoot = true

# --- NEW: Taking Damage Logic ---
func take_damage(amount: int) -> void:
	# Add invincibility frames (i-frames) logic here later!
	current_health -= amount
	
	sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1)
	
	# Notify the HUD!
	health_changed.emit(current_health, stats.max_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	print("Game Over! Player died.")
	get_tree().quit() # or reload current scene

