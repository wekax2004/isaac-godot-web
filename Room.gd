extends Node2D
class_name Room

@export var top_door: Node2D
@export var bottom_door: Node2D
@export var left_door: Node2D
@export var right_door: Node2D

@export var enemy_scene: PackedScene # Drag the saved Enemy.tscn here

var grid_pos: Vector2
var is_cleared: bool = false
var enemies_spawned: bool = false

# Optional: Add Marker2D nodes as children of the Room and put them in this group
@onready var spawn_markers = get_tree().get_nodes_in_group("enemy_spawn_points")

# Open specific doors based on neighbors
func open_doors(top: bool, bottom: bool, left: bool, right: bool):
	if top_door: top_door.visible = top
	if bottom_door: bottom_door.visible = bottom
	if left_door: left_door.visible = left
	if right_door: right_door.visible = right
	
func spawn_enemies() -> void:
	if enemies_spawned or is_cleared or not enemy_scene:
		return
		
	enemies_spawned = true
	print("Spawning enemies in room: ", grid_pos)
	
	# If we have explicit markers set up in the editor
	if spawn_markers.size() > 0:
		for marker in spawn_markers:
			# Instantiate only if it's a child marker of THIS specific room instance
			if marker.get_parent() == self:
				var enemy = enemy_scene.instantiate()
				enemy.global_position = marker.global_position
				add_child(enemy)
	else:
		# Fallback: Just spawn a random number (1 to 3) near the center of the room
		var num_enemies = randi() % 3 + 1
		for i in range(num_enemies):
			var enemy = enemy_scene.instantiate()
			# Scatter them cleanly from the room's origin (center)
			var offset = Vector2(randf_range(-150, 150), randf_range(-150, 150))
			enemy.global_position = global_position + offset
			add_child(enemy)

# Note: In Godot, connect an Area2D ('RoomTrigger') in the center of the room to this signal.
# When the player walks into the center area, it triggers the spawning.
func _on_room_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		spawn_enemies()
		
		# Optional: You'd want logic here to lock the doors until all child enemies are queue_free'd!
