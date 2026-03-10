extends NPC

var trade_completed: bool = false
var trade_cost: int = 1 # Max HP cost

func _ready() -> void:
	super._ready()
	interaction_label = "[E] CORRUPT DATA DEAL (COST: 1 MAX HP)"

func _on_interact() -> void:
	if trade_completed: return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	if player.stats.max_health > 1:
		_execute_trade(player)
	else:
		# HUD.show_popup("INSUFFICIENT ACCESS PRIVILEGES (Low HP)")
		pass

func _execute_trade(player) -> void:
	trade_completed = true
	player.stats.max_health -= trade_cost
	player.stats.recalculate_stats()
	
	# Grant a powerful item bundle or high-tier item
	var item_scene = load("res://Item.tscn")
	var item = item_scene.instantiate()
	item.global_position = global_position + Vector2(0, 50)
	
	# Force a high-tier item (ID 7, 12, 19, 21, 25, 31)
	var high_tier_ids = [7, 12, 19, 21, 25, 31]
	item.item_id = high_tier_ids.pick_random()
	
	get_parent().call_deferred("add_child", item)
	
	# HUD.show_popup("CONNECTION ESTABLISHED: DATA ACQUIRED")
	pass
	
	# Visual effect
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.2, 0.2, 0.2, 0.5)
	
	interaction_label = "CONNECTION TERMINATED"
	queue_redraw()

func _draw() -> void:
	super._draw()
	# Draw a glitchy holographic NPC
	var time = Time.get_ticks_msec() / 1000.0
	var offset = sin(time * 5.0) * 5.0
	
	# Body
	draw_rect(Rect2(-15, -25 + offset, 30, 40), Color(0.2, 0.8, 1.0, 0.4))
	# Eye glitches
	var eye_y = -15 + offset
	draw_circle(Vector2(-6, eye_y), 2, Color(1.0, 0.1, 0.1, 0.8))
	draw_circle(Vector2(6, eye_y), 2, Color(1.0, 0.1, 0.1, 0.8))
	# Scanlines
	for i in range(5):
		var sy = -25 + offset + (i * 8)
		draw_line(Vector2(-15, sy), Vector2(15, sy), Color(1.0, 1.0, 1.0, 0.2), 1.0)
