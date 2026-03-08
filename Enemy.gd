extends CharacterBody2D
class_name Enemy

enum EnemyType { CHASER, SHOOTER, TANK, FLANKER, HOPPER, FLY, FATTY, SNARE_BOT, PROXY_DRONE, GLITCH_WRAITH }
signal enemy_died

@export var enemy_type: EnemyType = EnemyType.CHASER

# Stats per type (set in _ready based on type)
var max_health: float = 3.0
var health: float = 3.0
var move_speed: float = 80.0
var contact_damage: int = 1
var knockback_strength: float = 200.0

# AI state
var player: Node2D = null
var direction: Vector2 = Vector2.ZERO
var can_shoot: bool = true
var flanker_angle: float = 0.0
var flanker_dashing: bool = false
var flanker_dash_timer: float = 0.0

# Bullet scene for Shooter type
var bullet_scene: PackedScene = preload("res://EnemyBullet.tscn")
var pickup_scene: PackedScene = preload("res://Pickup.tscn")
var splash_scene: PackedScene = preload("res://HitSplash.tscn")
var blood_stain_scene: Resource = preload("res://BloodStain.gd") 

# Damage flash
var flash_timer: float = 0.0
var is_shielded: bool = false
var shield_source: Node2D = null

# Damage-over-Time (DoT) System
var dot_dps: float = 0.0
var dot_timer: float = 0.0
var is_dot_active: bool = false
var dot_color: Color = Color.WHITE
var dot_tick_timer: float = 0.0 # Time until next tick

var scramble_timer: float = 0.0

# Snares/Wraith state
var snare_cooldown: float = 0.0
var phase_timer: float = 0.0
var is_phasing: bool = false
var teleport_cooldown: float = 0.0

var parent_room: Node2D = null
@onready var sprite = $Sprite2D # Ensure Sprite2D exists

func scramble(duration: float) -> void:
	scramble_timer = duration
	modulate = Color(1, 1, 0) # Highlight yellow for scramble

func _ready() -> void:
	add_to_group("enemies")
	
	# Scale health based on floor level
	if parent_room and parent_room.get("floor_level"):
		max_health += (parent_room.floor_level - 1) * 1.5
		health = max_health
	
	queue_redraw()
	
	# Determine parent room
	parent_room = get_parent()
	
	# Set stats based on type
	match enemy_type:
		EnemyType.CHASER:
			max_health = 4.0
			move_speed = 90.0
			contact_damage = 1
		EnemyType.SHOOTER:
			max_health = 5.0
			move_speed = 40.0
			contact_damage = 1
		EnemyType.TANK:
			max_health = 12.0
			move_speed = 30.0
			contact_damage = 2
		EnemyType.FLANKER:
			max_health = 2.0
			move_speed = 120.0
			contact_damage = 1
			flanker_angle = randf() * TAU
		EnemyType.HOPPER:
			max_health = 3.0
			move_speed = 150.0 # Jump speed
			contact_damage = 1
		EnemyType.FLY:
			max_health = 1.0
			move_speed = 100.0
			contact_damage = 1
		EnemyType.FATTY:
			max_health = 20.0
			move_speed = 40.0 # Base speed
			contact_damage = 2
		EnemyType.SNARE_BOT:
			max_health = 6.0
			move_speed = 50.0
			contact_damage = 1
		EnemyType.PROXY_DRONE:
			max_health = 4.0
			move_speed = 100.0
			contact_damage = 0 # No touch damage
		EnemyType.GLITCH_WRAITH:
			max_health = 8.0
			move_speed = 70.0
			contact_damage = 1
	
	health = max_health
	
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		match enemy_type:
			EnemyType.CHASER:
				sprite.texture = preload("res://assets/enemy_chaser_mainframe.png")
			EnemyType.SHOOTER:
				sprite.texture = preload("res://assets/enemy_shooter_mainframe.png")
			EnemyType.TANK:
				sprite.texture = preload("res://assets/enemy_tank_mainframe.png")
			EnemyType.FLANKER:
				sprite.texture = preload("res://assets/sprites/pulse_drone.png")
			EnemyType.HOPPER:
				sprite.texture = preload("res://assets/sprites/jump_bot.png")
			EnemyType.FLY:
				sprite.texture = preload("res://assets/enemy_fly_mainframe.png")
				# Flying enemies skip hole collision
				set_collision_mask_value(7, false) 
			EnemyType.FATTY:
				sprite.texture = preload("res://assets/sprites/shield_bot.png")
			EnemyType.SNARE_BOT:
				sprite.texture = preload("res://assets/sprites/scrap_bot.png")
			EnemyType.PROXY_DRONE:
				sprite.texture = preload("res://assets/sprites/pulse_drone.png")
			EnemyType.GLITCH_WRAITH:
				sprite.texture = preload("res://assets/sprites/scrap_bot.png")
			_:
				sprite.texture = preload("res://assets/enemy_basic.png")
			
		# This magic math forces ANY image to perfectly fit the target size
		if sprite.texture:
			var tex_size = sprite.texture.get_size()
			# Default size for basic mobs (Chaser, Shooter, Flanker)
			var target_size = Vector2(60.0, 60.0) 
			
			# Change the target box size based on what enemy spawned!
			if enemy_type == EnemyType.TANK: # Tank (Needs to be huge)
				target_size = Vector2(110.0, 110.0)
			elif enemy_type == EnemyType.FLY: # Nanite Fly (Needs to be tiny)
				target_size = Vector2(45.0, 45.0)
				
			sprite.scale = target_size / tex_size
			
		print("Enemy Spawned: Type ", enemy_type, " (" , EnemyType.keys()[enemy_type], ") Texture: ", sprite.texture.resource_path)
	
	# Find player
	await get_tree().process_frame
	
	# Ground enemies (non-FLY) should be blocked by holes (Layer 7)
	if enemy_type != EnemyType.FLY:
		set_collision_mask_value(7, true)
		
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	z_index = 5 # Draw on top of spikes

