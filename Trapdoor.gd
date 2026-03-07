extends Area2D

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# Draw a dark hole
	draw_circle(Vector2.ZERO, 25, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2.ZERO, 20, Color.BLACK)
	# Draw a little ladder inside
	draw_line(Vector2(-8, -10), Vector2(-8, 10), Color(0.4, 0.3, 0.2), 2.0)
	draw_line(Vector2(8, -10), Vector2(8, 10), Color(0.4, 0.3, 0.2), 2.0)
	for y in range(-6, 8, 4):
		draw_line(Vector2(-8, y), Vector2(8, y), Color(0.4, 0.3, 0.2), 2.0)

var has_triggered: bool = false

func _on_body_entered(body: Node2D) -> void:
	if has_triggered: return
	
	if body.is_in_group("player"):
		has_triggered = true
		# Get LevelGenerator root node
		var level_gen = get_tree().get_first_node_in_group("level_generator")
		if level_gen and level_gen.has_method("next_floor"):
			level_gen.call_deferred("next_floor")
		else:
			# Fallback
			get_tree().change_scene_to_file("res://VictoryScreen.tscn")
