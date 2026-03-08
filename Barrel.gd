extends StaticBody2D

@export var max_health: float = 8.0
var health: float = 8.0

var explosion_scene: PackedScene = preload("res://HitSplash.tscn") # We'll reuse the hit splash visually and add logic

var sprite: Sprite2D = null
var flash_timer: float = 0.0

func _ready() -> void:
	self.scale = Vector2(1.4, 1.4)
	add_to_group("rocks") # Reuse obstacle blockers
	
	health = max_health
	queue_redraw()

func _draw() -> void:
	# Glows bright white/cyan when flashing, otherwise neon blue
	var core_color = Color(0.1, 0.8, 1.0) if flash_timer <= 0 else Color.WHITE 
	
	# Dark metal server casing
	draw_rect(Rect2(-14, -16, 28, 32), Color(0.1, 0.1, 0.15)) 
	draw_rect(Rect2(-10, -12, 20, 24), Color(0.05, 0.05, 0.05)) # Inner shadow
	
	# Glowing plasma cooling rings
	draw_rect(Rect2(-10, -8, 20, 4), core_color)
	draw_rect(Rect2(-10, 4, 20, 4), core_color)
	
	# Red warning indicator light on top
	var warn_color = Color(1.0, 0.2, 0.2) if flash_timer > 0 else Color(0.4, 0.0, 0.0)
	draw_circle(Vector2(0, -14), 2.5, warn_color)

func _physics_process(delta: float) -> void:
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0:
			queue_redraw()

func take_damage(amount: float) -> void:
	health -= amount
	flash_timer = 0.1
	queue_redraw()
	
	if health <= 0:
		explode()

func explode() -> void:
	SFX.play_explosion()
	# 1. Provide visual feedback (reuse massive HitSplash)
	if explosion_scene:
		var splash = explosion_scene.instantiate()
		splash.global_position = global_position
		splash.scale = Vector2(4, 4) # HUGE
		splash.color = Color(0.0, 0.8, 1.0) # Digital burst cyan
		get_tree().current_scene.add_child(splash)
		
	# 2. Deal AoE Damage (Radius 120 pixels)
	var blast_radius = 120.0
	var blast_damage = 5.0
	
	# Hit enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e.has_method("take_damage") and global_position.distance_to(e.global_position) <= blast_radius:
			e.take_damage(blast_damage * 3) # Massive damage to enemies
			
	# Hit player
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.has_method("take_damage") and global_position.distance_to(p.global_position) <= blast_radius:
			p.take_damage(1) # Barrels do 1 heart to the player
			
	# Camera shake
	var level_gen = get_tree().get_first_node_in_group("level_generator")
	if level_gen and level_gen.has_method("shake_camera"):
		level_gen.shake_camera(30.0, 0.3)
			
	queue_free()
