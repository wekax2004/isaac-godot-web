extends Area2D

var damage: float = 1.0
var lifetime: float = 3.0

func _ready() -> void:
	# Add visually below player/enemies but above floor
	z_index = -1 
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free)

func _draw() -> void:
	# Draw acid puddle
	draw_circle(Vector2.ZERO, 15, Color(0.2, 0.9, 0.3, 0.6))
	draw_circle(Vector2(4, -2), 8, Color(0.4, 1.0, 0.5, 0.6))
	draw_circle(Vector2(-6, 5), 10, Color(0.4, 1.0, 0.5, 0.6))

func _physics_process(delta: float) -> void:
	for body in get_overlapping_bodies():
		# Only hurt player, not bosses/enemies
		if body.is_in_group("player") and body.has_method("take_damage"):
			# Deal tick damage rapidly but at low values
			# Actually standard Take Damage grants i-frames, so we do 1 damage
			body.take_damage(int(damage))
