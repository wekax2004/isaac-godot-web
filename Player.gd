extends CharacterBody2D

# Base player stats
var bullet_scene: PackedScene = preload("res://Tear.tscn")
var game_over_scene: PackedScene = preload("res://GameOverScreen.tscn")
var familiar_scene: PackedScene = preload("res://Familiar.tscn")
var spider_scene: PackedScene = preload("res://Familiar.tscn") # Spiders are derived familiars
var laser_scene: PackedScene = preload("res://Laser.tscn")
var knife_scene: PackedScene = preload("res://Knife.tscn")

# --- NEW: Signals for Phase 10 HUD ---
signal health_changed(current_health: int, max_health: int)
signal bandwidth_changed(amount: int)

var can_shoot: bool = true
var current_health: int = 3 # We will sync this with StatManager later
var bandwidth: int = 20 # Unified resource

# --- NEW: Dash Mechanics ---
var is_dashing: bool = false
var dash_cooldown: float = 0.0
var dash_duration: float = 0.2
var dash_multiplier: float = 2.5
var invincible: bool = false
var invincibility_timer: float = 0.0
# Brimstone Mechanics
var brimstone_charge: float = 0.0
var is_charging: bool = false
var last_shoot_dir: Vector2 = Vector2.ZERO

# --- NEW: Snaring Mechanics (Rooting) ---
var snare_timer: float = 0.0

@onready var anim = $AnimationPlayer 
@onready var sprite = $Sprite2D 
@onready var stats = $StatManager # Ensure you added this custom Node as a child of Player!

func _ready() -> void:
	add_to_group("player")
	
	# Layer 1 = Player, Mask 3 = detect Enemies (Layer 3) & Enemy Bullets (Layer 4)
	# Using Godot 4 bit flags (1 for layer 1, 12 for masks 3 & 4)
	collision_layer = 1
	collision_mask = 1 | 2 | 4 | 8
	
	if stats:
		current_health = stats.max_health
		call_deferred("emit_signal", "health_changed", current_health, stats.max_health)
		stats.familiar_added.connect(_on_familiar_added)
		stats.stats_changed.connect(queue_redraw)
		
	if sprite and GameManager.selected_character:
		var c = GameManager.selected_character
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.texture = load("res://assets/player_rogue_instance.png")
		sprite.show_behind_parent = true 
		
		# Auto-scale the player to exactly 50x50 pixels on screen
		if sprite.texture:
			var tex_size = sprite.texture.get_size()
			var target_size = Vector2(50.0, 50.0)
			sprite.scale = target_size / tex_size
		
		if stats:
			for item_id in c.starting_items:
				var item_data = ItemRegistry.get_item_data(item_id)
				stats.add_item(item_data)
		
		bandwidth = c.starting_bandwidth
	
	call_deferred("emit_signal", "bandwidth_changed", bandwidth)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("use_active_item") or event.is_action_pressed("use_card"):
		_trigger_active_item()
		
func _trigger_active_item() -> void:
	if not stats or not stats.active_item: return
	
	if stats.active_item_charge >= stats.active_item.max_charges:
		# Trigger effect
		var item_name = stats.active_item.item_name
		if item_name == "Book of Shadows":
			invincible = true
			invincibility_timer = 5.0
			queue_redraw()
			SFX.play_shoot() # Or a shield sound
		elif item_name == "Drone Swarm":
			for i in range(3): # Spawn 3 drones
				var fam = spider_scene.instantiate()
				fam.player = self
				fam.familiar_name = "Attack Drone"
				fam.type = 1 # Follower
				fam.follow_lag = 0.5 + (i * 0.2)
				fam.contact_damage = 5.0
				fam.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
				call_deferred("add_child", fam)
			SFX.play_pickup()
			
		# Drain charge
		stats.active_item_charge = 0
		stats.active_charge_changed.emit(0, stats.active_item.max_charges)

