extends Area2D

@export var active_duration: float = 2.0
@export var inactive_duration: float = 2.5
@export var damage: float = 1.0

var is_active: bool = false
var timer: float = 0.0

var sprite: Sprite2D = null

func _ready() -> void:
	add_to_group("hazards")
	# Start at a random point in the timer so spikes aren't synced perfectly across the room
	timer = randf_range(0.0, inactive_duration)

func _physics_process(delta: float) -> void:
	timer -= delta
	
	if timer <= 0:
		is_active = !is_active
		timer = active_duration if is_active else inactive_duration
		queue_redraw()
		
		# If it just became active, damage anything standing on it!
		if is_active:
			_check_damage()

func _draw() -> void:
	if not is_active:
		# Draw flat, inactive hole/plate
		draw_rect(Rect2(-16, -16, 32, 32), Color(0.1, 0.1, 0.1))
		draw_rect(Rect2(-14, -14, 28, 28), Color(0.2, 0.2, 0.2))
	else:
		# Draw spikes extended
		draw_rect(Rect2(-16, -16, 32, 32), Color(0.1, 0.1, 0.1))
		# Draw 4 metallic spikes
		_draw_spike(Vector2(-8, -8))
		_draw_spike(Vector2(8, -8))
		_draw_spike(Vector2(-8, 8))
		_draw_spike(Vector2(8, 8))

func _draw_spike(pos: Vector2) -> void:
	var pts = PackedVector2Array([
		pos + Vector2(-6, 6),
		pos + Vector2(6, 6),
		pos + Vector2(0, -8)
	])
	draw_colored_polygon(pts, Color(0.7, 0.7, 0.8)) # Silver
	# Highlight
	draw_line(pos + Vector2(0, -8), pos + Vector2(6, 6), Color(0.9, 0.9, 1.0), 1.0)

# Continuous damage check if standing inside while active
func _on_body_entered(body: Node2D) -> void:
	_try_damage(body)

func _check_damage() -> void:
	# Get overlapping bodies
	var bodies = get_overlapping_bodies()
	for b in bodies:
		_try_damage(b)

func _try_damage(body: Node2D) -> void:
	if is_active and body.has_method("take_damage"):
		if body.is_in_group("player") or body.is_in_group("enemies"):
			body.take_damage(damage)
