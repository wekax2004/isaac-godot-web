extends Area2D

var damage: float = 1.0
var lifetime: float = 3.0
var is_player_owned: bool = false
var puddle_color: Color = Color(0.0, 0.6, 1.0, 0.6) # Default cyan

func _ready() -> void:
	# Add visually below player/enemies but above floor
	z_index = -1 
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free)

func _draw() -> void:
	# Use dynamic color
	var coolant_base = puddle_color
	var coolant_highlight = puddle_color
	coolant_highlight.a = min(1.0, coolant_highlight.a + 0.3)
	
	draw_circle(Vector2.ZERO, 15, coolant_base)
	draw_circle(Vector2(4, -2), 8, coolant_highlight)
	draw_circle(Vector2(-6, 5), 10, coolant_highlight)

func _physics_process(delta: float) -> void:
	for body in get_overlapping_bodies():
		if is_player_owned:
			# Hurt enemies/bosses only
			if body.is_in_group("enemies") and body.has_method("take_damage"):
				body.take_damage(damage * delta) # Tick damage
		else:
			# Trap/Env hazard - hurt player only
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(1)
