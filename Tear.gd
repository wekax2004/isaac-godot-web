extends Area2D

# Snapshot of the player's stats at the moment the bullet was fired
@export var speed: float = 500.0
var direction: Vector2 = Vector2.ZERO

var damage: float = 3.5
var max_range: float = 400.0
var distance_traveled: float = 0.0
var is_homing: bool = false
var is_piercing: bool = false
var is_poison: bool = false
var is_explosive: bool = false
var is_parasite: bool = false
var is_rubber_cement: bool = false
var tear_size: float = 1.0
var color_override: Color = Color.WHITE
var can_split: bool = true # Prevent infinite recursion
var has_explosive_ricochet: bool = false

# NEW: Interesting Range Mechanics
var is_boomerang: bool = false
var boomerang_triggered: bool = false
var damage_ramp: float = 0.0 # 0.1 = +10% dmg at max range
var initial_damage: float = 0.0
var split_on_range: bool = false
var is_orbital: bool = false
var orbit_angle: float = 0.0
var trail_timer: float = 0.0

var splash_scene: PackedScene = preload("res://HitSplash.tscn")

@export var shoot_sound: AudioStream # E.g., a "pew.wav"

@onready var sprite = $Sprite2D

func _ready() -> void:
	self.scale = Vector2(1.3, 1.3)
	queue_redraw()
	# Apply visual item synergy changes
	if sprite and color_override != Color.WHITE:
		sprite.modulate = color_override
	
	initial_damage = damage
	orbit_angle = direction.angle()

	var notifier = $VisibleOnScreenNotifier2D
	if notifier:
		notifier.screen_exited.connect(_on_screen_exited)
		
	# ALIGN HITBOX: Scale collision shape to match the visual glow radius (6.0 * tear_size)
	if has_node("CollisionShape2D"):
		var shape_node = $CollisionShape2D
		if shape_node.shape is CircleShape2D:
			# Use a unique shape resource so we don't modify other tears
			shape_node.shape = shape_node.shape.duplicate()
			shape_node.shape.radius = 6.0 * tear_size
		
	area_entered.connect(_on_area_entered)
		
	# Play shoot sound on spawn
	if shoot_sound:
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = shoot_sound
		audio_player.bus = "SFX"
		add_child(audio_player)
		audio_player.play()

func _draw() -> void:
	# Draw a bullet projectile
	var bullet_color = color_override if color_override != Color.WHITE else Color(1.0, 0.85, 0.2)
	if is_poison:
		bullet_color = Color(0.2, 0.9, 0.1) # Green poison tint
	if is_explosive:
		bullet_color = Color(1.0, 0.3, 0.0) # Fiery orange
	var s = tear_size
	# Outer glow
	draw_circle(Vector2.ZERO, 6 * s, Color(1.0, 0.6, 0.1, 0.4))
	# Bullet body
	draw_circle(Vector2.ZERO, 4 * s, bullet_color)
	# Bright core
	draw_circle(Vector2.ZERO, 2 * s, Color(1.0, 1.0, 0.8))

func _physics_process(delta: float) -> void:
	# Toxic Trail synergy
	if is_piercing and is_poison:
		trail_timer -= delta
		if trail_timer <= 0:
			_spawn_poison_cloud()
			trail_timer = 0.15

	# Add logic for Spoon Bender homing effect!
	if is_homing:
		var enemies = get_tree().get_nodes_in_group("enemies")
		if enemies.size() > 0:
			var closest = _find_closest_node(enemies)
			var dir_to_target = (closest.global_position - global_position).normalized()
			# Curve trajectory toward the enemy (slerp or lerp direction)
			direction = direction.lerp(dir_to_target, delta * 5.0).normalized()
			
	# Damage Ramping logic
	if damage_ramp != 0:
		# Scale damage based on distance traveled relative to max range
		var ramp_percent = clamp(distance_traveled / max_range, 0.0, 1.0)
		damage = initial_damage * (1.0 + damage_ramp * ramp_percent)
		tear_size = 1.0 + (damage_ramp * 0.5 * ramp_percent)
		queue_redraw()

	# Orbital logic
	if is_orbital:
		orbit_angle += delta * 5.0
		var orbit_radius = distance_traveled + 50.0
		var player = get_tree().get_first_node_in_group("player")
		if player:
			global_position = player.global_position + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
			distance_traveled += delta * speed * 0.2 # slower progression
		else:
			position += direction * speed * delta
			distance_traveled += (direction * speed * delta).length()
	else:
		var step = direction * speed * delta
		position += step
		distance_traveled += step.length()
	
	# Tear falls and splashes if it travels too far
	if distance_traveled >= max_range:
		if is_boomerang and not boomerang_triggered:
			boomerang_triggered = true
			direction = -direction
			distance_traveled = 0 # reset to allow return
			return
			
		if split_on_range:
			_split_tears()
			
		call_deferred("queue_free")

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
	_spawn_splash()
	call_deferred("queue_free")

