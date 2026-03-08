extends Node2D

var room_scene: PackedScene = preload("res://Room.tscn")
var player_scene: PackedScene = preload("res://Player.tscn")
var hud_scene: PackedScene = preload("res://HUD.tscn")
@export var is_generating: bool = false
var rooms_to_spawn: int = 8
@export var room_size: Vector2 = Vector2(1280, 720)
@export var final_pos: Vector2 = Vector2.ZERO # Store the boss room pos

var room_grid: Dictionary = {} # Maps Vector2 to Room instances
var logical_map: Dictionary = {} # Store map for HUD minimap
var used_item_ids: Array[int] = [] # Track items spawned this floor to prevent duplicates

var hud_instance: CanvasLayer = null
var current_player: Node2D = null
var camera: Camera2D
var camera_target_pos: Vector2
var last_room_pos: Vector2 = Vector2(-999, -999)
var devil_room_chance: float = 0.35 # Starts at 35%
var player_took_red_heart_damage: bool = false

# Screen shake variables
var shake_intensity: float = 0.0
var shake_duration: float = 0.0

func _ready() -> void:
	add_to_group("level_generator")
	if not room_scene:
		print("CRITICAL: No Room scene attached to LevelGenerator!")
		return
		
	generate_floor()

func next_floor() -> void:
	if is_generating: return
	is_generating = true
	
	if current_player and current_player.stats:
		current_player.stats.current_floor += 1
		
		# Increase min/max rooms based on floor
		rooms_to_spawn = 10 + (current_player.stats.current_floor * 5) 
		
	# 1. Clean up old room instances
	for pos in room_grid.keys():
		var r = room_grid[pos]
		if is_instance_valid(r):
			r.queue_free()
	room_grid.clear()
	logical_map.clear()
	
	# 2. Reset tracking
	last_room_pos = Vector2(-999, -999)
	
	# 3. Clean up old HUD and camera so we can respawn it fresh via generate_floor
	if is_instance_valid(hud_instance):
		hud_instance.queue_free()
	if is_instance_valid(camera):
		camera.queue_free()
		
	# Wait one frame for queue_free to finish to prevent overlap bugs
	await get_tree().process_frame
	
	var floor_num = current_player.stats.current_floor if current_player else 1
	var floor_names = [
		"The Localhost", 
		"The Dead Sector (Recycle Bin)", 
		"The Deep Web", 
		"The Overclocked Core", 
		"The Quantum Buffer",
		"The Dark Fiber",
		"The Root Partition",
		"The Neural Net",
		"The Mainframe Core"
	]
	var floor_name = floor_names[mini(floor_num - 1, floor_names.size() - 1)]
	
	print("----- MIGRATING TO ENVIRONMENT: ", floor_name, " (Node ", floor_num, ") -----")
	generate_floor(true, floor_name)
	is_generating = false

