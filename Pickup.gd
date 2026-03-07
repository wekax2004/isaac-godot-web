extends Area2D

# 0: Health, 1: Coin, 2: Key, 3: Bomb
@export var pickup_type: int = -1
@export var price: int = 0

func _ready() -> void:
	# Randomize if not explicitly set
	if pickup_type == -1:
		pickup_type = randi() % 4
	
	var sprite = Sprite2D.new()
	if pickup_type == 0: # Heart
		sprite.texture = load("res://assets/pickup_heart.png")
		sprite.scale = Vector2(0.4, 0.4)
	elif pickup_type == 1: # Coin
		sprite.texture = load("res://assets/pickup_coin.png")
		sprite.scale = Vector2(0.1, 0.1)
		
	if sprite.texture:
		add_child(sprite)
	
	queue_redraw()

func _draw() -> void:
	# return # Use sprite instead (only return if sprite is valid)
	# For now just let it be, or conditionally return
	if pickup_type < 2: return 
	match pickup_type:
		0: # Health (Heart)
			draw_circle(Vector2(-4,-2), 5, Color.RED)
			draw_circle(Vector2(4,-2), 5, Color.RED)
			var pts = PackedVector2Array([Vector2(-8,-1), Vector2(8,-1), Vector2(0, 8)])
			draw_colored_polygon(pts, Color.RED)
		1: # Coin
			draw_circle(Vector2(0, 0), 6, Color(1.0, 0.8, 0.0))
			draw_circle(Vector2(0, 0), 4, Color(1.0, 0.9, 0.4))
			draw_rect(Rect2(-1, -3, 2, 6), Color(0.8, 0.6, 0.0))
		2: # Key
			draw_circle(Vector2(-4, -2), 4, Color(0.6, 0.6, 0.6))
			draw_circle(Vector2(-4, -2), 2, Color.BLACK)
			draw_rect(Rect2(-2, -3, 10, 2), Color(0.6, 0.6, 0.6))
			draw_rect(Rect2(4, -1, 2, 3), Color(0.6, 0.6, 0.6))
			draw_rect(Rect2(7, -1, 2, 3), Color(0.6, 0.6, 0.6))
		3: # Bomb
			draw_circle(Vector2(0, 2), 6, Color(0.1, 0.1, 0.1))
			draw_line(Vector2(0, -4), Vector2(0, -8), Color(0.8, 0.6, 0.4), 2.0)
			draw_circle(Vector2(0, -9), 2, Color(1.0, 0.4, 0.0))
			
	if price > 0:
		draw_string(ThemeDB.fallback_font, Vector2(-10, 25), str(price) + "c", 0, -1, 14, Color(1.0, 0.8, 0.0))

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if price > 0:
			var p_coins = body.get("coins")
			if p_coins == null or p_coins < price:
				return # Not enough money
			body.add_consumable("coin", -price)
			
		_apply_pickup(body)
		call_deferred("queue_free")

func _apply_pickup(player: Node2D) -> void:
	match pickup_type:
		0: # Health
			var stats = player.get("stats")
			if stats:
				player.current_health = min(player.current_health + 1, stats.max_health)
				player.health_changed.emit(player.current_health, stats.max_health)
			print("Picked up Health!")
		1: # Coin
			if player.has_method("add_consumable"):
				player.add_consumable("coin", 1)
			print("Picked up Coin!")
		2: # Key
			if player.has_method("add_consumable"):
				player.add_consumable("key", 1)
			print("Picked up Key!")
		3: # Bomb
			if player.has_method("add_consumable"):
				player.add_consumable("bomb", 1)
			print("Picked up Bomb!")