func _spawn_splash() -> void:
	if splash_scene:
		var splash = splash_scene.instantiate()
		splash.global_position = global_position
		splash.color = color_override if color_override != Color.WHITE else Color(0.2, 0.8, 1.0) # Default cyan tear splash
		# Add to level directly so it doesn't move with or get deleted by the tear
		get_tree().current_scene.call_deferred("add_child", splash)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("obstacles") or area.is_in_group("explosives") or area.is_in_group("rocks"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
			
		if not is_piercing:
			if is_parasite and can_split:
				_split_tears()
			_spawn_splash()
			call_deferred("queue_free")
		elif is_parasite and can_split:
			_split_tears()

# Make sure you connect the area_entered signal to yourself if you want Tear 
# to handle its own destruction, OR let Enemy.gd handle it like we did in Phase 8!
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): return # don't hit player
	if body.is_in_group("holes"): return # tears fly over holes
	
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		if is_poison and body.has_method("apply_dot"):
			body.apply_dot(1.0, 3.0, Color(0.2, 0.9, 0.1)) # 1 DPS for 3s, Green
		if is_explosive:
			if body.has_method("apply_dot"):
				body.apply_dot(1.5, 2.0, Color(1.0, 0.4, 0.0)) # 1.5 DPS for 2s, Orange/Fire
			_explode()
			
		if not is_piercing:
			if is_parasite and can_split:
				_split_tears()
			_spawn_splash()
			call_deferred("queue_free")
		elif is_parasite and can_split:
			_split_tears()
	elif body.is_in_group("rocks") or body.is_in_group("obstacles"):
		if is_rubber_cement:
			# Calculate bounce direction based on collision normal
			# For simple AABB rooms, we can check position vs room bounds or use move_and_collide
			# But Tears are Areas. Let's approximate or use a simple check.
			# Better: use move_and_collide in _physics_process if is_rubber_cement is true.
			# For now, let's stick to the Area logic and just split if parasite.
			pass
			
		if is_parasite and can_split:
			_split_tears()
			
		if is_rubber_cement:
			# For now, let's just reverse direction if it hits a wall to simulate a "bounce"
			# This is a bit naive but works for simple rectangular rooms.
			direction = -direction
			distance_traveled = 0 # reset distance to allow longer bounce
			
			if has_explosive_ricochet:
				_explode()
				
			return
			
		if is_explosive:
			_explode()
		# Hit a rock or wall
		_spawn_splash()
		call_deferred("queue_free")

func _split_tears() -> void:
	can_split = false # Current tear can't split again
	var angles = [90, -90]
	for angle in angles:
		var new_tear = load("res://Tear.tscn").instantiate()
		new_tear.global_position = global_position
		new_tear.direction = direction.rotated(deg_to_rad(angle))
		new_tear.speed = speed
		new_tear.damage = damage * 0.5 
		new_tear.max_range = max_range * 0.5
		new_tear.tear_size = tear_size * 0.7
		new_tear.is_parasite = false 
		new_tear.can_split = false
		new_tear.color_override = color_override
		
		# Transfer other properties
		new_tear.is_homing = is_homing
		new_tear.is_piercing = is_piercing
		new_tear.is_poison = is_poison
		new_tear.is_explosive = is_explosive
		
		if is_explosive or has_explosive_ricochet:
			new_tear.is_explosive = true
			new_tear.damage = damage * 0.8
		
		get_parent().call_deferred("add_child", new_tear)

func _explode() -> void:
	if VFXManager:
		VFXManager.shake_screen(3.0, 0.15)
	SFX.play_explosion()
	var blast_radius = 100.0
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			if global_position.distance_to(e.global_position) <= blast_radius:
				e.take_damage(damage * 0.5) # 50% splash damage
	# Visual
	if splash_scene:
		var splash = splash_scene.instantiate()
		splash.global_position = global_position
		splash.scale = Vector2(3, 3)
		splash.color = Color(1.0, 0.4, 0.0)
		get_tree().current_scene.call_deferred("add_child", splash)

func _spawn_poison_cloud() -> void:
	if splash_scene:
		var cloud = splash_scene.instantiate()
		cloud.global_position = global_position
		cloud.scale = Vector2(0.8, 0.8)
		cloud.color = Color(0.2, 0.9, 0.1, 0.6)
		get_tree().current_scene.call_deferred("add_child", cloud)