func generate_floor(keep_player: bool = false, override_name: String = "") -> void:
	if override_name != "":
		# Ensure we can use it if needed, or just let the room_instance logic handle it
		pass
	# Keep track of layout logically
	logical_map.clear()
	used_item_ids.clear()
	var current_pos = Vector2.ZERO
	logical_map[current_pos] = true
	
	var walker_pos = current_pos
	
	# Define cardinal directions
	var directions = [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT
	]
	
	# 1. Walk to create the logical bounds
	while logical_map.size() < rooms_to_spawn:
		var dir = directions[randi() % directions.size()]
		walker_pos += dir
		logical_map[walker_pos] = true
		
		# Always update final_pos to the furthest generated room visually
		if walker_pos.length() > final_pos.length():
			final_pos = walker_pos
	
	# 2. Instantiate the actual visual Room nodes
	for layout_pos in logical_map.keys():
		var room_instance = room_scene.instantiate() as Room
		
		# Space them out visually in Godot's world relative to their (0,0) index
		room_instance.position = layout_pos * room_size
		room_instance.grid_pos = layout_pos
		
		if layout_pos == final_pos:
			room_instance.is_boss_room = true
			
		# Pass floor info down to the room for rendering
		if current_player and current_player.stats:
			room_instance.floor_level = current_player.stats.current_floor
			var floor_names = [
				"The Localhost", 
				"The Dead Sector", 
				"The Deep Web", 
				"The Overclocked Core", 
				"The Quantum Buffer",
				"The Dark Fiber",
				"The Root Partition",
				"The Neural Net",
				"The Mainframe Core"
			]
			room_instance.floor_name = floor_names[mini(room_instance.floor_level - 1, floor_names.size() - 1)]
			
		call_deferred("add_child", room_instance)
		
		room_grid[layout_pos] = room_instance
	# 2.5 Find an item room and a shop room
	var item_room_pos = null
	var shop_room_pos = null
	
	var leaves = []
	for layout_pos in logical_map.keys():
		if layout_pos == Vector2.ZERO or layout_pos == final_pos:
			continue
		
		var neighbors = 0
		if logical_map.has(layout_pos + Vector2.UP): neighbors += 1
		if logical_map.has(layout_pos + Vector2.DOWN): neighbors += 1
		if logical_map.has(layout_pos + Vector2.LEFT): neighbors += 1
		if logical_map.has(layout_pos + Vector2.RIGHT): neighbors += 1
		
		if neighbors == 1:
			leaves.append(layout_pos)
			
	if leaves.size() > 0:
		item_room_pos = leaves[0]
	if leaves.size() > 1:
		shop_room_pos = leaves[1]
		
	# Fallback if no dead ends exist
	var fallback_nodes = []
	for layout_pos in logical_map.keys():
		if layout_pos != Vector2.ZERO and layout_pos != final_pos:
			fallback_nodes.append(layout_pos)
			
	if item_room_pos == null and fallback_nodes.size() > 0:
		item_room_pos = fallback_nodes[0]
	if shop_room_pos == null and fallback_nodes.size() > 1:
		shop_room_pos = fallback_nodes[1]

	if item_room_pos != null and room_grid.has(item_room_pos):
		room_grid[item_room_pos].is_item_room = true
	if shop_room_pos != null and room_grid.has(shop_room_pos):
		room_grid[shop_room_pos].is_shop_room = true
	
	# 2.6 Assign random layouts to some rooms
	_assign_random_layouts()
		
	# 2.7 Generate one Secret Room per floor
	var secret_pos = _find_secret_room_position()
	if secret_pos != null:
		logical_map[secret_pos] = true
		var secret_room = room_scene.instantiate() as Room
		secret_room.position = secret_pos * room_size
		secret_room.grid_pos = secret_pos
		secret_room.is_secret_room = true
		if current_player and current_player.stats:
			secret_room.floor_level = current_player.stats.current_floor
		call_deferred("add_child", secret_room)
		room_grid[secret_pos] = secret_room
		
	# 3. Open appropriate doors based on world layout
	for layout_pos in room_grid.keys():
		var room = room_grid[layout_pos]
		
		var has_top = logical_map.has(layout_pos + Vector2.UP)
		var has_bottom = logical_map.has(layout_pos + Vector2.DOWN)
		var has_left = logical_map.has(layout_pos + Vector2.LEFT)
		var has_right = logical_map.has(layout_pos + Vector2.RIGHT)
		
		# Assume +Y in Godot 2D is Down visually
		# So UP logic checks for - Y coords.
		room.open_doors(has_top, has_bottom, has_left, has_right)
		
	print("Floor Generation Complete!")
	
	# Connect Boss room clearing to Devil Room logic
	if room_grid.has(final_pos):
		if room_grid[final_pos].cleared.is_connected(_on_boss_room_cleared):
			room_grid[final_pos].cleared.disconnect(_on_boss_room_cleared)
		room_grid[final_pos].cleared.connect(_on_boss_room_cleared)
	
	# Ensure the starting room is safe
	if room_grid.has(Vector2.ZERO):
		room_grid[Vector2.ZERO].is_cleared = true
	
	# 4. Spawn HUD
	hud_instance = hud_scene.instantiate()
	call_deferred("add_child", hud_instance)

	# 5. Spawn (or reset) the player
	if not keep_player:
		current_player = player_scene.instantiate()
		current_player.add_to_group("player")
		call_deferred("add_child", current_player)
		print("Player spawned at origin!")
		
	current_player.position = Vector2.ZERO # Always start at (0,0) center of new map
	current_player.z_index = 10 # Force draw on top of new floors
	
	# Initial HUD hookups
	if current_player.has_signal("health_changed"):
		current_player.health_changed.connect(hud_instance._on_player_health_changed)
	if current_player.has_signal("bandwidth_changed"):
		current_player.bandwidth_changed.connect(hud_instance._on_bandwidth_changed)
		hud_instance._on_bandwidth_changed(current_player.bandwidth)
	if hud_instance.has_method("set_player_stats") and current_player.get("stats"):
		hud_instance.set_player_stats(current_player.stats)
	if hud_instance.has_method("update_minimap"):
		hud_instance.update_minimap(self, Vector2.ZERO)
	
	# Force sync current health to the new HUD (prevents "healing" between floors)
	if current_player.stats:
		current_player.health_changed.emit(current_player.current_health, current_player.stats.max_health)

	# 6. Spawn Camera
	camera = Camera2D.new()
	camera.zoom = Vector2(1.0, 1.0) # 1:1 screen size
	camera.position = Vector2.ZERO
	camera_target_pos = Vector2.ZERO
	camera.z_index = 20 # Keep above everything
	call_deferred("add_child", camera)

# --- Camera System ---
func _process(delta: float) -> void:
	
	if camera:
		# Very smooth camera movement (Isaac style)
		var lerp_speed = 6.0
		if camera.global_position.distance_to(camera_target_pos) > 100:
			lerp_speed = 12.0 # Snap faster if we "teleport" or move far
			
		camera.global_position = camera.global_position.lerp(camera_target_pos, lerp_speed * delta)
		
		# Screen shake logic
		if shake_duration > 0:
			shake_duration -= delta
			camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
			# Dampen intensity over time
			shake_intensity = lerpf(shake_intensity, 0.0, delta * 5.0)
		else:
			camera.offset = Vector2.ZERO