func _draw() -> void:
	return # Use Sprite2D instead
	match enemy_type:
		EnemyType.CHASER:
			_draw_chaser()
		EnemyType.SHOOTER:
			_draw_shooter()
		EnemyType.TANK:
			_draw_tank()
		EnemyType.FLANKER:
			_draw_flanker()
		EnemyType.HOPPER:
			_draw_hopper()
		EnemyType.FLY:
			_draw_fly()
		EnemyType.FATTY:
			_draw_fatty()

func _draw_chaser() -> void:
	var c = Color(0.9, 0.15, 0.1) if flash_timer <= 0 else Color.WHITE
	# Body
	draw_circle(Vector2.ZERO, 12, c)
	# Angry eyes
	draw_circle(Vector2(-4, -3), 3, Color.BLACK)
	draw_circle(Vector2(4, -3), 3, Color.BLACK)
	draw_circle(Vector2(-4, -4), 1.5, Color(1.0, 0.9, 0.2))
	draw_circle(Vector2(4, -4), 1.5, Color(1.0, 0.9, 0.2))
	# Mouth
	draw_rect(Rect2(-5, 3, 10, 3), Color(0.3, 0.0, 0.0))

func _draw_shooter() -> void:
	var c = Color(0.6, 0.15, 0.7) if flash_timer <= 0 else Color.WHITE
	# Body (slightly larger, with "cannon")
	draw_circle(Vector2.ZERO, 14, c)
	draw_circle(Vector2.ZERO, 10, Color(0.4, 0.1, 0.5))
	# Eye (single targeting eye)
	draw_circle(Vector2(0, -2), 4, Color(1.0, 0.3, 0.3))
	draw_circle(Vector2(0, -2), 2, Color.BLACK)
	# Cannon barrel (points toward player if available)
	var aim_dir = Vector2.RIGHT
	if player:
		aim_dir = (player.global_position - global_position).normalized()
	var barrel_start = aim_dir * 10
	var barrel_end = aim_dir * 20
	draw_line(barrel_start, barrel_end, Color(0.3, 0.3, 0.3), 4.0)

