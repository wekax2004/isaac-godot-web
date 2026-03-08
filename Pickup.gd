extends Area2D

# 0: Health, 1: Small Memory (1), 2: Medium Memory (5), 3: Large Memory (10)
@export var pickup_type: int = -1
@export var price: int = 0

func _ready() -> void:
	self.scale = Vector2(1.5, 1.5)
	# Randomize if not explicitly set
	if pickup_type == -1:
		var r = randf()
		if r < 0.2: pickup_type = 0 # 20% Health
		elif r < 0.7: pickup_type = 1 # 50% Small
		elif r < 0.9: pickup_type = 2 # 20% Medium
		else: pickup_type = 3 # 10% Large
	
	queue_redraw()

func _draw() -> void:
	match pickup_type:
		0: # Health (Heart) - Remains same but techy colors? Let's keep red for clarity.
			draw_circle(Vector2(-4,-2), 5, Color.RED)
			draw_circle(Vector2(4,-2), 5, Color.RED)
			var pts = PackedVector2Array([Vector2(-8,-1), Vector2(8,-1), Vector2(0, 8)])
			draw_colored_polygon(pts, Color.RED)
		1: # Small Memory Fragment (1)
			_draw_fragment(Color(0.2, 0.8, 1.0), 6.0)
		2: # Medium Memory Fragment (5)
			_draw_fragment(Color(0.3, 0.9, 1.0), 10.0)
		3: # Large Memory Fragment (10)
			_draw_fragment(Color(0.5, 1.0, 1.0), 14.0)
			
	if price > 0:
		draw_string(ThemeDB.fallback_font, Vector2(-10, 25), str(price) + " MEM", 0, -1, 14, Color(0.2, 0.8, 1.0))

func _draw_fragment(color: Color, size: float) -> void:
	var pts = PackedVector2Array([
		Vector2(0, -size),
		Vector2(size*0.8, 0),
		Vector2(0, size),
		Vector2(-size*0.8, 0)
	])
	draw_colored_polygon(pts, color)
	# Inner glow
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -size*0.6),
		Vector2(size*0.5, 0),
		Vector2(0, size*0.6),
		Vector2(-size*0.5, 0)
	]), Color.WHITE)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if price > 0:
			var p_bw = body.get("bandwidth")
			if p_bw == null or p_bw < price:
				return # Not enough bandwidth
			body.bandwidth -= price
			body.bandwidth_changed.emit(body.bandwidth)
			
		_apply_pickup(body)
		call_deferred("queue_free")

func _apply_pickup(player: Node2D) -> void:
	match pickup_type:
		0: # Health
			var stats = player.get("stats")
			if stats:
				player.current_health = min(player.current_health + 1, stats.max_health)
				player.health_changed.emit(player.current_health, stats.max_health)
			print("Picked up System Repair!")
		1: # Small Memory
			player.add_consumable("bandwidth", 1)
			print("Picked up 1 Memory Unit")
		2: # Medium Memory
			player.add_consumable("bandwidth", 5)
			print("Picked up 5 Memory Units")
		3: # Large Memory
			player.add_consumable("bandwidth", 10)
			print("Picked up 10 Memory Units")
