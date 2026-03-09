extends Node2D
class_name Room

signal cleared

@export var top_door: Node2D
@export var bottom_door: Node2D
@export var left_door: Node2D
@export var right_door: Node2D

var boss_scene: PackedScene = preload("res://Boss.tscn")
var toxic_sludge_scene: PackedScene = preload("res://ToxicSludge.tscn")
var trapdoor_scene: PackedScene = preload("res://Trapdoor.tscn")
var pickup_scene: PackedScene = preload("res://Pickup.tscn")
var item_scene: PackedScene = preload("res://Item.tscn")
var obstacle_scene: PackedScene = preload("res://Obstacle.tscn")
var enemy_scene: PackedScene = preload("res://Enemy.tscn")
var barrel_scene: PackedScene = preload("res://Barrel.tscn")
var spikes_scene: PackedScene = preload("res://Spikes.tscn")
var tnt_scene: PackedScene = preload("res://TNT.tscn")
var turret_scene: PackedScene = preload("res://Turret.tscn")

@export var template: RoomTemplate = null
var layouts_dict: Array = [] # Backup for script-generated layouts



var grid_pos: Vector2
var floor_texture: Texture2D = preload("res://assets/basement_tile.png")
var is_cleared: bool = false
var enemies_spawned: bool = false
var is_boss_room: bool = false
var is_item_room: bool = false
var is_shop_room: bool = false
var is_devil_room: bool = false
var is_secret_room: bool = false
var is_npc_room: bool = false
var is_buffer_room: bool = false
var secret_revealed: bool = false
var player_ref: Node2D = null
@export var floor_level: int = 1
@export var floor_name: String = "The Localhost"

# Theme Colors
var color_background: Color = Color(0.02, 0.02, 0.04)
var color_grid: Color = Color(0.0, 0.8, 1.0, 0.15)
var color_wall: Color = Color(0.1, 0.1, 0.15)
var color_firewall: Color = Color(1.0, 0.4, 0.1)

# Hazards - Deletion Zones
var deletion_zones: Array[Rect2] = []
var deletion_active: bool = true
var deletion_timer: float = 0.0

# Hazards - Tumbleweeds
var tumbleweeds: Array[Dictionary] = []

# Hazards - Tracking Pings
var ping_timer: float = 0.0
var ping_active: bool = false
var ping_radius: float = 0.0

# Hazards - Exhaust Vents
var vents: Array[Dictionary] = []
var vent_cycle_timer: float = 0.0
var vent_active: bool = false

var spawn_markers: Array = []

var walls_body: StaticBody2D
# Indices: 0=top, 1=bottom, 2=left, 3=right
var door_blockers: Array[CollisionShape2D] = []
var active_doors: Dictionary = {"top": false, "bottom": false, "left": false, "right": false}
var doors_locked: bool = false
var spawned_enemy_nodes: Array[Node] = []
var current_wave: int = 0
var max_waves: int = 3

func _ready() -> void:
	queue_redraw()
	spawn_markers = get_tree().get_nodes_in_group("enemy_spawn_points")
	# Wire door references by node path
	_apply_theme()
	
	if has_node("TopDoor"): top_door = $TopDoor
	if has_node("BottomDoor"): bottom_door = $BottomDoor
	if has_node("LeftDoor"): left_door = $LeftDoor
	if has_node("RightDoor"): right_door = $RightDoor
	
	_update_visual_doors()
	_build_collisions()
	_setup_entry_detection()
	_update_door_locks()

func _setup_exhaust_vents() -> void:
	# Add 2-4 static vents
	for i in range(randi() % 3 + 2):
		var rx = randf_range(-450, 450)
		var ry = randf_range(-250, 250)
		var dir = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT].pick_random()
		vents.append({"pos": Vector2(rx, ry), "dir": dir})

func _setup_tracking_pings() -> void:
	ping_timer = 5.0 # Every 5 seconds

