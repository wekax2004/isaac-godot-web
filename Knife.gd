extends Area2D

var damage: float = 10.0
var max_range: float = 150.0
var speed: float = 500.0
var return_speed: float = 600.0

var direction: Vector2 = Vector2.ZERO
var player: Node2D = null
var distance_traveled: float = 0.0
var is_returning: bool = false
var size_mult: float = 1.0
var is_poison: bool = false
var is_explosive: bool = false
var has_toxic_blade: bool = false
var splash_scene: PackedScene = preload("res://HitSplash.tscn")

func _ready() -> void:
	add_to_group("player_bullets")
	# Knives pierce by default
	scale = Vector2.ONE * size_mult
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if not is_returning:
		var step = direction * speed * delta
		position += step
		distance_traveled += step.length()
		
		if distance_traveled >= max_range:
			is_returning = true
	else:
		if is_instance_valid(player):
			var dir_to_player = (player.global_position - global_position).normalized()
			global_position += dir_to_player * return_speed * delta
			rotation = dir_to_player.angle()
			
			if global_position.distance_to(player.global_position) < 20.0:
				call_deferred("queue_free")
		else:
			call_deferred("queue_free")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): return
	
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		if is_poison and body.has_method("apply_dot"):
			var dot_dmg = 2.5 if has_toxic_blade else 1.0
			body.apply_dot(dot_dmg, 4.0, Color(0.2, 0.9, 0.1))
		if is_explosive:
			if body.has_method("apply_dot"):
				body.apply_dot(1.5, 2.0, Color(1.0, 0.4, 0.0))
			_explode()
	elif body.is_in_group("obstacles"):
		# In Isaac, the knife doesn't break on walls, it just returns
		is_returning = true

func _draw() -> void:
	# Draw a knife shape
	var knife_color = Color(0.7, 0.75, 0.8) # Steel
	if has_toxic_blade:
		knife_color = Color(0.3, 0.8, 0.2) # Venomous Green
	var handle_color = Color(0.4, 0.25, 0.15) # Wood
	
	# Blade (Triangle)
	var pts = PackedVector2Array([
		Vector2(12, 0),    # Tip
		Vector2(-4, -6),   # Base top
		Vector2(-4, 6)     # Base bottom
	])
	draw_colored_polygon(pts, knife_color)
	draw_polyline(pts, Color(0.5, 0.55, 0.6), 1.0)
	
	# Handle
	draw_rect(Rect2(-8, -2, 4, 4), handle_color)
	# Crossguard
	draw_rect(Rect2(-5, -6, 2, 12), Color(0.3, 0.3, 0.3))

func _explode() -> void:
	SFX.play_explosion()
	var blast_radius = 80.0
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			if global_position.distance_to(e.global_position) <= blast_radius:
				e.take_damage(damage * 0.5)
	
	if splash_scene:
		var splash = splash_scene.instantiate()
		splash.global_position = global_position
		splash.scale = Vector2(2.5, 2.5)
		splash.color = Color(1.0, 0.4, 0.0)
		get_tree().current_scene.call_deferred("add_child", splash)
