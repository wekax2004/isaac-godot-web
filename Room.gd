extends Node2D
class_name Room

@export var top_door: Node2D
@export var bottom_door: Node2D
@export var left_door: Node2D
@export var right_door: Node2D

@export var enemy_scene: PackedScene # Drag the saved Enemy.tscn here
@export var boss_scene: PackedScene  # Drag the saved Boss.tscn here
@export var trapdoor_scene: PackedScene # Drag Trapdoor.tscn here

var grid_pos: Vector2
var is_cleared: bool = false
var enemies_spawned: bool = false
var is_boss_room: bool = false # Set by LevelGenerator

# Optional: Add Marker2D nodes as children of the Room and put them in this group
@onready var spawn_markers = get_tree().get_nodes_in_group("enemy_spawn_points")

# Open specific doors based on neighbors
func open_doors(top: bool, bottom: bool, left: bool, right: bool):
	if top_door: top_door.visible = top
	if bottom_door: bottom_door.visible = bottom
	if left_door: left_door.visible = left
	if right_door: right_door.visible = right
	
func spawn_enemies() -> void:
	if enemies_spawned or is_cleared:
		return
		
	enemies_spawned = true
	print("Spawning entities in room: ", grid_pos)
	
	if is_boss_room and boss_scene:
		# Lock doors ideally
		var boss = boss_scene.instantiate()
		boss.global_position = global_position # Spawn exact center
		
		# Give it the "boss" group for the HUD to find it
		boss.add_to_group("boss")
		add_child(boss)
		
		# Hook HUD dynamically
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("register_boss"):
			hud.register_boss(boss)
			
		# Hook death logic to spawn the win state
		boss.boss_defeated.connect(_on_boss_defeated)
			
	elif enemy_scene:
		# Normal enemy spawning logic
		if spawn_markers.size() > 0:
			for marker in spawn_markers:
				if marker.get_parent() == self:
					var enemy = enemy_scene.instantiate()
					enemy.global_position = marker.global_position
					add_child(enemy)
		else:
			var num_enemies = randi() % 3 + 1
			for i in range(num_enemies):
				var enemy = enemy_scene.instantiate()
				var offset = Vector2(randf_range(-150, 150), randf_range(-150, 150))
				enemy.global_position = global_position + offset
				add_child(enemy)

# Note: In Godot, connect an Area2D ('RoomTrigger') in the center of the room to this signal.
# When the player walks into the center area, it triggers the spawning.
func _on_room_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		spawn_enemies()
		
		# Optional: You'd want logic here to lock the doors until all child enemies are queue_free'd!

func _on_boss_defeated() -> void:
	print("Boss Defeated in Room ", grid_pos)
	is_cleared = true
	
	if trapdoor_scene:
		var trapdoor = trapdoor_scene.instantiate()
		trapdoor.global_position = global_position
		# Add it securely using call_deferred since this triggers exactly during physics step destruction
		call_deferred("add_child", trapdoor)