func _setup_tumbleweeds() -> void:
	# Add 1-3 bouncy obstacles
	for i in range(randi() % 3 + 1):
		var rx = randf_range(-400, 400)
		var ry = randf_range(-200, 200)
		var dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		tumbleweeds.append({"pos": Vector2(rx, ry), "dir": dir, "speed": 120.0})

func _apply_theme() -> void:
	match floor_level:
		1: # Localhost
			color_background = Color(0.02, 0.02, 0.04)
			color_grid = Color(0.0, 0.8, 1.0, 0.15)
			color_wall = Color(0.1, 0.1, 0.15)
		2: # Dead Sector
			color_background = Color(0.05, 0.05, 0.05)
			color_grid = Color(0.5, 0.5, 0.5, 0.2) # Monochromatic grey
			color_wall = Color(0.2, 0.2, 0.2)
		3: # Deep Web
			color_background = Color(0.0, 0.0, 0.0)
			color_grid = Color(0.4, 0.1, 0.6, 0.2) # Purple
			color_wall = Color(0.05, 0.0, 0.1)
		4: # Overclocked Core
			color_background = Color(0.1, 0.02, 0.02)
			color_grid = Color(1.0, 0.2, 0.0, 0.2) # Red
			color_wall = Color(0.2, 0.1, 0.1)
		5: # Quantum Buffer
			color_background = Color(0.02, 0.05, 0.05)
			color_grid = Color(0.0, 1.0, 0.8, 0.2) # Teal
			color_wall = Color(0.1, 0.2, 0.2)
		_:
			pass
			
	if is_buffer_room:
		color_background = Color(0.05, 0.0, 0.05) # Dark Purple/Magenta for challenges
		color_grid = Color(1.0, 0.0, 1.0, 0.1)

func _setup_deletion_zones() -> void:
	# Add 2-3 dangerous zones that toggle
	for i in range(randi() % 2 + 2):
		var rx = randf_range(-400, 400)
		var ry = randf_range(-200, 200)
		deletion_zones.append(Rect2(rx, ry, 128, 128))

func _setup_entry_detection() -> void:
	var area = Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1 # Player layer
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(1280, 720) # Detection zone full room size
	shape.shape = rect
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_player_body_entered)

func _build_collisions() -> void:
	walls_body = StaticBody2D.new()
	walls_body.collision_layer = 1 # Ensure player (mask 1) collides
	add_child(walls_body)
	
	var half_w = 640.0
	var half_h = 360.0
	var wall_thickness = 16.0
	var door_blocker_thickness = 8.0 # THINNER: Prevents trapping player in the collision
	var door_size = 180.0 # INCREASED: Make the physical gap much wider for larger sprites!
	
	var wall_w = half_w - door_size / 2.0
	var wall_h = half_h - door_size / 2.0
	
	# Top Left & Right
	_add_coll(Vector2(-half_w + wall_w/2.0, -half_h + wall_thickness/2.0), Vector2(wall_w, wall_thickness))
	_add_coll(Vector2(half_w - wall_w/2.0, -half_h + wall_thickness/2.0), Vector2(wall_w, wall_thickness))
	# Bottom Left & Right
	_add_coll(Vector2(-half_w + wall_w/2.0, half_h - wall_thickness/2.0), Vector2(wall_w, wall_thickness))
	_add_coll(Vector2(half_w - wall_w/2.0, half_h - wall_thickness/2.0), Vector2(wall_w, wall_thickness))
	# Left Top & Bottom
	_add_coll(Vector2(-half_w + wall_thickness/2.0, -half_h + wall_h/2.0), Vector2(wall_thickness, wall_h))
	_add_coll(Vector2(-half_w + wall_thickness/2.0, half_h - wall_h/2.0), Vector2(wall_thickness, wall_h))
	# Right Top & Bottom
	_add_coll(Vector2(half_w - wall_thickness/2.0, -half_h + wall_h/2.0), Vector2(wall_thickness, wall_h))
	_add_coll(Vector2(half_w - wall_thickness/2.0, half_h - wall_h/2.0), Vector2(wall_thickness, wall_h))
	
	# Door blockers (closed by default)
	_add_door_blocker(Vector2(0, -half_h + door_blocker_thickness/2.0), Vector2(door_size, door_blocker_thickness))
	_add_door_blocker(Vector2(0, half_h - door_blocker_thickness/2.0), Vector2(door_size, door_blocker_thickness))
	_add_door_blocker(Vector2(-half_w + door_blocker_thickness/2.0, 0), Vector2(door_blocker_thickness, door_size))
	_add_door_blocker(Vector2(half_w - door_blocker_thickness/2.0, 0), Vector2(door_blocker_thickness, door_size))

