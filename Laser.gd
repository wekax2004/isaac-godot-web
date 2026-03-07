extends RayCast2D

var damage: float = 3.5
var color: Color = Color(0.2, 1.0, 0.3) # Technology Green
var max_range: float = 600.0
var duration: float = 0.1 # Real technology lasers in Isaac flicker or stay for a frame
var width: float = 4.0
var is_poison: bool = false
var is_explosive: bool = false
var splash_scene: PackedScene = preload("res://HitSplash.tscn")

var hit_enemies = []

func _ready() -> void:
	enabled = true
	target_position = Vector2.RIGHT * max_range
	collision_mask = 2 | 4 
	collide_with_areas = true
	collide_with_bodies = true
	
	# Self-destruct after duration
	await get_tree().create_timer(duration).timeout
	queue_free()

func _process(_delta: float) -> void:
	# Update laser hits every frame while it exists to ensure it follows player and handles collisions
	force_raycast_update()
	_process_laser()
	queue_redraw()

func _process_laser() -> void:
	target_position = Vector2.RIGHT * max_range # Reset to max at start of check
	_apply_piercing_damage()

func _apply_piercing_damage() -> void:
	# Convert current direction and max range to space coordinates
	var space_state = get_world_2d().direct_space_state
	var start = global_position
	var end = global_position + global_transform.x * max_range
	
	# Use intersect_ray in a loop to find all enemies
	var current_start = start
	var enemies_hit = []
	
	for i in range(10):
		var query = PhysicsRayQueryParameters2D.create(current_start, end)
		query.collision_mask = 2 | 4 # Walls and Enemies
		query.exclude = enemies_hit # Don't hit the same enemy twice
		query.collide_with_areas = true
		query.collide_with_bodies = true
		
		var result = space_state.intersect_ray(query)
		if result:
			var collider = result.collider
			var target = null
			
			if collider.is_in_group("enemies"):
				target = collider
			elif collider.get_parent().is_in_group("enemies"):
				target = collider.get_parent()
				
			if target and target.has_method("take_damage"):
				if not target.get_instance_id() in hit_enemies:
					target.call_deferred("take_damage", damage)
					
					if is_poison and target.has_method("apply_dot"):
						target.call_deferred("apply_dot", 1.0, 3.0, Color(0.2, 0.9, 0.1))
					if is_explosive:
						if target.has_method("apply_dot"):
							target.call_deferred("apply_dot", 1.5, 2.0, Color(1.0, 0.4, 0.0))
						_explode_at(result.position)
						
					hit_enemies.append(target.get_instance_id())
				
				enemies_hit.append(collider.get_rid())
				current_start = result.position + global_transform.x * 0.1
			elif collider.is_in_group("rocks") or collider.is_in_group("holes"):
				# Pierce through obstacles!
				enemies_hit.append(collider.get_rid())
				current_start = result.position + global_transform.x * 0.1
			else:
				# Hit a wall, stop here
				target_position = to_local(result.position)
				break
		else:
			break

func _explode_at(pos: Vector2) -> void:
	SFX.play_explosion()
	var blast_radius = 60.0 # Smaller radius for laser pulses
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			if pos.distance_to(e.global_position) <= blast_radius:
				e.take_damage(damage * 0.5)
	
	if splash_scene:
		var splash = splash_scene.instantiate()
		splash.global_position = pos
		splash.scale = Vector2(2, 2)
		splash.color = Color(1.0, 0.4, 0.0)
		get_tree().current_scene.call_deferred("add_child", splash)

func _draw() -> void:
	# Draw the laser beam
	var end_pt = target_position
	
	# Outer glow
	draw_line(Vector2.ZERO, end_pt, color * Color(1, 1, 1, 0.4), width * 2.5)
	# Main beam
	draw_line(Vector2.ZERO, end_pt, color, width)
	# Core
	draw_line(Vector2.ZERO, end_pt, Color.WHITE, width * 0.4)
	
	# Impact spark at the end
	draw_circle(end_pt, width * 1.5, color)
	draw_circle(end_pt, width * 0.7, Color.WHITE)
