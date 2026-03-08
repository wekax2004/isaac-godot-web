extends CharacterBody2D

signal health_changed(current: float, max: float)
signal boss_defeated

enum BossType { MONSTRO, DUKE_OF_FLIES, HEAVY_MECH, NECROMANCER, NANITE_SWARM }
enum State { IDLE, SHOOT_RING, DASH, SUMMON, ORBIT, VOLLEY, TELEPORT, SUMMON_ELITES }

@export var boss_type: BossType = BossType.MONSTRO

var max_health: float = 150.0
var health: float = 150.0
var move_speed: float = 60.0
var contact_damage: int = 2

var player: Node2D = null
var current_state: State = State.IDLE
var state_timer: float = 2.0
var dash_target: Vector2 = Vector2.ZERO
var flash_timer: float = 0.0
@onready var sprite = $Sprite2D # Assuming a Sprite2D child exists or adding it

# Damage-over-Time (DoT) System
var dot_dps: float = 0.0
var dot_timer: float = 0.0
var is_dot_active: bool = false
var dot_color: Color = Color.WHITE
var dot_tick_timer: float = 0.0 # Consistency with Enemy.gd

var bullet_scene: PackedScene = preload("res://EnemyBullet.tscn")
var item_scene: PackedScene = preload("res://Item.tscn")
var enemy_scene: PackedScene = preload("res://Enemy.tscn") # For summoning flies

func _ready() -> void:
	add_to_group("enemies") # so player bullets can hit it
	add_to_group("boss") # so HUD can find it
	queue_redraw()
	
	health = max_health
	
	if has_node("Hitbox"):
		var hb = $Hitbox
		# Dynamically attach a tiny script so the Area2D can receive 'take_damage'
		var script = GDScript.new()
		script.source_code = "extends Area2D\nfunc take_damage(amount: float):\n\tget_parent().take_damage(amount)\n"
		script.reload()
		hb.set_script(script)
	
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		# Scale based on floor
		if player.has_node("StatManager"):
			var stats = player.get_node("StatManager")
			var f: int = stats.current_floor
			
			max_health = 150.0 + (50 * (f - 1))
			health = max_health
			move_speed = 60.0 + (10 * (f - 1))
			
			if boss_type == BossType.DUKE_OF_FLIES:
				max_health *= 0.8 # Less HP but summons mobs
				health = max_health
				current_state = State.ORBIT
				state_timer = 3.0
			
			if f >= 3:
				# Boss becomes redder and faster
				modulate = Color(1.2, 0.8, 0.8)
				
	if sprite:
		match boss_type:
			BossType.MONSTRO:
				sprite.texture = load("res://assets/monstro_sprite.png")
				sprite.scale = Vector2(0.18, 0.18)
			BossType.DUKE_OF_FLIES:
				sprite.texture = load("res://assets/sprites/nanite_fly.png") # Changed to a cooler nanite fly sprite
				sprite.scale = Vector2(0.25, 0.25)
			BossType.HEAVY_MECH:
				sprite.texture = load("res://assets/sprites/heavy_mech.png")
				sprite.scale = Vector2(0.2, 0.2)
				max_health = 250.0
				health = max_health
			BossType.NECROMANCER:
				sprite.texture = load("res://assets/sprites/necromancer.png")
				sprite.scale = Vector2(0.18, 0.18)
			BossType.NANITE_SWARM:
				sprite.texture = load("res://assets/sprites/pulse_drone.png")
				sprite.scale = Vector2(0.15, 0.15)
				move_speed *= 1.5

func _draw() -> void:
	return # Use Sprite2D instead
	if boss_type == BossType.MONSTRO:
		_draw_monstro()
	else:
		_draw_duke()

func _draw_monstro() -> void:
	var c = Color(0.8, 0.1, 0.2) if flash_timer <= 0 else Color.WHITE
	# Huge boss body
	draw_circle(Vector2.ZERO, 40, Color(0.2, 0.05, 0.05))
	draw_circle(Vector2.ZERO, 35, c)
	
	# Features
	draw_circle(Vector2(-15, -10), 8, Color.BLACK)
	draw_circle(Vector2(15, -10), 8, Color.BLACK)
	draw_circle(Vector2(-15, -10), 3, Color(1, 0.8, 0.2)) # Glowing eyes
	draw_circle(Vector2(15, -10), 3, Color(1, 0.8, 0.2))
	
	# Maw
	draw_rect(Rect2(-20, 10, 40, 15), Color(0.1, 0, 0))
	# Teeth
	for t in range(-15, 20, 8):
		var pts = PackedVector2Array([Vector2(t, 10), Vector2(t+4, 18), Vector2(t+8, 10)])
		draw_colored_polygon(pts, Color.WHITE)