func _add_coll(pos: Vector2, size: Vector2) -> void:
	var shape = RectangleShape2D.new()
	shape.size = size
	var col = CollisionShape2D.new()
	col.shape = shape
	col.position = pos
	walls_body.add_child(col)

func _add_door_blocker(pos: Vector2, size: Vector2) -> void:
	var shape = RectangleShape2D.new()
	shape.size = size
	var col = CollisionShape2D.new()
	col.shape = shape
	col.position = pos
	col.disabled = false # By default, block all doors until explicitly opened
	walls_body.add_child(col)
	door_blockers.append(col)

func _process(_delta: float) -> void:
	if tumbleweeds.size() > 0:
		_process_tumbleweeds(_delta)

	if deletion_zones.size() > 0:
		_process_deletion_zones(_delta)
		
	if floor_name.contains("Deep Web"):
		_process_tracking_pings(_delta)
	elif floor_name.contains("Overclocked Core"):
		_process_exhaust_vents(_delta)

func _process_exhaust_vents(delta: float) -> void:
	vent_cycle_timer += delta
	if vent_cycle_timer > 3.0:
		vent_cycle_timer = 0.0
		vent_active = !vent_active
		queue_redraw()
	
	if vent_active:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var p = players[0]
			var local_p = to_local(p.global_position)
			for vent in vents:
				var beam_end = vent.pos + vent.dir * 1000.0
				# Simple ray-point distance check (vent beam is a line segment)
				# Since vent.dir is axis aligned, it's easier
				if vent.dir.x != 0: # Horizontal
					if abs(local_p.y - vent.pos.y) < 20.0:
						if (vent.dir.x > 0 and local_p.x > vent.pos.x) or (vent.dir.x < 0 and local_p.x < vent.pos.x):
							p.take_damage(1)
				else: # Vertical
					if abs(local_p.x - vent.pos.x) < 20.0:
						if (vent.dir.y > 0 and local_p.y > vent.pos.y) or (vent.dir.y < 0 and local_p.y < vent.pos.y):
							p.take_damage(1)

func _process_tracking_pings(delta: float) -> void:
	ping_timer -= delta
	if ping_timer <= 0:
		ping_timer = 6.0
		ping_active = true
		ping_radius = 0.0
		# Alert enemies
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if e.get_parent() == self:
				# Force AI to target player immediately if within room
				pass
	
	if ping_active:
		ping_radius += delta * 800.0
		if ping_radius > 1000.0:
			ping_active = false
		queue_redraw()

func _process_deletion_zones(delta: float) -> void:
	deletion_timer += delta
	if deletion_timer > 2.0:
		deletion_timer = 0.0
		deletion_active = !deletion_active
		queue_redraw()
	
	if deletion_active:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var p = players[0]
			var local_p = to_local(p.global_position)
			for zone in deletion_zones:
				if zone.has_point(local_p):
					p.take_damage(1) # Player takes damage if in active zone

