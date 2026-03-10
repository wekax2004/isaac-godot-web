extends Area2D

enum FamiliarType { ORBITAL, FOLLOWER }
@export var type: FamiliarType = FamiliarType.ORBITAL
@export var familiar_name: String = ""

# Common properties
var player: Node2D = null

# Orbital properties
var orbit_angle: float = 0.0
@export var orbit_speed: float = 3.0
@export var orbit_radius: float = 40.0

# Follower properties
@export var follow_lag: float = 0.2
var position_history: Array[Vector2] = []
var history_timer: float = 0.0

# Combat properties
@export var contact_damage: float = 0.0
@export var shoot_cooldown: float = 0.0
@export var is_blocking: bool = false
var shoot_timer: float = 0.0

var bullet_scene: PackedScene = preload("res://Tear.tscn")

func _ready() -> void:
	add_to_group("familiars")
	set_as_top_level(true) # Ignore parent transform so global lerping works even if child of Player
	orbit_angle = randf() * TAU

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
		
	# Movement logic
	if type == FamiliarType.ORBITAL:
		orbit_angle += orbit_speed * delta
		var offset = Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
		global_position = player.global_position + offset
		
	elif type == FamiliarType.FOLLOWER:
		if familiar_name == "Attack Drone":
			# Aggressively seek nearest enemy, or follow player loosely if none found
			var enemies = get_tree().get_nodes_in_group("enemies")
			var closest = _find_closest(enemies)
			
			if closest and is_instance_valid(closest):
				var dir = (closest.global_position - global_position).normalized()
				global_position += dir * 150.0 * delta # Spiders are fast!
			else:
				# Just jitter around the player
				var orbit = player.global_position + Vector2(cos(Time.get_ticks_msec() * 0.005 + follow_lag), sin(Time.get_ticks_msec() * 0.005 + follow_lag)) * 40.0
				global_position = global_position.lerp(orbit, delta * 5.0)
		else:
			# History-based movement (Isaac style)
			# Record player position
			history_timer += delta
			if history_timer >= 0.05: # Record every 50ms
				history_timer = 0
				position_history.append(player.global_position)
				if position_history.size() > 20: # Keep a short trail
					position_history.remove_at(0)
			
			# Target position is back in time
			# follow_lag = 0.3 means roughly 6 frames of history at 0.05s per frame
			var target_idx = clampi(position_history.size() - 1 - int(follow_lag / 0.05), 0, position_history.size() - 1)
			if position_history.size() > 0:
				var target_pos = position_history[target_idx]
				global_position = global_position.lerp(target_pos, delta * 10.0)
			
	# Shooting logic
	if shoot_cooldown > 0:
		shoot_timer -= delta
		if shoot_timer <= 0:
			var enemies = get_tree().get_nodes_in_group("enemies")
			var target = _find_closest(enemies)
			if target:
				_shoot_at(target)
				shoot_timer = shoot_cooldown

func _find_closest(nodes: Array) -> Node2D:
	var closest: Node2D = null
	var min_dist = 600.0 # Increased aggro range from 400
	for n in nodes:
		if is_instance_valid(n):
			var dist = global_position.distance_to(n.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = n
	return closest

func _shoot_at(target: Node2D) -> void:
	if not bullet_scene: return
	var dir = (target.global_position - global_position).normalized()
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = dir
	
	# Spectral tears for Spectral Drone
	if familiar_name == "Spectral Drone":
		bullet.is_piercing = true
		bullet.damage = 2.0
		bullet.color_override = Color(0.8, 0.9, 1.0, 0.7)
		bullet.modulate = Color(1.0, 1.0, 1.0, 0.7)
		
	get_tree().current_scene.call_deferred("add_child", bullet)

func _on_body_entered(body: Node2D) -> void:
	if contact_damage > 0:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(contact_damage)
			if familiar_name == "Attack Drone":
				queue_free() # Drones explode on impact

func _draw() -> void:
	if familiar_name == "Defense Matrix":
		draw_rect(Rect2(-8, -8, 16, 16), Color(0.2, 0.6, 0.2))
		draw_rect(Rect2(-6, -6, 12, 12), Color(0.3, 0.8, 0.3))
		draw_circle(Vector2(-3, -2), 1.5, Color(1, 1, 1)) # eye
		draw_circle(Vector2(-3, -2), 0.5, Color(0, 0, 0)) # pupil
		
	elif familiar_name == "Spectral Drone":
		# Hovering tech drone
		draw_circle(Vector2(0, -2), 6, Color(0.3, 0.7, 0.9, 0.8))
		draw_rect(Rect2(-6, -2, 12, 8), Color(0.2, 0.6, 0.8, 0.8))
		draw_polygon(PackedVector2Array([Vector2(-6, 6), Vector2(-3, 8), Vector2(0, 6), Vector2(3, 8), Vector2(6, 6)]), PackedColorArray([Color(0.2, 0.6, 0.8, 0.8)]))
		draw_circle(Vector2(-2, -2), 1.5, Color.BLACK)
		draw_circle(Vector2(2, -2), 1.5, Color.BLACK)
		
	elif familiar_name == "Attack Drone":
		# Draw a simple aggressive green attack drone
		draw_circle(Vector2.ZERO, 4, Color(0.4, 0.8, 0.2))
		# Legs
		for i in range(4):
			var leg_y = -3 + (i * 2)
			draw_line(Vector2(-4, leg_y), Vector2(-8, leg_y + 2), Color(0.1, 0.2, 0.6), 1.0)
			draw_line(Vector2(4, leg_y), Vector2(8, leg_y + 2), Color(0.1, 0.2, 0.6), 1.0)
		# Eyes
		draw_circle(Vector2(-2, -1), 1, Color.BLACK)
		draw_circle(Vector2(2, -1), 1, Color.BLACK)