func shake_camera(intensity: float = 20.0, duration: float = 0.2) -> void:
	shake_intensity = intensity
	shake_duration = duration

func _on_room_entered(grid_pos: Vector2) -> void:
	if hud_instance:
		var closest_pos = grid_pos
		
		# If we changed rooms, update the HUD minimap!
		if closest_pos != last_room_pos:
			last_room_pos = closest_pos
			if hud_instance.has_method("update_minimap"):
				hud_instance.update_minimap(self, closest_pos)
		
		# Set camera target to newly populated closest pos
		var target_pos = closest_pos * room_size
		camera_target_pos = target_pos

func _find_secret_room_position():
	# Find an empty position adjacent to 2+ existing rooms
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var candidates = []
	
	# Scan all border positions
	for pos in logical_map.keys():
		for dir in directions:
			var candidate = pos + dir
			if logical_map.has(candidate):
				continue # Already occupied
			
			# Count how many existing rooms neighbor this candidate
			var adj_count = 0
			for d in directions:
				if logical_map.has(candidate + d):
					adj_count += 1
			
			if adj_count >= 2:
				candidates.append(candidate)
	
	if candidates.size() > 0:
		return candidates[randi() % candidates.size()]
	return null

func _assign_random_layouts() -> void:
	# Define a few patterns
	var patterns = [
		{"name": "Cross", "layouts": [
			{"pos": Vector2(-80, 0), "type": 0}, {"pos": Vector2(80, 0), "type": 0},
			{"pos": Vector2(0, -80), "type": 0}, {"pos": Vector2(0, 80), "type": 0}
		]},
		{"name": "TNT Box", "layouts": [
			{"pos": Vector2(-40, -40), "type": 1}, {"pos": Vector2(40, -40), "type": 1},
			{"pos": Vector2(-40, 40), "type": 1}, {"pos": Vector2(40, 40), "type": 1}
		]},
		{"name": "Turret Corner", "layouts": [
			{"pos": Vector2(-450, -250), "type": 2}, {"pos": Vector2(450, 250), "type": 2}
		]}
	]
	
	for pos in room_grid.keys():
		var room = room_grid[pos]
		if room.is_cleared or room.is_item_room or room.is_boss_room: continue
		
		# 40% chance to have a template layout
		if randf() < 0.4:
			var p = patterns[randi() % patterns.size()]
			room.layouts_dict = p["layouts"]

func _on_boss_room_cleared() -> void:
	# 100% chance if no red damage, or 33% otherwise
	var chance = devil_room_chance
	if not player_took_red_heart_damage:
		chance = 1.0 # Guarantee door
		
	if randf() < chance:
		_spawn_devil_room_door()

func _spawn_devil_room_door() -> void:
	# In a real game, this would be a special Black Door asset in the Boss room
	print("----- THE DEVIL ROOM DOOR OPENS -----")
	# Logic to spawn a temporary room at a far offset and teleport player
	var devil_pos: Vector2 = final_pos + Vector2(100, 100) # Default Fallback teleport
	# Find the best door to open in the current boss room
	if room_grid.has(final_pos):
		var boss_room = room_grid[final_pos]
		# Find an unused door direction
		if not boss_room.active_doors["top"]:
			boss_room.force_open_door("top")
			devil_pos = final_pos + Vector2.UP
		elif not boss_room.active_doors["right"]:
			boss_room.force_open_door("right")
			devil_pos = final_pos + Vector2.RIGHT
		elif not boss_room.active_doors["left"]:
			boss_room.force_open_door("left")
			devil_pos = final_pos + Vector2.LEFT
		elif not boss_room.active_doors["bottom"]:
			boss_room.force_open_door("bottom")
			devil_pos = final_pos + Vector2.DOWN
		else:
			devil_pos = final_pos + Vector2(100, 100) # Fallback teleport
	
	logical_map[devil_pos] = true
	var room_instance = room_scene.instantiate() as Room
	room_instance.position = devil_pos * room_size
	room_instance.grid_pos = devil_pos
	room_instance.is_devil_room = true # Unique devil room logic
	
	# Open the reverse door in the devil room
	if devil_pos == final_pos + Vector2.UP:
		room_instance.active_doors["bottom"] = true
	elif devil_pos == final_pos + Vector2.DOWN:
		room_instance.active_doors["top"] = true
	elif devil_pos == final_pos + Vector2.LEFT:
		room_instance.active_doors["right"] = true
	elif devil_pos == final_pos + Vector2.RIGHT:
		room_instance.active_doors["left"] = true
		
	call_deferred("add_child", room_instance)
	room_grid[devil_pos] = room_instance
	
	# Open the devil room door visually on the next frame so doors line up
	room_instance.call_deferred("open_doors", room_instance.active_doors["top"], room_instance.active_doors["bottom"], room_instance.active_doors["left"], room_instance.active_doors["right"])