func _process_tumbleweeds(delta: float) -> void:
	var half_w = 640.0 - 40.0 # Collision padding
	var half_h = 360.0 - 40.0
	
	for weed in tumbleweeds:
		weed.pos += weed.dir * weed.speed * delta
		
		# Bounce off walls
		if abs(weed.pos.x) > half_w:
			weed.dir.x *= -1
			weed.pos.x = sign(weed.pos.x) * half_w
		if abs(weed.pos.y) > half_h:
			weed.dir.y *= -1
			weed.pos.y = sign(weed.pos.y) * half_h
			
		# Check player hit
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var p = players[0]
			var local_p = to_local(p.global_position)
			if weed.pos.distance_to(local_p) < 30.0:
				p.take_damage(1)
	queue_redraw()

func _on_player_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var level_gen = get_tree().get_first_node_in_group("level_generator")
		if level_gen and level_gen.has_method("_on_room_entered"):
			level_gen._on_room_entered(grid_pos)
		
		# Update HUD with player signals
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			if not body.health_changed.is_connected(hud._on_player_health_changed):
				body.health_changed.connect(hud._on_player_health_changed)
			if body.has_signal("bandwidth_changed") and not body.bandwidth_changed.is_connected(hud._on_bandwidth_changed):
				body.bandwidth_changed.connect(hud._on_bandwidth_changed)
			
			hud.set_player_stats(body.stats)
			hud._on_player_health_changed(body.current_health, body.stats.max_health)
			hud._on_bandwidth_changed(body.bandwidth)
			hud.update_minimap(level_gen, grid_pos)
		
		if not is_cleared and not enemies_spawned:
			# Isaac-style: Spawn enemies when player is deep enough in or after a tiny delay
			# For now, trigger immediately upon the camera snapping
			_check_spawn_trigger()

func _check_spawn_trigger() -> void:
	if enemies_spawned or is_cleared: return
	var cam = get_viewport().get_camera_2d()
	if cam and cam.global_position.distance_to(global_position) < 50.0:
		# Grace period: Wait 0.4s to ensure player is fully inside before locking doors
		await get_tree().create_timer(0.4).timeout
		if is_instance_valid(self):
			spawn_enemies()
	else:
		# Retry in a few frames
		await get_tree().process_frame
		_check_spawn_trigger()