func _draw_tank() -> void:
	var c = Color(0.1, 0.45, 0.15) if flash_timer <= 0 else Color.WHITE
	# Big armored body
	draw_circle(Vector2.ZERO, 18, Color(0.05, 0.3, 0.1))
	draw_circle(Vector2.ZERO, 15, c)
	# Armor plates
	draw_rect(Rect2(-12, -12, 24, 6), Color(0.15, 0.55, 0.2))
	draw_rect(Rect2(-12, 6, 24, 6), Color(0.15, 0.55, 0.2))
	# Small mean eyes
	draw_circle(Vector2(-5, -2), 2, Color(1.0, 0.2, 0.2))
	draw_circle(Vector2(5, -2), 2, Color(1.0, 0.2, 0.2))

func _draw_flanker() -> void:
	var c = Color(1.0, 0.55, 0.1) if flash_timer <= 0 else Color.WHITE
	# Small, fast, triangular
	var points = PackedVector2Array([
		Vector2(0, -10),
		Vector2(-8, 8),
		Vector2(8, 8)
	])
	draw_colored_polygon(points, c)
	# Inner highlight
	var inner = PackedVector2Array([
		Vector2(0, -6),
		Vector2(-4, 5),
		Vector2(4, 5)
	])
	draw_colored_polygon(inner, Color(1.0, 0.8, 0.3))
	# Eye
	draw_circle(Vector2(0, 0), 2, Color.BLACK)

func _draw_hopper() -> void:
	var c = Color(0.3, 0.3, 0.3) if flash_timer <= 0 else Color.WHITE
	# Spider-like body
	draw_circle(Vector2.ZERO, 8, c)
	# Legs
	for i in range(4):
		var ang = PI/4 + (i * PI/2)
		draw_line(Vector2.ZERO, Vector2(cos(ang), sin(ang)) * 14, c, 2.0)

func _draw_fly() -> void:
	var c = Color(0.1, 0.1, 0.1) if flash_timer <= 0 else Color.WHITE
	# Small black dot
	draw_circle(Vector2.ZERO, 4, c)
	# Wings
	draw_circle(Vector2(-4, -2), 3, Color(0.8, 0.8, 1.0, 0.5))
	draw_circle(Vector2(4, -2), 3, Color(0.8, 0.8, 1.0, 0.5))

func _draw_fatty() -> void:
	var c = Color(0.9, 0.7, 0.6) if flash_timer <= 0 else Color.WHITE
	# Large fleshy body
	draw_circle(Vector2.ZERO, 22, c)
	# Belly button
	draw_circle(Vector2(0, 5), 3, Color(0.7, 0.5, 0.4))
	# Tiny eyes
	draw_circle(Vector2(-6, -8), 2, Color.BLACK)
	draw_circle(Vector2(6, -8), 2, Color.BLACK)

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
		
	# Only act if player is in the same room (distance check)
	# Assuming room size is ~800x600, wait until distance is quite large
	if parent_room and player.global_position.distance_to(parent_room.global_position) > 1200.0:
		return
	
	# Flash timer
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0:
			queue_redraw()
	
	# DoT Ticks (Poison/Fire/etc)
	# Scramble Logic
	if scramble_timer > 0:
		scramble_timer -= delta
		if scramble_timer <= 0:
			modulate = Color.WHITE
			player = get_tree().get_nodes_in_group("player")[0]
		else:
			# Find a new target (other enemy)
			var others = get_tree().get_nodes_in_group("enemies")
			if others.size() > 1:
				var best_target = null
				var best_dist = 100000.0
				for other in others:
					if other == self: continue
					var d = global_position.distance_to(other.global_position)
					if d < best_dist:
						best_dist = d
						best_target = other
				if best_target:
					player = best_target # Redirect AI targeting
	
	# Reset shield status - will be reapplied by Proxies this frame
	is_shielded = false
	
	match enemy_type:
		EnemyType.CHASER:
			_ai_chaser(delta)
		EnemyType.SHOOTER:
			_ai_shooter(delta)
		EnemyType.TANK:
			_ai_tank(delta)
		EnemyType.FLANKER:
			_ai_flanker(delta)
		EnemyType.HOPPER:
			_ai_hopper(delta)
		EnemyType.FLY:
			_ai_fly(delta)
		EnemyType.FATTY:
			_ai_fatty(delta)
		EnemyType.SNARE_BOT:
			_ai_snare_bot(delta)
		EnemyType.PROXY_DRONE:
			_ai_proxy_drone(delta)
		EnemyType.GLITCH_WRAITH:
			_ai_glitch_wraith(delta)
			
	_check_contact_damage()

