extends StaticBody2D

# 0: Rock, 1: Hole
@export var obstacle_type: int = -1

func _ready() -> void:
	if obstacle_type == -1:
		obstacle_type = randi() % 2
		
	# If it's a hole, it shouldn't block tears, but we'll leave that logic for the Tear script
	if obstacle_type == 1:
		add_to_group("holes")
		# Layer 7 = Holes. ground enemies mask this, fliers don't.
		set_collision_layer_value(1, false)
		set_collision_layer_value(7, true)
	else:
		add_to_group("rocks")
		# Layer 1 = Solid world
		set_collision_layer_value(1, true)
		
	queue_redraw()

func _draw() -> void:
	if obstacle_type == 0: # Rock
		# Draw a jagged grayish rock
		var pts = PackedVector2Array([
			Vector2(-24, 24), Vector2(-20, 0), Vector2(-10, -20), 
			Vector2(10, -24), Vector2(20, -10), Vector2(24, 20),
			Vector2(10, 24)
		])
		draw_colored_polygon(pts, Color(0.4, 0.4, 0.45))
		# Inner highlight
		var h_pts = PackedVector2Array([
			Vector2(-10, 10), Vector2(-5, -5), Vector2(5, -10), Vector2(10, 5)
		])
		draw_colored_polygon(h_pts, Color(0.5, 0.5, 0.55))
		
	elif obstacle_type == 1: # Hole
		# Draw a standard pit that contrasts properly with the floor
		draw_circle(Vector2.ZERO, 20, Color(0.02, 0.02, 0.02))
		draw_arc(Vector2.ZERO, 20, 0, TAU, 32, Color(0.1, 0.1, 0.1), 3.0)
		draw_circle(Vector2(0, 0), 16, Color(0.00, 0.00, 0.00))