func _draw() -> void:
	var half_w = 640.0
	var half_h = 360.0
	
	# 1. Draw the server floor
	draw_rect(Rect2(-half_w, -half_h, half_w * 2, half_h * 2), color_background)
	
	# 2. Draw Tracking Ping
	if ping_active:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var p_pos = to_local(players[0].global_position)
			draw_arc(p_pos, ping_radius, 0, TAU, 32, Color(0.8, 0.2, 1.0, 0.4 * (1.0 - ping_radius/1000.0)), 4.0)

	# 2.5 Draw Exhaust Vents
	for vent in vents:
		draw_rect(Rect2(vent.pos - Vector2(10, 10), Vector2(20, 20)), Color(0.3, 0.3, 0.3))
		if vent_active:
			var beam_color = Color(1.0, 0.2, 0.0, 0.8) # Red beam
			var beam_end = vent.pos + vent.dir * 1280.0 # Long beam
			draw_line(vent.pos, beam_end, beam_color, 4.0)
			# Outer glow
			draw_line(vent.pos, beam_end, Color(1, 0.5, 0, 0.3), 12.0)
		else:
			# Warning flicker
			if vent_cycle_timer > 2.0:
				draw_rect(Rect2(vent.pos - Vector2(10, 10), Vector2(20, 20)), Color(1, 0.5, 0, 0.5))

	# 3. Draw the Deletion Zones (if any)
	if deletion_zones.size() > 0:
		for zone in deletion_zones:
			var alpha = 0.4 if deletion_active else 0.05
			var c = Color(1.0, 0.0, 0.0, alpha) # Red danger
			draw_rect(zone, c)
			if deletion_active:
				# Glitchy border
				draw_rect(zone, Color(1, 1, 1, 0.2), false, 2.0)

	# 3. Data Trash Tumbleweeds
	for weed in tumbleweeds:
		var c = Color(0.6, 0.6, 0.6, 0.8) # Grey trash
		draw_circle(weed.pos, 15, c)
		# Draw some glitchy lines inside
		for i in range(4):
			var v1 = Vector2(randf_range(-10, 10), randf_range(-10, 10))
			var v2 = Vector2(randf_range(-10, 10), randf_range(-10, 10))
			draw_line(weed.pos + v1, weed.pos + v2, Color.WHITE, 1.0)

	# 4. Draw the Neon Grid Matrix
	var grid_step = 64.0
	
	for x in range(int(-half_w), int(half_w), int(grid_step)):
		draw_line(Vector2(x, -half_h), Vector2(x, half_h), color_grid, 2.0)
	for y in range(int(-half_h), int(half_h), int(grid_step)):
		draw_line(Vector2(-half_w, y), Vector2(half_w, y), color_grid, 2.0)
	
	# 4. Border Walls
	var wall_thickness = 16.0
	var door_size = 180.0 
	
	draw_rect(Rect2(-half_w, -half_h, half_w * 2, wall_thickness), color_wall) # top
	draw_rect(Rect2(-half_w, half_h - wall_thickness, half_w * 2, wall_thickness), color_wall) # bottom
	draw_rect(Rect2(-half_w, -half_h, wall_thickness, half_h * 2), color_wall) # left
	draw_rect(Rect2(half_w - wall_thickness, -half_h, wall_thickness, half_h * 2), color_wall) # right
	
	# 5. Firewalls
	var open_color = Color(0.0, 0.8, 1.0, 0.2) # Subtle cyan glow for OPEN doors
	var top_c = color_firewall if doors_locked else open_color
	var bot_c = color_firewall if doors_locked else open_color
	var left_c = color_firewall if doors_locked else open_color
	var right_c = color_firewall if doors_locked else open_color
	
	if top_door and top_door.visible: draw_rect(Rect2(-door_size/2, -half_h, door_size, wall_thickness), top_c)
	if bottom_door and bottom_door.visible: draw_rect(Rect2(-door_size/2, half_h - wall_thickness, door_size, wall_thickness), bot_c)
	if left_door and left_door.visible: draw_rect(Rect2(-half_w, -door_size/2, wall_thickness, door_size), left_c)
	if right_door and right_door.visible: draw_rect(Rect2(half_w - wall_thickness, -door_size/2, wall_thickness, door_size), right_c)

	# Special room highlights
	if is_item_room:
		draw_circle(Vector2(0, 5), 15, Color(0.2, 0.8, 1.0, 0.3)) # Glowing item pedestal base
	elif is_shop_room:
		draw_rect(Rect2(-150, -30, 300, 60), Color(0.1, 0.4, 0.5, 0.2)) # Shop rug

# Open specific doors based on neighbors
func open_doors(top: bool, bottom: bool, left: bool, right: bool):
	active_doors = {"top": top, "bottom": bottom, "left": left, "right": right}
	
	if is_inside_tree() or top_door != null:
		_update_visual_doors()
		_update_door_locks()

func _update_visual_doors():
	if top_door: top_door.visible = active_doors["top"]
	if bottom_door: bottom_door.visible = active_doors["bottom"]
	if left_door: left_door.visible = active_doors["left"]
	if right_door: right_door.visible = active_doors["right"]

func force_open_door(dir: String) -> void:
	match dir:
		"top": active_doors["top"] = true; if top_door: top_door.visible = true
		"bottom": active_doors["bottom"] = true; if bottom_door: bottom_door.visible = true
		"left": active_doors["left"] = true; if left_door: left_door.visible = true
		"right": active_doors["right"] = true; if right_door: right_door.visible = true
	
	_update_door_locks()
	queue_redraw()