func _on_familiar_added(item: ItemData) -> void:
	if not familiar_scene: return
	
	var fam = familiar_scene.instantiate()
	fam.player = self
	fam.familiar_name = item.familiar_name
	
	# Configure based on name
	if item.familiar_name == "Meat Cube":
		fam.type = 0 # FamiliarType.ORBITAL
		fam.orbit_speed = 3.0
		fam.orbit_radius = 45.0
		fam.contact_damage = 3.0
	elif item.familiar_name == "Ghost Baby":
		fam.type = 1 # FamiliarType.FOLLOWER
		fam.follow_lag = 0.3
		fam.shoot_cooldown = 1.0
		
	# Spawn at player position
	fam.global_position = global_position
	call_deferred("add_child", fam)
		
func _draw() -> void:
	if is_dashing:
		draw_circle(Vector2.ZERO, 19, Color(0.8, 0.8, 1.0, 0.4)) # Dash aura
		
	if invincible and not is_dashing:
		# Draw a protective shield aura
		var radius = 22.0 + sin(Time.get_ticks_msec() * 0.01) * 2.0
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0.2, 0.8, 1.0, 0.6), 3.0)
		draw_arc(Vector2.ZERO, radius - 4.0, 0, TAU, 32, Color(0.6, 0.9, 1.0, 0.3), 1.0)
	
	# Draw Brimstone charge bar
	if is_charging:
		var bar_w = 40
		var bar_h = 4
		var bar_y = -30
		draw_rect(Rect2(-bar_w/2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
		var fill = clamp(brimstone_charge / stats.fire_rate, 0.0, 1.0)
		draw_rect(Rect2(-bar_w/2, bar_y, bar_w * fill, bar_h), Color(0.8, 0.1, 0.1))
		
	if stats:
		_draw_item_accessories()

func _draw_item_accessories() -> void:
	# Draw fun visual add-ons based on collected items!
	for item in stats.inventory:
		match item.item_name:
			"Acid Rounds":
				# Leaking green coolant
				draw_circle(Vector2(0, 8), 3, Color(0.2, 0.9, 0.1))
				draw_circle(Vector2(-3, 6), 2, Color(0.2, 0.9, 0.1))
			"Neural Tracker":
				# Purple headband
				draw_rect(Rect2(-10, -10, 20, 3), Color(0.4, 0.1, 0.6))
				draw_circle(Vector2(0, -8), 2.0, Color(0.9, 0.4, 1.0))
			"Hyper-Accelerator":
				# Glowing orange thrusters on the sides
				draw_rect(Rect2(-12, -2, 4, 8), Color(1.0, 0.5, 0.0))
				draw_rect(Rect2(8, -2, 4, 8), Color(1.0, 0.5, 0.0))
			"Explosive Munitions":
				# Red hazard core in the center of the chest
				draw_circle(Vector2(0, 0), 4.0, Color(0.8, 0.1, 0.1))
				draw_circle(Vector2(0, 0), 2.0, Color(1.0, 0.8, 0.1))
			"Power Node":
				# A glowing blue battery pack on the head
				draw_rect(Rect2(-5, -14, 10, 5), Color(0.1, 0.1, 0.3))
				draw_rect(Rect2(-3, -13, 6, 3), Color(0.0, 0.8, 1.0))
			"Overclock":
				# Yellow energy sparks/antenna
				draw_line(Vector2(0, -9), Vector2(-3, -14), Color(0.9, 0.9, 0.1), 2)
				draw_line(Vector2(-3, -14), Vector2(3, -17), Color(0.9, 0.9, 0.1), 2)
			"Omni-Cell":
				# Floating data prism
				draw_circle(Vector2(0, -14), 2, Color.WHITE)
				var pts = PackedVector2Array([Vector2(-3,-14), Vector2(0,-17), Vector2(3,-14), Vector2(0,-11)])
				draw_colored_polygon(pts, Color(0.2, 0.8, 1.0, 0.6))

func add_active_charge(amount: int) -> void:
	if stats and stats.active_item:
		stats.active_item_charge = mini(stats.active_item_charge + amount, stats.active_item.max_charges)
		stats.active_charge_changed.emit(stats.active_item_charge, stats.active_item.max_charges)

func _physics_process(delta: float) -> void:
	if not stats: return

	# Handle Dash timers
	if dash_cooldown > 0:
		dash_cooldown -= delta
	if invincibility_timer > 0:
		invincibility_timer -= delta
		queue_redraw() # Force redraw for the pulsating shield
		# Make the sprite blink while invincible
		if sprite:
			sprite.modulate.a = 0.5 if int(Time.get_ticks_msec() / 100) % 2 == 0 else 1.0
		if invincibility_timer <= 0:
			invincible = false
			if sprite:
				sprite.modulate.a = 1.0
			queue_redraw()
	
	if snare_timer > 0:
		snare_timer -= delta
		if snare_timer <= 0:
			queue_redraw()
			
	handle_movement()
	handle_shooting(delta)
	update_animation()

func handle_movement() -> void:
	var move_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Check for dash input
	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown <= 0 and move_dir != Vector2.ZERO:
		_start_dash()
	
	var current_speed = stats.speed
	if is_dashing:
		current_speed *= dash_multiplier
	
	if snare_timer > 0:
		current_speed = 0.0 # Rooted!
		
	velocity = move_dir * current_speed
	move_and_slide()
	
	if is_dashing and Engine.get_frames_drawn() % 3 == 0:
		var c = GameManager.selected_character
		if c and c.character_id == "0x03": # OVERFLOW
			_leave_coolant_trail()
		else:
			_leave_corruption_trail()

func _leave_coolant_trail() -> void:
	if not stats: return
	var puddle_scene = load("res://AcidPuddle.tscn")
	if puddle_scene:
		var inst = puddle_scene.instantiate()
		inst.global_position = global_position
		
		# CRITICAL: Tell the game the player owns this!
		inst.is_player_owned = true 
		inst.puddle_color = Color(1.0, 0.2, 0.0, 0.8) # Neon Orange Firewall!
		inst.damage = stats.damage * 5.0 # Massive tick damage to enemies
		inst.lifetime = 1.0 # Disappears quickly behind you
		
		get_parent().add_child(inst)

func _start_dash() -> void:
	is_dashing = true
	invincible = true
	dash_cooldown = 1.0
	SFX.play_dash()
	queue_redraw()
	
	var tree = get_tree()
	if tree:
		await tree.create_timer(dash_duration).timeout
		if not is_instance_valid(self): return
		is_dashing = false
		queue_redraw()
		
		# Give a tiny bit of extra i-frames after dash ends to be forgiving
		await tree.create_timer(0.1).timeout
		if not is_instance_valid(self): return
		invincible = false
		queue_redraw()

func _leave_corruption_trail() -> void:
	# Create a temporary 'glitch' effect that damages enemies
	var glitch = Area2D.new()
	glitch.collision_layer = 0
	glitch.collision_mask = 4 # Enemies
	glitch.global_position = global_position
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(20, 20)
	shape.shape = rect
	glitch.add_child(shape)
	
	# Visual for glitch
	var visual = ColorRect.new()
	visual.size = Vector2(16, 16)
	visual.position = Vector2(-8, -8)
	visual.color = Color(0.2, 0.8, 1.0, 0.6)
	glitch.add_child(visual)
	
	get_parent().add_child(glitch)
	
	# Damage logic
	glitch.body_entered.connect(func(body):
		if body.has_method("take_damage"):
			body.take_damage(2.0) # Dash trail damage
		
		# Character Specific: SCRAMBLE.EXE Packet Burst
		var c = GameManager.selected_character
		if c and c.character_id == "0x01" and body.has_method("scramble"):
			body.scramble(3.0) # Scramble for 3 seconds
	)
	
	# Cleanup after 1 second
	var t = get_tree().create_timer(1.0)
	t.timeout.connect(func(): glitch.queue_free())
	
	# Randomize visual a bit for 'glitch' look
	visual.rotation = randf() * TAU
	visual.scale = Vector2(randf_range(0.5, 1.5), randf_range(0.5, 1.5))

func handle_shooting(delta: float) -> void:
	var shoot_dir := Input.get_vector("shoot_left", "shoot_right", "shoot_up", "shoot_down")
	
	if shoot_dir != Vector2.ZERO and can_shoot:
		if stats.has_brimstone:
			_handle_brimstone_charging(shoot_dir, delta)
		elif stats.has_laser:
			fire_laser(shoot_dir.normalized())
		elif stats.has_knife:
			fire_knife(shoot_dir.normalized())
		else:
			fire_tear(shoot_dir.normalized())
	elif is_charging:
		# Release charge if shoot_dir is zero
		_fire_brimstone_if_ready()

func update_animation() -> void:
	# Using programmatic _draw() - no sprite animations needed
	pass

func fire_tear(direction: Vector2) -> void:
	if not bullet_scene: return
		
	can_shoot = false
	
	SFX.play_shoot()
	
	if stats.has_shotgun:
		# Fire 3 tears in a spread
		var angles = [-15.0, 0.0, 15.0]
		for angle_deg in angles:
			var rotated_dir = direction.rotated(deg_to_rad(angle_deg))
			_spawn_tear(rotated_dir)
	else:
		_spawn_tear(direction)
	
	await get_tree().create_timer(stats.fire_rate).timeout
	can_shoot = true

func _spawn_tear(dir: Vector2) -> void:
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = dir
	
	bullet.damage = stats.damage
	bullet.max_range = stats.range
	bullet.is_homing = stats.has_homing
	bullet.is_piercing = stats.has_piercing
	bullet.is_poison = stats.has_poison
	bullet.is_explosive = stats.has_explosive
	bullet.is_parasite = stats.has_parasite
	bullet.is_rubber_cement = stats.has_rubber_cement
	# Tears scale with damage: base 3.5 = 1.0x, higher damage = bigger tears
	var damage_scale = clampf(stats.damage / 3.5, 0.8, 3.0)
	bullet.tear_size = stats.tear_size_mult * damage_scale
	bullet.color_override = stats.current_tear_color
	
	get_tree().current_scene.call_deferred("add_child", bullet)

func fire_laser(direction: Vector2) -> void:
	if not laser_scene: return
	
	can_shoot = false
	SFX.play_shoot() 
	
	if stats.has_shotgun:
		var angles = [-15.0, 0.0, 15.0]
		for angle_deg in angles:
			var rotated_dir = direction.rotated(deg_to_rad(angle_deg))
			_spawn_laser(rotated_dir)
	else:
		_spawn_laser(direction)
	
	await get_tree().create_timer(stats.fire_rate).timeout
	can_shoot = true

func _spawn_laser(dir: Vector2) -> void:
	var laser = laser_scene.instantiate()
	laser.position = Vector2.ZERO # Follow player
	laser.rotation = dir.angle()
	laser.damage = stats.damage
	# Technology lasers are usually green as per user request
	laser.color = stats.current_tear_color if stats.current_tear_color != Color.WHITE else Color(0.2, 1.0, 0.3)
	laser.max_range = stats.range
	laser.is_poison = stats.has_poison
	laser.is_explosive = stats.has_explosive
	
	add_child(laser)

func fire_knife(direction: Vector2) -> void:
	if not knife_scene: return
	
	can_shoot = false
	
	if stats.has_shotgun:
		var angles = [-15.0, 0.0, 15.0]
		for angle_deg in angles:
			var rotated_dir = direction.rotated(deg_to_rad(angle_deg))
			_spawn_knife(rotated_dir)
	else:
		_spawn_knife(direction)
	
	await get_tree().create_timer(stats.fire_rate).timeout
	can_shoot = true

func _spawn_knife(dir: Vector2) -> void:
	var knife = knife_scene.instantiate()
	knife.player = self
	knife.global_position = global_position
	knife.direction = dir
	
	knife.damage = stats.damage
	knife.max_range = stats.range * 0.5 # Knife has shorter effective range than tears
	knife.size_mult = stats.tear_size_mult
	knife.is_poison = stats.has_poison
	knife.is_explosive = stats.has_explosive
	
	get_tree().current_scene.call_deferred("add_child", knife)

func _handle_brimstone_charging(dir: Vector2, delta: float) -> void:
	is_charging = true
	last_shoot_dir = dir.normalized()
	brimstone_charge += delta
	queue_redraw()
	
	if brimstone_charge >= stats.fire_rate:
		# Fully charged! In this version, we fire immediately or hold?
		# Let's say it keeps charging until released.
		pass

func _fire_brimstone_if_ready() -> void:
	if brimstone_charge >= stats.fire_rate:
		fire_brimstone(last_shoot_dir)
	
	is_charging = false
	brimstone_charge = 0.0
	queue_redraw()

func fire_brimstone(direction: Vector2) -> void:
	if not laser_scene: return
	
	can_shoot = false
	SFX.play_shoot()
	
	if stats.has_shotgun:
		var angles = [-15.0, 0.0, 15.0]
		for angle_deg in angles:
			var rotated_dir = direction.rotated(deg_to_rad(angle_deg))
			_spawn_brimstone_laser(rotated_dir)
	else:
		_spawn_brimstone_laser(direction)
	
	# Delay before next charge can start
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(self):
		can_shoot = true

func _spawn_brimstone_laser(dir: Vector2) -> void:
	# Brimstone is a thick red laser
	var laser = laser_scene.instantiate()
	laser.position = Vector2.ZERO # Follow player
	laser.rotation = dir.angle()
	laser.damage = stats.damage * 2.0 # Brimstone hits harder
	laser.color = Color(0.8, 0.1, 0.1)
	laser.max_range = stats.range * 1.5
	laser.duration = 0.3 # stays longer
	laser.width = 12.0 # thicker
	
	add_child(laser)

# --- NEW: Taking Damage Logic ---
func snare(duration: float) -> void:
	if invincible: return # Can't snare if i-framed
	snare_timer = maxi(snare_timer, duration)
	queue_redraw()

func take_damage(amount: int) -> void:
	if invincible:
		return # I-frames!
		
	var c = GameManager.selected_character
	if c and c.character_id == "0x02": # ENCRYPTOR
		# Hardened Shell: Reduced damage
		if randf() < 0.5: # 50% chance to ignore 1 damage
			amount = maxi(1, amount - 1)
		
	current_health -= amount
	SFX.play_hit()
	
	# Triger i-frames
	invincible = true
	invincibility_timer = 0.5
	queue_redraw()
	
	if sprite:
		sprite.modulate = Color(1, 0, 0)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite):
			sprite.modulate = Color(1, 1, 1)
		
	# Trigger screen shake
	var level_gen = get_tree().get_first_node_in_group("level_generator")
	if level_gen and level_gen.has_method("shake_camera"):
		level_gen.shake_camera(25.0, 0.2)
	
	# Notify the HUD!
	health_changed.emit(current_health, stats.max_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	SFX.play_death()
	print("Game Over! Player died.")
	if game_over_scene:
		get_tree().change_scene_to_packed(game_over_scene)
	else:
		get_tree().reload_current_scene()

func add_consumable(type: String, amount: int) -> void:
	# In the unified system, all types (memory_fragment, etc) add to bandwidth
	SFX.play_pickup()
	bandwidth += amount
	bandwidth_changed.emit(bandwidth)

