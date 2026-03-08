extends CharacterBody2D

signal health_changed(current: float, max: float)
signal boss_defeated

@export var is_split: bool = false
var is_dead: bool = false
var boss_name: String = "TOXIC SLUDGE"

var max_health: float = 120.0
var health: float = 120.0
var move_speed: float = 50.0
var contact_damage: int = 2

var player: Node2D = null
var split_scene: PackedScene = preload("res://ToxicSludge.tscn")
var item_scene: PackedScene = preload("res://Item.tscn")
var trapdoor_scene: PackedScene = preload("res://Trapdoor.tscn")
var puddle_scene: PackedScene = preload("res://AcidPuddle.tscn")

var state_timer: float = 2.0
var dash_target: Vector2 = Vector2.ZERO
var is_dashing: bool = false
var flash_timer: float = 0.0

@onready var sprite = $Sprite2D

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	
	# FIX 1: Safely attach the Hitbox script ONLY if it doesn't already exist from a duplicate
	if has_node("Hitbox"):
		var hb = $Hitbox
		if not hb.has_method("take_damage"):
			var script = GDScript.new()
			script.source_code = "extends Area2D\nfunc take_damage(amount: float):\n\tget_parent().take_damage(amount)\n"
			script.reload()
			hb.set_script(script)
		
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
		# Scaling
		if player.has_node("StatManager"):
			var stats = player.get_node("StatManager")
			var f = stats.current_floor
			
			if not is_split:
				max_health = 120.0 + (50 * (f - 1))
				move_speed = 50.0 + (10 * (f - 1))
				# FIX 2: Only reset health to max if this is the original parent boss!
				health = max_health 
			else:
				# Split versions are faster but have lower health ceiling
				max_health = 60.0 + (25 * (f - 1))
				move_speed = 90.0 + (15 * (f - 1))
				# Notice we removed "health = max_health" from here! It keeps its inherited half-health.
	
	if is_split:
		scale = Vector2(0.6, 0.6)
	
	queue_redraw()

func _draw() -> void:
	var c = Color(0.1, 0.4, 0.9) if flash_timer <= 0 else Color.WHITE # Coolant blue
	var dark_c = Color(0.05, 0.1, 0.3) # Deep oil blue
	
	# Drawing a bubbling sludge pile
	var time = Time.get_ticks_msec() * 0.005
	var r1 = 30.0 + sin(time) * 4.0
	var r2 = 25.0 + cos(time * 0.8) * 3.0
	var r3 = 28.0 + sin(time * 1.2) * 5.0
	
	# Body pieces
	draw_circle(Vector2.ZERO, r1, dark_c) # Dark oil outline
	draw_circle(Vector2(5, 5), r2, c)
	draw_circle(Vector2(-8, 2), r3, c)
	draw_circle(Vector2(2, -10), 22, c)
	
	# Bubbles / Sparks
	draw_circle(Vector2(-10, -10), 4 + sin(time*2)*1, Color(0.4, 0.8, 1.0))
	draw_circle(Vector2(12, 0), 6 + cos(time*3)*2, Color(0.4, 0.8, 1.0))
	
	# Simple Face
	draw_circle(Vector2(-5, -2), 3, Color.BLACK)
	draw_circle(Vector2(5, -2), 3, Color.BLACK)
	draw_circle(Vector2(-5, -2), 1, Color(0.8, 1, 0.8))
	draw_circle(Vector2(5, -2), 1, Color(0.8, 1, 0.8))

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player): return
	
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0: queue_redraw()
		
	state_timer -= delta
	
	if is_dashing:
		var dir = (dash_target - global_position).normalized()
		velocity = dir * move_speed * 3.0
		
		# Drop acid puddle periodically
		if Engine.get_frames_drawn() % 10 == 0 and puddle_scene:
			var p = puddle_scene.instantiate()
			p.global_position = global_position
			get_parent().add_child(p)
		
		if global_position.distance_to(dash_target) < 10.0 or state_timer <= 0:
			is_dashing = false
			state_timer = 2.0
	else:
		# Slowly chase
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * move_speed
		
		if state_timer <= 0:
			# Dash!
			is_dashing = true
			state_timer = 1.0
			dash_target = player.global_position + (player.global_position - global_position).normalized() * 200.0
			
	move_and_slide()
	_check_contact_damage()
	
	# Wiggle animation
	queue_redraw()

func take_damage(amount: float) -> void:
	health -= amount
	health_changed.emit(health, max_health)
	
	flash_timer = 0.1
	queue_redraw()
	
	# Splitting logic!
	if not is_split and health <= (max_health / 2.0):
		_trigger_split()
		return
		
	if health <= 0:
		die()

func _trigger_split() -> void:
	SFX.play_explosion()
	
	# Change ourselves to act as the first split
	is_split = true
	scale = Vector2(0.6, 0.6)
	move_speed += 40.0
	
	# Spawn a second split sibling
	var sl = split_scene.instantiate()
	sl.is_split = true
	sl.health = health # Start at half health too
	sl.max_health = max_health
	sl.position = position + Vector2(30, 0)
	
	var r = get_parent()
	r.call_deferred("add_child", sl)
	
	# Delay registering to the room to avoid threading crashes
	await get_tree().process_frame
	if r and "spawned_enemy_nodes" in r:
		r.spawned_enemy_nodes.append(sl)
		# Manually hook its death if it happens to be the last one alive
		if sl.has_signal("boss_defeated") and r.has_method("_on_boss_defeated"):
			sl.boss_defeated.connect(r._on_boss_defeated)

func die() -> void:
	SFX.play_explosion()
	if is_dead: return
	is_dead = true
	
	if not is_split: # Only drop items if the main body somehow dies without splitting (like an instant-kill)
		boss_defeated.emit()
		_spawn_loot()
	else:
		# Check if the other split is dead
		var sibs = get_tree().get_nodes_in_group("boss")
		var other_slimes_alive = 0
		
		for s in sibs:
			if is_instance_valid(s) and s != self:
				# We count slimes with health > 0 as "alive"
				if s.get("health") != null and s.health > 0 and not s.get("is_dead"):
					other_slimes_alive += 1
				
		if other_slimes_alive <= 0:
			# This is the last slime standing
			print("Last Slime Defeated! Spawning loot and trapdoor.")
			boss_defeated.emit()
			_spawn_loot()
		else:
			print("Slime Defeated, but ", other_slimes_alive, " others still alive.")
			
	call_deferred("queue_free")

func _spawn_loot() -> void:
	if item_scene:
		var item = item_scene.instantiate()
		item.position = position + Vector2(0, 40)
		get_parent().call_deferred("add_child", item)
		
	# --- NEW: CHECK FOR FINAL FLOOR ---
	var is_final_floor = false
	if player and player.get("stats") and player.stats.current_floor >= 9:
		is_final_floor = true
		
	if is_final_floor:
		print("MAINFRAME DESTROYED. VICTORY!")
		get_tree().create_timer(3.0).timeout.connect(func(): get_tree().change_scene_to_file("res://VictoryScreen.tscn"))
	else:
		if trapdoor_scene:
			var trapdoor = trapdoor_scene.instantiate()
			trapdoor.position = position - Vector2(0, 20)
			get_parent().call_deferred("add_child", trapdoor)

func _check_contact_damage() -> void:
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.call_deferred("take_damage", contact_damage)