func _update_door_locks() -> void:
	if len(door_blockers) < 4: return
	door_blockers[0].set_deferred("disabled", active_doors["top"] and not doors_locked)
	door_blockers[1].set_deferred("disabled", active_doors["bottom"] and not doors_locked)
	door_blockers[2].set_deferred("disabled", active_doors["left"] and not doors_locked)
	door_blockers[3].set_deferred("disabled", active_doors["right"] and not doors_locked)
	queue_redraw()
	
func spawn_enemies() -> void:
	if enemies_spawned or is_cleared:
		return
		
	enemies_spawned = true
	print("Spawning entities in room: ", grid_pos)
	
	if is_boss_room:
		# Randomize which boss spawns
		var boss_scenes = []
		if boss_scene: boss_scenes.append(boss_scene)
		if toxic_sludge_scene: boss_scenes.append(toxic_sludge_scene)
		
		if boss_scenes.size() > 0:
			var selected_boss = boss_scenes[randi() % boss_scenes.size()]
			var boss = selected_boss.instantiate()
			boss.position = Vector2.ZERO # Spawn exact center
			
			# Logic to pick specific boss variation for the generic "Boss" scene
			if boss.name == "Boss" or boss.get_script().get_global_name() == "Boss":
				# Randomize between MONSTRO, DUKE, MECH, NECRO, NANITE_SWARM
				var types = [0, 1, 2, 3, 4] # BossType indices
				boss.boss_type = types[randi() % types.size()]
			
			# Give it the "boss" group for the HUD to find it
			boss.add_to_group("boss")
			call_deferred("add_child", boss)
			
			# Hook HUD dynamically
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("register_boss"):
				hud.register_boss(boss)
				
			# Hook death logic to spawn the win state
			if boss.has_signal("boss_defeated"):
				boss.boss_defeated.connect(_on_boss_defeated)
			
			spawned_enemy_nodes.append(boss)
			doors_locked = true
			_update_door_locks()
			
	elif is_item_room and item_scene:
		var item = item_scene.instantiate()
		item.position = Vector2(0, -10)
		item.item_id = _get_unique_item_id()
		add_child(item)
		_on_room_cleared()
		
	elif is_npc_room:
		var npc_script = load("res://RogueAI.gd")
		var npc = Node2D.new()
		npc.set_script(npc_script)
		npc.position = Vector2.ZERO
		add_child(npc)
		_on_room_cleared()
		
	elif is_buffer_room:
		# Challenge Room: Spawn a series of items after waves. For now, just a hard combat room.
		_spawn_challenge_waves()
		
	elif is_shop_room:
		var items_to_spawn = 3
		for i in range(items_to_spawn):
			var is_perm_item = (randf() < 0.5)
			
			var store_node = null
			if is_perm_item and item_scene:
				store_node = item_scene.instantiate()
				store_node.item_id = _get_unique_item_id()
				store_node.price = 15
			elif pickup_scene:
				store_node = pickup_scene.instantiate()
				store_node.price = 5 - (randi() % 2) # 4 or 5 memory units
				
				# NEW: Force it to be a System Repair (Health = Type 0) so it doesn't sell currency!
				# NOTE: Looking at Pickup.gd, Health is Type 0. User said Type 2 but that's Medium Memory.
				# I will use Type 0 for Health.
				store_node.pickup_type = 0 
				
			if store_node:
				var x_offset = -100 + (i * 100)
				store_node.position = Vector2(x_offset, -10)
				add_child(store_node)
				
		_on_room_cleared()
		
	elif is_devil_room:
		var items_to_spawn = (randi() % 2) + 1 # 1 or 2 items
		for i in range(items_to_spawn):
			if item_scene:
				var store_node = item_scene.instantiate()
				store_node.item_id = _get_unique_item_id()
				
				# Quality-based pricing! (ID 7, 12, 14, 25 are very strong)
				store_node.price_hp = 2 if store_node.item_id in [7, 12, 14, 25] else 1
				
				var x_offset = -60 + (i * 120) if items_to_spawn > 1 else 0
				store_node.position = Vector2(x_offset, -10)
				add_child(store_node)
				
		_on_room_cleared()
		
	elif is_secret_room and item_scene:
		# Secret rooms have a guaranteed rare synergy item or familiar
		var item = item_scene.instantiate()
		item.position = Vector2(0, -10)
		item.item_id = _get_unique_item_id(3, 23) # Only synergy/rare/familiar/active items
		add_child(item)
		_on_room_cleared()
		
	elif enemy_scene:
		# Randomize number of enemies based on floor
		var min_e = 1 + (floor_level - 1)
		var max_e = 3 + floor_level
		var num_enemies = randi() % (max_e - min_e + 1) + min_e
		
		for i in range(num_enemies):
			var enemy = enemy_scene.instantiate()
			
			# Choose enemy type based on floor
			var e_type = 0
			var roll = randf()
			if floor_level == 1: # Localhost
				if roll < 0.6: e_type = 0 # 60% chaser
				elif roll < 0.9: e_type = 5 # 30% fly
				else: e_type = 1 # 10% shooter
			elif floor_level == 2: # Dead Sector (Recycle Bin)
				if roll < 0.4: e_type = 7 # 40% snare bot
				elif roll < 0.7: e_type = 0 # 30% chaser
				elif roll < 0.9: e_type = 5 # 20% fly
				else: e_type = 6 # 10% fatty
			elif floor_level == 3: # Deep Web
				if roll < 0.3: e_type = 9 # 30% glitch wraith
				elif roll < 0.6: e_type = 1 # 30% shooter
				elif roll < 0.8: e_type = 3 # 20% flanker
				else: e_type = 8 # 20% proxy drone
			elif floor_level == 4: # Overclocked Core
				if roll < 0.3: e_type = 2 # 30% tank
				elif roll < 0.6: e_type = 8 # 30% proxy drone
				elif roll < 0.8: e_type = 1 # 20% shooter
				else: e_type = 9 # 20% glitch wraith
			else: # Floor 5+
				e_type = randi() % 10 # Total chaos
				
			enemy.enemy_type = e_type
			var offset = Vector2(randf_range(-400, 400), randf_range(-200, 200))
			enemy.position = offset
			call_deferred("add_child", enemy)
			enemy.enemy_died.connect(_on_enemy_died)
			spawned_enemy_nodes.append(enemy)
			
		# Spawn Obstacles & Hazards
		var num_obs = randi() % 6 + 2 # 2 to 7 obstacles
		for i in range(num_obs):
			var r = randf()
			var obs = null
			
			if r < 0.2 and barrel_scene:
				obs = barrel_scene.instantiate()
			elif r < 0.35 and spikes_scene: # 15% chance for spikes
				obs = spikes_scene.instantiate()
			else:
				obs = obstacle_scene.instantiate()
				obs.obstacle_type = randi() % 2 # Force assign type directly so no internal resetting happens on _ready
			
			var rx = randf_range(-450, 450)
			var ry = randf_range(-200, 200)
			# Push away from exact center drop-point
			if abs(rx) < 150 and abs(ry) < 150:
				rx = 180 * sign(rx) if rx != 0 else 180
				ry = 180 * sign(ry) if ry != 0 else 180
			obs.position = Vector2(rx, ry)
			call_deferred("add_child", obs)
			
	# Apply Template-based layout if exists
	var combined_layouts = []
	if template: combined_layouts.append_array(template.layouts)
	combined_layouts.append_array(layouts_dict)
	
	for layout in combined_layouts:
			var pos = layout["pos"]
			var type = layout["type"]
			var node = null
			
			match type:
				0: # Obstacle
					node = obstacle_scene.instantiate()
					if layout.has("subtype"): node.obstacle_type = int(layout["subtype"])
				1: # TNT
					node = tnt_scene.instantiate()
				2: # Turret
					node = turret_scene.instantiate()
				3: # Enemy
					node = enemy_scene.instantiate()
					if layout.has("subtype"): node.enemy_type = int(layout["subtype"])
					spawned_enemy_nodes.append(node)
			
			if node:
				node.position = pos
				call_deferred("add_child", node)
				if "enemy_died" in node:
					node.enemy_died.connect(_on_enemy_died)
			
	# Lock doors to trap player
	if spawned_enemy_nodes.size() > 0:
		doors_locked = true
		_update_door_locks()
	elif not is_boss_room: # Let boss room logic handle itself
		_on_room_cleared() # Just in case it spawned 0 enemies (if we ever allow that)