func _check_contact_damage() -> void:
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.call_deferred("take_damage", contact_damage)

func _ai_chaser(delta: float) -> void:
	# Simply chase the player
	var dir_to_player = (player.global_position - global_position).normalized()
	velocity = dir_to_player * move_speed
	move_and_slide()

func _ai_shooter(delta: float) -> void:
	var dist = global_position.distance_to(player.global_position)
	var dir_to_player = (player.global_position - global_position).normalized()
	
	# Keep distance: move closer if far, back away if too close
	if dist > 200:
		velocity = dir_to_player * move_speed
	elif dist < 120:
		velocity = -dir_to_player * move_speed
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	# Shoot at player
	if can_shoot:
		_shoot_at_player()
	
	queue_redraw() # Redraw to update cannon direction

func _ai_tank(delta: float) -> void:
	# Slowly approach the player
	var dir_to_player = (player.global_position - global_position).normalized()
	velocity = dir_to_player * move_speed
	move_and_slide()

func _ai_flanker(delta: float) -> void:
	var dist = global_position.distance_to(player.global_position)
	
	if flanker_dashing:
		# Dash toward player
		var dir_to_player = (player.global_position - global_position).normalized()
		velocity = dir_to_player * move_speed * 1.8
		flanker_dash_timer -= delta
		if flanker_dash_timer <= 0:
			flanker_dashing = false
	else:
		# Circle around player
		flanker_angle += delta * 2.5
		var orbit_radius = 130.0
		var target = player.global_position + Vector2(cos(flanker_angle), sin(flanker_angle)) * orbit_radius
		var dir_to_target = (target - global_position).normalized()
		velocity = dir_to_target * move_speed
		
		# Random dash chance
		if randf() < delta * 0.5: # ~once every 2 seconds
			flanker_dashing = true
			flanker_dash_timer = 0.4
			
	move_and_slide()

var hopper_timer: float = 0.0
var is_jumping: bool = false
func _ai_hopper(delta: float) -> void:
	hopper_timer -= delta
	if hopper_timer <= 0:
		if is_jumping:
			is_jumping = false
			velocity = Vector2.ZERO
			hopper_timer = randf_range(0.5, 1.5) # Wait time
		else:
			is_jumping = true
			var dir = (player.global_position - global_position).normalized()
			velocity = dir * move_speed
			hopper_timer = 0.4 # Jump duration
	
	if is_jumping:
		move_and_slide()
	queue_redraw()

func _ai_fly(delta: float) -> void:
	# Keep a tight orbit or swarm
	flanker_angle += delta * 4.0
	var orbit_radius = 60.0 + sin(Time.get_ticks_msec() * 0.005) * 20.0
	var target = player.global_position + Vector2(cos(flanker_angle), sin(flanker_angle)) * orbit_radius
	var dir_to_target = (target - global_position).normalized()
	velocity = dir_to_target * move_speed
	move_and_slide()

var fatty_charging: bool = false
func _ai_fatty(delta: float) -> void:
	var dir_to_player = (player.global_position - global_position)
	
	if fatty_charging:
		move_and_slide()
		if get_slide_collision_count() > 0 or dir_to_player.length() > 600:
			fatty_charging = false
			velocity = Vector2.ZERO
	else:
		# Slow approach or initiate charge if aligned
		if abs(dir_to_player.x) < 20 or abs(dir_to_player.y) < 20:
			fatty_charging = true
			velocity = dir_to_player.normalized() * move_speed * 3.0
		else:
			velocity = dir_to_player.normalized() * move_speed
			move_and_slide()

