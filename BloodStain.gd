extends Node2D

var color: Color = Color(0.8, 0.1, 0.1, 0.6)
var size: float = 1.0

func _ready() -> void:
	z_index = -1 # Draw below enemies and players
	rotation = randf() * TAU
	size = randf_range(0.8, 1.4)
	queue_redraw()

func _draw() -> void:
	# Draw several overlapping circles for a messy splat effect
	var splat_pts = 6
	for i in range(splat_pts):
		var offset = Vector2(randf_range(-8, 8), randf_range(-8, 8)) * size
		var r = randf_range(4, 10) * size
		draw_circle(offset, r, color)
		
	# Add some "drips"
	for i in range(3):
		var drip_pos = Vector2(randf_range(-12, 12), randf_range(-12, 12)) * size
		draw_circle(drip_pos, randf_range(2, 4) * size, color)
