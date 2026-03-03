extends Node2D

@export var room_scene: PackedScene
@export var num_rooms: int = 10
@export var room_size: Vector2 = Vector2(800, 600)

var room_grid: Dictionary = {} # Maps Vector2 to Room instances

func _ready() -> void:
	if not room_scene:
		print("CRITICAL: No Room scene attached to LevelGenerator!")
		return
		
	generate_floor()

func generate_floor() -> void:
	# Keep track of layout logically
	var logical_map = {} # Maps Vector2 coord to boolean (exists)
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
	for i in range(num_rooms - 1):
		# Just pick a random cardinal direction
		var dir = directions[randi() % directions.size()]
		walker_pos += dir
		logical_map[walker_pos] = true
		
	# The last room logically instantiated is the Boss room.
	# Or, you can find the furthest leaf node like we did in JS!
	
	# 2. Instantiate the actual visual Room nodes
	for layout_pos in logical_map.keys():
		var room_instance = room_scene.instantiate() as Room
		
		# Space them out visually in Godot's world relative to their (0,0) index
		room_instance.position = layout_pos * room_size
		room_instance.grid_pos = layout_pos
		add_child(room_instance)
		
		room_grid[layout_pos] = room_instance
		
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
