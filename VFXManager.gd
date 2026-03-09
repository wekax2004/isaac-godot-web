extends Node

# Hit-stop effect (frame freezing)
func hit_stop(duration: float = 0.05) -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

# Flash effect for any Node2D with a Sprite2D
func flash_node(node: Node2D, duration: float = 0.1, color: Color = Color.WHITE) -> void:
	if not node or not node.has_node("Sprite2D"): return
	var sprite = node.get_node("Sprite2D")
	var old_mod = sprite.modulate
	sprite.modulate = color
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(sprite):
		sprite.modulate = old_mod

# Screen shake request
func shake_screen(intensity: float = 5.0, duration: float = 0.2) -> void:
	var gen = get_tree().get_first_node_in_group("level_generator")
	if gen and gen.has_method("shake"):
		gen.shake(intensity, duration)

func spawn_sparks(pos: Vector2, color: Color = Color.WHITE, count: int = 5) -> void:
	# Simplified spark spawning using HitSplash for now but smaller/faster
	var splash_scene = load("res://HitSplash.tscn")
	for i in range(count):
		var s = splash_scene.instantiate()
		s.global_position = pos + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		s.scale = Vector2(0.5, 0.5)
		s.color = color
		get_tree().current_scene.add_child(s)