func _on_enemy_died() -> void:
	# Small delay to ensure is_queued_for_deletion is accurate if needed
	await get_tree().process_frame
	
	if doors_locked:
		var all_dead = true
		for e in spawned_enemy_nodes:
			if is_instance_valid(e) and not e.is_queued_for_deletion():
				all_dead = false
				break
		
		if all_dead:
			_on_room_cleared()

func _on_room_cleared() -> void:
	if is_cleared: return
	
	print("Room Cleared: ", grid_pos)
	is_cleared = true
	doors_locked = false
	SFX.play_door_unlock()
	cleared.emit()
	
	# Charge the player's active item
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0].has_method("add_active_charge"):
		players[0].add_active_charge(1)
		
	_update_door_locks()
	
	# Trapdoors are dropped directly by the bosses upon death

func _on_boss_defeated() -> void:
	_on_room_cleared()

func _get_unique_item_id(min_id: int = 0, max_id: int = 23) -> int:
	var level_gen = get_parent()
	var used = level_gen.get("used_item_ids") if level_gen else null
	
	# If all real items are taken, serve the joke item
	if used != null and used.size() >= (max_id - min_id + 1):
		return 24 # Breakfast!
	
	var id = randi_range(min_id, max_id)
	var attempts = 0
	while used != null and id in used and attempts < 30:
		id = randi_range(min_id, max_id)
		attempts += 1
	
	if used != null:
		used.append(id)
	return id

