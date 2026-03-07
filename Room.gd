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
var secret_revealed: bool = false
var player_ref: Node2D = null
var floor_level: int = 1

var spawn_markers: Array = []

var walls_body: StaticBody2D
# Indices: 0=top, 1=bottom, 2=left, 3=right
var door_blockers: Array[CollisionShape2D] = []
var active_doors: Dictionary = {"top": false, "bottom": false, "left": false, "right": false}
var doors_locked: bool = false
var spawned_enemy_nodes: Array[Node] = []

func _ready() -> void:
	queue_redraw()
	spawn_markers = get_tree().get_nodes_in_group("enemy_spawn_points")
	# Wire door references by node path
	if has_node("TopDoor"): top_door = $TopDoor
	if has_node("BottomDoor"): bottom_door = $BottomDoor
	if has_node("LeftDoor"): left_door = $LeftDoor
	if has_node("RightDoor"): right_door = $RightDoor
	
	_build_collisions()
	_setup_entry_detection()

func _setup_entry_detection() -> void:
	var area = Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1 # Player layer
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(1100, 540) # Detection zone slightly smaller than walls
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
	var door_size = 40.0
	
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
	_add_door_blocker(Vector2(0, -half_h + wall_thickness/2.0), Vector2(door_size, wall_thickness))
	_add_door_blocker(Vector2(0, half_h - wall_thickness/2.0), Vector2(door_size, wall_thickness))
	_add_door_blocker(Vector2(-half_w + wall_thickness/2.0, 0), Vector2(wall_thickness, door_size))
	_add_door_blocker(Vector2(half_w - wall_thickness/2.0, 0), Vector2(wall_thickness, door_size))

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

func _process(delta: float) -> void:
	if is_cleared: return
	
	# Monitor enemies if locked
	if doors_locked:
		var all_dead = true
		for e in spawned_enemy_nodes:
			if is_instance_valid(e) and not e.is_queued_for_deletion():
				all_dead = false
				break
		
		if all_dead:
			_on_room_cleared()

func _on_player_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var level_gen = get_tree().get_first_node_in_group("level_generator")
		if level_gen and level_gen.has_method("_on_room_entered"):
			level_gen._on_room_entered(grid_pos)
		
		if not is_cleared and not enemies_spawned:
			# Isaac-style: Spawn enemies when player is deep enough in or after a tiny delay
			# For now, trigger immediately upon the camera snapping
			_check_spawn_trigger()

func _check_spawn_trigger() -> void:
	if enemies_spawned or is_cleared: return
	var cam = get_viewport().get_camera_2d()
	if cam and cam.global_position.distance_to(global_position) < 50.0:
		spawn_enemies()
	else:
		# Retry in a few frames
		await get_tree().process_frame
		_check_spawn_trigger()

