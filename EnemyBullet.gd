extends Area2D

var speed: float = 200.0
var direction: Vector2 = Vector2.ZERO
var damage: int = 1
var snare_duration: float = 0.0

func _ready() -> void:
	self.scale = Vector2(1.3, 1.3)
	queue_redraw()

func _draw() -> void:
	# Red enemy bullet
	draw_circle(Vector2.ZERO, 5, Color(1.0, 0.2, 0.2, 0.5)) # glow
	draw_circle(Vector2.ZERO, 3, Color(1.0, 0.15, 0.15))     # body
	draw_circle(Vector2.ZERO, 1.5, Color(1.0, 0.6, 0.6))     # core

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"): return # don't hit other enemies
	if body.is_in_group("holes"): return # fly over holes
	
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		if snare_duration > 0 and body.has_method("snare"):
			body.snare(snare_duration)
		
	call_deferred("queue_free") # Hit player, rock, or wall

func _on_screen_exited() -> void:
	queue_free()

func set_is_snare(is_snare: bool) -> void:
	if is_snare:
		snare_duration = 2.0
		damage = 0 # Snare doesn't damage directly? Or maybe 1? 
		# Let's keep damage 1 but add snare.
		damage = 1