func _spawn_challenge_waves() -> void:
	current_wave = 1
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_popup("BUFFER OVERFLOW: CLEAR WAVES FOR DATA RECOVERY [1/3]")
	_spawn_wave_enemies()
	doors_locked = true
	_update_door_locks()

func _spawn_wave_enemies() -> void:
	# Spawn 3-5 random enemies
	var count = 3 + current_wave
	for i in range(count):
		var enemy = enemy_scene.instantiate()
		# Random position
		enemy.position = Vector2(randf_range(-450, 450), randf_range(-250, 250))
		add_child(enemy)
		enemy.enemy_died.connect(_on_enemy_defeated)
		spawned_enemy_nodes.append(enemy)

func _on_enemy_defeated(enemy: Node) -> void:
	if enemy in spawned_enemy_nodes:
		spawned_enemy_nodes.erase(enemy)
		
	if spawned_enemy_nodes.is_empty() and is_buffer_room:
		if current_wave < max_waves:
			current_wave += 1
			var hud = get_tree().get_first_node_in_group("hud")
			if hud:
				hud.show_popup("CLEANING BUFFER... NEXT WAVE [ " + str(current_wave) + "/3 ]")
			await get_tree().create_timer(1.2).timeout
			if is_instance_valid(self):
				_spawn_wave_enemies()
		else:
			_on_buffer_cleared()

func _on_buffer_cleared() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_popup("BUFFER FLUSHED: REWARDS RECOVERED")
	# Spawn 2 items in the center
	for i in range(2):
		var item = item_scene.instantiate()
		item.position = Vector2((i - 0.5) * 120.0, 0)
		item.item_id = _get_unique_item_id()
		add_child(item)
	
	_on_room_cleared()