func _draw() -> void:
	# Draw the room floor
	var half_w = 640.0
	var half_h = 360.0
	var tile_size = 80.0
	
	# Base Floor 1 Theme: Basement (Brown/Sepia)
	var color_a = Color(0.15, 0.12, 0.1)
	var color_b = Color(0.18, 0.15, 0.13)
	var wall_color = Color(0.35, 0.3, 0.25)
	
	# Theme mapping based on floor level
	if floor_level == 2:
		# Floor 2 Theme: Caves (Dark Blue/Cyan)
		color_a = Color(0.08, 0.12, 0.18)
		color_b = Color(0.1, 0.15, 0.22)
		wall_color = Color(0.2, 0.28, 0.38)
	elif floor_level >= 3:
		# Floor 3+ Theme: Depths (Fleshy Red/Dark Purple)
		color_a = Color(0.18, 0.08, 0.1)
		color_b = Color(0.22, 0.1, 0.12)
		wall_color = Color(0.38, 0.15, 0.2)
	
	if is_boss_room:
		color_a = Color(0.2, 0.05, 0.05)
		color_b = Color(0.25, 0.08, 0.08)
	elif is_item_room:
		color_a = Color(0.25, 0.22, 0.1)
		color_b = Color(0.3, 0.25, 0.1)
	elif is_shop_room:
		color_a = Color(0.1, 0.22, 0.1)
		color_b = Color(0.15, 0.28, 0.15)
	elif is_devil_room:
		color_a = Color(0.15, 0.0, 0.0)
		color_b = Color(0.2, 0.0, 0.0)
		wall_color = Color(0.3, 0.05, 0.05)
	elif is_secret_room:
		color_a = Color(0.3, 0.25, 0.05)
		color_b = Color(0.35, 0.3, 0.08)
		wall_color = Color(0.5, 0.45, 0.15)

	# Draw Checkerboard Floor
	if floor_texture:
		# We can use draw_texture_rect with tile = true if we setup a region, 
		# but draw_rect with a texture is simpler for a single call in _draw
		var floor_rect = Rect2(-half_w, -half_h, half_w * 2, half_h * 2)
		# tile size 80
		draw_texture_rect(floor_texture, floor_rect, true)
	else:
		var start_x_idx = 0
		for x in range(int(-half_w), int(half_w), int(tile_size)):
			var is_color_a = (start_x_idx % 2 == 0)
			for y in range(int(-half_h), int(half_h), int(tile_size)):
				var current_color = color_a if is_color_a else color_b
				draw_rect(Rect2(x, y, tile_size, tile_size), current_color)
				is_color_a = !is_color_a
			start_x_idx += 1
		
	# Draw Pedestal if item room
	if is_item_room:
		draw_circle(Vector2(0, 5), 15, Color(0.4, 0.4, 0.4))
		draw_rect(Rect2(-10, -5, 20, 10), Color(0.6, 0.6, 0.6))
	elif is_shop_room:
		# Draw a decorative rug for the shop
		draw_rect(Rect2(-150, -30, 300, 60), Color(0.2, 0.1, 0.1))
	elif is_devil_room:
		# Blood pool rug
		draw_circle(Vector2(0, -10), 100, Color(0.4, 0.0, 0.0, 0.3))
		
	# Border walls
	var wall_thickness = 16.0
	draw_rect(Rect2(-half_w, -half_h, half_w * 2, wall_thickness), wall_color) # top
	draw_rect(Rect2(-half_w, half_h - wall_thickness, half_w * 2, wall_thickness), wall_color) # bottom
	draw_rect(Rect2(-half_w, -half_h, wall_thickness, half_h * 2), wall_color) # left
	draw_rect(Rect2(half_w - wall_thickness, -half_h, wall_thickness, half_h * 2), wall_color) # right
	# Door openings
	var door_size = 40.0
	# Locked doors draw red. Open and clear draw floor color. Unconnected draw wall color.
	var open_color = Color(0.15, 0.12, 0.1)
	var locked_color = Color(0.8, 0.2, 0.2)
	var top_c = locked_color if doors_locked else open_color
	var bot_c = locked_color if doors_locked else open_color
	var left_c = locked_color if doors_locked else open_color
	var right_c = locked_color if doors_locked else open_color
	
	if top_door and top_door.visible: draw_rect(Rect2(-door_size/2, -half_h, door_size, wall_thickness), top_c)
	if bottom_door and bottom_door.visible: draw_rect(Rect2(-door_size/2, half_h - wall_thickness, door_size, wall_thickness), bot_c)
	if left_door and left_door.visible: draw_rect(Rect2(-half_w, -door_size/2, wall_thickness, door_size), left_c)
	if right_door and right_door.visible: draw_rect(Rect2(half_w - wall_thickness, -door_size/2, wall_thickness, door_size), right_c)

# Open specific doors based on neighbors
func open_doors(top: bool, bottom: bool, left: bool, right: bool):
	active_doors = {"top": top, "bottom": bottom, "left": left, "right": right}
	
	if top_door: top_door.visible = top
	if bottom_door: bottom_door.visible = bottom
	if left_door: left_door.visible = left
	if right_door: right_door.visible = right
	
	# Enable paths through connected doors ONLY if room is cleared/safe
	_update_door_locks()

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
			
			# Randomize boss type for original boss
			if boss.get("boss_type") != null and randf() < 0.5:
				boss.boss_type = 1 # DUKE_OF_FLIES
			
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
				store_node.price = 5 - (randi() % 2) # 4 or 5 coins
				
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
			if floor_level == 1:
				if roll < 0.7: e_type = 0 # 70% basic
				elif roll < 0.9: e_type = 1 # 20% chaser
				else: e_type = 2 # 10% tank
			elif floor_level == 2:
				if roll < 0.3: e_type = 0 # 30% basic
				elif roll < 0.6: e_type = 1 # 30% chaser
				elif roll < 0.8: e_type = 2 # 20% tank
				else: e_type = 3 # 20% shooter
			else: # Floor 3+
				if roll < 0.1: e_type = 0 # 10% basic
				elif roll < 0.3: e_type = 1 # 20% chaser
				elif roll < 0.6: e_type = 2 # 30% tank
				else: e_type = 3 # 40% shooter
				
			enemy.enemy_type = e_type
			var offset = Vector2(randf_range(-400, 400), randf_range(-200, 200))
			enemy.position = offset
			call_deferred("add_child", enemy)
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
			
	# Lock doors to trap player
	if spawned_enemy_nodes.size() > 0:
		doors_locked = true
		_update_door_locks()
	elif not is_boss_room: # Let boss room logic handle itself
		_on_room_cleared() # Just in case it spawned 0 enemies (if we ever allow that)

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