func _draw_duke() -> void:
	var c = Color(0.4, 0.3, 0.2) if flash_timer <= 0 else Color.WHITE
	# Rotting fleshy blob
	draw_circle(Vector2.ZERO, 38, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2.ZERO, 34, c)
	# Holes for flies
	for i in range(5):
		var ang = (i * TAU / 5.0)
		draw_circle(Vector2(cos(ang), sin(ang)) * 20, 6, Color(0.1, 0.05, 0))
	# Sickly eyes
	draw_circle(Vector2(-12, -8), 5, Color.WHITE)
	draw_circle(Vector2(12, -8), 5, Color.WHITE)
	draw_circle(Vector2(-12, -8), 2, Color.BLACK)
	draw_circle(Vector2(12, -8), 2, Color.BLACK)

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
		
	# Flash effect
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0:
			queue_redraw()
			
	# DoT Ticks (Poison/Fire/etc)
	if is_dot_active:
		dot_tick_timer -= delta
		if dot_tick_timer <= 0:
			dot_tick_timer = 0.5
			var tick_dmg = dot_dps * 0.5
			health -= tick_dmg
			flash_timer = 0.1 # Visual flash
			queue_redraw()
			
			if health <= 0:
				die()
				return
				
		if dot_timer <= 0:
			is_dot_active = false
			modulate = Color.WHITE
			
	state_timer -= delta
	
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.SHOOT_RING:
			_state_shoot_ring(delta)
		State.DASH:
			_state_dash(delta)
		State.ORBIT:
			_state_orbit(delta)
		State.SUMMON:
			_state_summon(delta)
		State.VOLLEY:
			_state_volley(delta)
		State.TELEPORT:
			_state_teleport(delta)
		State.SUMMON_ELITES:
			_state_summon_elites(delta)

func _state_idle(delta: float) -> void:
	# Slowly drift toward player
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()
	_check_contact_damage()
	
	if state_timer <= 0:
		# Pick random next state
		var r = randf()
		if r < 0.5:
			current_state = State.SHOOT_RING
			state_timer = 1.0 # Brief pause while shooting
			_fire_ring()
		elif r < 0.8:
			current_state = State.DASH
			state_timer = 1.5
			# Charge much further past the player to look dangerous!
			dash_target = player.global_position + (player.global_position - global_position).normalized() * 300.0
		else:
			# Boss-specific decision logic
			match boss_type:
				BossType.HEAVY_MECH:
					current_state = State.VOLLEY
					state_timer = 2.0
				BossType.NECROMANCER:
					current_state = State.TELEPORT if randf() < 0.5 else State.SUMMON_ELITES
					state_timer = 1.0
				BossType.NANITE_SWARM:
					current_state = State.SUMMON
					state_timer = 0.5
				_:
					current_state = State.IDLE
					state_timer = 1.0

func _state_shoot_ring(_delta: float) -> void:
	velocity = Vector2.ZERO # Stop to shoot
	if state_timer <= 0:
		current_state = State.IDLE
		state_timer = 2.0

func _state_dash(delta: float) -> void:
	var dir = (dash_target - global_position).normalized()
	velocity = dir * move_speed * 4.5 # Fast dash
	move_and_slide()
	_check_contact_damage()
	
	# Check for direct contact damage during dash
	var dist = global_position.distance_to(player.global_position)
	if dist < 60: # Boss hitbox is large
		player.take_damage(contact_damage)
	
	# Stop dashing if we reach target or timer runs out
	if global_position.distance_to(dash_target) < 10.0 or state_timer <= 0:
		current_state = State.IDLE
		state_timer = 2.0

func _state_orbit(delta: float) -> void:
	# Orbit the player at a distance
	var orbit_speed = 1.0
	var dist = 200.0
	var target = player.global_position + Vector2(cos(Time.get_ticks_msec() * 0.001 * orbit_speed), sin(Time.get_ticks_msec() * 0.001 * orbit_speed)) * dist
	var dir = (target - global_position).normalized()
	velocity = dir * move_speed * 1.5
	move_and_slide()
	_check_contact_damage()
	
	if state_timer <= 0:
		current_state = State.SUMMON
		state_timer = 1.0