func _ai_snare_bot(delta: float) -> void:
	var dist = global_position.distance_to(player.global_position)
	var dir_to_player = (player.global_position - global_position).normalized()
	
	# Keep distance
	if dist > 300:
		velocity = dir_to_player * move_speed
	elif dist < 200:
		velocity = -dir_to_player * move_speed
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	snare_cooldown -= delta
	if snare_cooldown <= 0 and dist < 450:
		_shoot_snare()
		snare_cooldown = 3.5

func _ai_glitch_wraith(delta: float) -> void:
	phase_timer -= delta
	if phase_timer <= 0:
		is_phasing = !is_phasing
		phase_timer = 2.0 if is_phasing else 1.5
		if is_phasing:
			modulate.a = 0.2
			collision_layer = 0 # Phase through things? 
			# Actually just collision_mask to avoid being hit
		else:
			modulate.a = 1.0
			collision_layer = 4 # Reset to enemy layer
			
	teleport_cooldown -= delta
	if not is_phasing and teleport_cooldown <= 0:
		# Teleport behind or near player
		var offset = Vector2(randf_range(-150, 150), randf_range(-150, 150))
		global_position = player.global_position + offset
		teleport_cooldown = 4.0
		# Visual effect for teleport
		if parent_room:
			parent_room.queue_redraw()
	
	if not is_phasing:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()
		
		if can_shoot and randf() < delta * 0.5:
			_shoot_at_player()
	else:
		# Float slowly while phasing
		velocity = velocity.lerp(Vector2.ZERO, delta * 2.0)
		move_and_slide()

func _shoot_at_player() -> void:
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.direction = (player.global_position - global_position).normalized()
		bullet.speed = 250.0
		get_tree().current_scene.call_deferred("add_child", bullet)
	
func _shoot_snare() -> void:
	snare_cooldown = 2.0
	# Placeholder: Stops the crash until we build the snare bullet!
	
func _ai_proxy_drone(delta: float) -> void:
	# Orbit the player or stay near other enemies
	# Let's find a nearby enemy to protect
	var target_enemy = null
	var others = get_tree().get_nodes_in_group("enemies")
	for other in others:
		if other == self: continue
		if other.enemy_type == EnemyType.PROXY_DRONE: continue
		target_enemy = other
		break
		
	if target_enemy:
		var dir = (target_enemy.global_position - global_position).normalized()
		var dist = global_position.distance_to(target_enemy.global_position)
		if dist > 60:
			velocity = dir * move_speed
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		
		# Shield them
		if dist < 150:
			target_enemy.apply_shield(self)
	else:
		_ai_fly(delta) # Fallback to fly AI if alone

func apply_shield(source: Node2D) -> void:
	is_shielded = true
	shield_source = source

func take_damage(amount: float) -> void:
	if is_shielded and is_instance_valid(shield_source):
		# Visual feedback for shield hit
		modulate = Color(1, 1, 1) # Flash white
		await get_tree().create_timer(0.05).timeout
		modulate = Color(1, 0.8, 0) # Back to shield color
		return
		
	if enemy_type == EnemyType.GLITCH_WRAITH and is_phasing:
		return # Immortal while phasing
		
	health -= amount
	flash_timer = 0.1
	queue_redraw()
	
	if health <= 0:
		die()

func die() -> void:
	if pickup_scene and randf() < 0.35: # 35% drop chance
		var pickup = pickup_scene.instantiate()
		pickup.position = position # spawn in the same relative Room coordinate as the enemy
		get_parent().call_deferred("add_child", pickup)
		
	if splash_scene:
		var splash = splash_scene.instantiate()
		splash.global_position = global_position
		splash.color = Color(0.8, 0.1, 0.1) # Blood red!
		get_tree().current_scene.call_deferred("add_child", splash)
		
	# Spawn persistent blood stain
	if blood_stain_scene:
		var stain = Node2D.new()
		stain.set_script(blood_stain_scene)
		stain.global_position = global_position
		# Add to parent room so it persists with the room, not globally
		get_parent().call_deferred("add_child", stain)
		
	enemy_died.emit()
	call_deferred("queue_free")

func apply_dot(dps: float, duration: float, color: Color) -> void:
	dot_dps = dps
	dot_timer = duration
	is_dot_active = true
	dot_color = color
	modulate = color

# Collision with player
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(contact_damage)
