extends Area2D

var speed: float = 200.0
var direction: Vector2 = Vector2.ZERO
var damage: int = 1

func _ready() -> void:
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
		
	call_deferred("queue_free") # Hit player, rock, or wall

func _on_screen_exited() -> void:
	queue_free()