func _state_summon(_delta: float) -> void:
	velocity *= 0.8 # Slow down to summon
	if state_timer <= 0:
		_spawn_flies()
		_fire_ring() # <--- NEW: The Duke now fires a massive ring of bullets when he summons!
		current_state = State.ORBIT
		state_timer = randf_range(2.0, 4.0)

func _state_volley(delta: float) -> void:
	velocity = Vector2.ZERO # Stop to fire volley
	if state_timer > 0 and Engine.get_frames_drawn() % 15 == 0:
		_shoot_volley()
	
	if state_timer <= 0:
		current_state = State.IDLE
		state_timer = 1.5

func _shoot_volley() -> void:
	if not bullet_scene: return
	var dir = (player.global_position - global_position).normalized()
	for i in range(-1, 2): # 3-way spread
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.direction = dir.rotated(i * 0.25)
		get_tree().current_scene.call_deferred("add_child", bullet)

func _state_teleport(_delta: float) -> void:
	# Visual "fade out" before teleport
	modulate.a = lerpf(modulate.a, 0.0, 0.2)
	if state_timer <= 0:
		# Find random spot in room (assumed size)
		global_position += Vector2(randf_range(-400, 400), randf_range(-200, 200))
		modulate.a = 1.0
		current_state = State.IDLE
		state_timer = 2.0

func _state_summon_elites(_delta: float) -> void:
	velocity = Vector2.ZERO
	if state_timer <= 0:
		_spawn_elites()
		current_state = State.IDLE
		state_timer = 3.0

func _spawn_elites() -> void:
	if not enemy_scene: return
	for i in range(2):
		var elite = enemy_scene.instantiate()
		elite.enemy_type = EnemyType.GLITCH_WRAITH if boss_type == BossType.NECROMANCER else EnemyType.SHOOTER
		elite.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		get_parent().call_deferred("add_child", elite)

func _spawn_flies() -> void:
	if not enemy_scene: return
	SFX.play_boss_roar() # Or a "vomit" sound
	
	for i in range(3):
		var fly = enemy_scene.instantiate()
		fly.enemy_type = 5 # FLY
		fly.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		get_parent().call_deferred("add_child", fly)

func apply_dot(dps: float, duration: float, color: Color) -> void:
	dot_dps = dps
	dot_timer = duration
	is_dot_active = true
	dot_color = color
	modulate = color

func _fire_ring() -> void:
	if not bullet_scene: return
	SFX.play_boss_roar()
	
	var floor_num = 1
	if player and player.has_node("StatManager"):
		floor_num = player.get_node("StatManager").current_floor
		
	var num_bullets = 12 + (floor_num * 4) # More bullets per floor
	var angle_step = TAU / num_bullets
	for i in range(num_bullets):
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.direction = Vector2(cos(i * angle_step), sin(i * angle_step))
		get_tree().current_scene.call_deferred("add_child", bullet)

func take_damage(amount: float) -> void:
	health -= amount
	health_changed.emit(health, max_health)
	
	flash_timer = 0.1
	queue_redraw()
	
	if sprite:
		sprite.modulate = Color(1, 0, 0)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite):
			sprite.modulate = Color.WHITE
	
	if health <= 0:
		die()

func die() -> void:
	SFX.play_explosion()
	boss_defeated.emit()
	
	if item_scene:
		var item = item_scene.instantiate()
		item.position = position + Vector2(0, 40) # Spawn item slightly below
		get_parent().call_deferred("add_child", item)
		
	# --- NEW: CHECK FOR FINAL FLOOR ---
	var is_final_floor = false
	if player and player.get("stats") and player.stats.current_floor >= 9:
		is_final_floor = true
		
	if is_final_floor:
		print("MAINFRAME DESTROYED. VICTORY!")
		get_tree().create_timer(3.0).timeout.connect(func(): get_tree().change_scene_to_file("res://VictoryScreen.tscn"))
	else:
		# Spawn normal trapdoor
		var trapdoor_scene = load("res://Trapdoor.tscn")
		if trapdoor_scene:
			var trapdoor = trapdoor_scene.instantiate()
			trapdoor.position = position - Vector2(0, 20)
			get_parent().call_deferred("add_child", trapdoor)
			
	call_deferred("queue_free")

func _check_contact_damage() -> void:
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.call_deferred("take_damage", contact_damage)
