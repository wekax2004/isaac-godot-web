extends CanvasLayer

var current_health: float = 3.0
var max_health: float = 3.0
var bandwidth: int = 0
var player_stats: Node = null

var level_generator: Node = null
var current_room_grid_pos: Vector2 = Vector2.ZERO

var current_boss: Node2D = null
var boss_health: float = 1.0
var boss_max_health: float = 1.0

# Item Popup System
var popup_messages: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("hud")
	# Will redraw UI whenever needed
	$"HUD_UI".queue_redraw()

func _process(delta: float) -> void:
	# Always redraw for hover tooltips and popups
	if popup_messages.size() > 0 or (player_stats and player_stats.inventory.size() > 0):
		if popup_messages.size() > 0:
			for i in range(popup_messages.size() - 1, -1, -1):
				var popup = popup_messages[i]
				popup.lifetime -= delta
				popup.y_offset -= delta * 30.0
				if popup.lifetime <= 0:
					popup_messages.remove_at(i)
		$"HUD_UI".queue_redraw()

func _on_player_health_changed(hp: float, max_hp: float) -> void:
	current_health = hp
	max_health = max_hp
	$"HUD_UI".queue_redraw()

func _on_bandwidth_changed(amount: int) -> void:
	bandwidth = amount
	$"HUD_UI".queue_redraw()

func set_player_stats(stats: Node) -> void:
	# Check if inventory grew, indicating a new item
	if player_stats != null and stats != null and stats.inventory.size() > player_stats.inventory.size():
		var new_item = stats.inventory[-1]
		var desc = new_item.description if new_item.description != "Provides mysterious buffs." else _get_item_desc(new_item)
		popup_messages.append({
			"text": "+ " + new_item.item_name,
			"desc": desc,
			"lifetime": 3.5,
			"y_offset": 50.0
		})
	
	player_stats = stats
	$"HUD_UI".queue_redraw()

func _get_item_desc(item: ItemData) -> String:
	var parts = []
	if item.flat_damage != 0: parts.append(("+" if item.flat_damage > 0 else "") + str(item.flat_damage) + " Damage")
	if item.flat_speed != 0: parts.append(("+" if item.flat_speed > 0 else "") + str(item.flat_speed) + " Speed")
	if item.flat_range != 0: parts.append(("+" if item.flat_range > 0 else "") + str(item.flat_range) + " Range")
	if item.flat_health != 0: parts.append("+" + str(item.flat_health) + " HP")
	if item.mult_damage != 1.0: parts.append(str(item.mult_damage) + "x Damage")
	if item.mult_fire_rate != 1.0:
		if item.mult_fire_rate < 1.0:
			parts.append("Faster Fire Rate")
		else:
			parts.append("Slower Fire Rate")
	if item.mult_range != 1.0: parts.append(str(item.mult_range) + "x Range")
	if item.is_homing: parts.append("Homing Bullets")
	if item.is_piercing: parts.append("Piercing Bullets")
	if item.is_shotgun: parts.append("3-Way Spread")
	if item.is_poison: parts.append("Poison DoT")
	if item.is_explosive: parts.append("Explosive AoE")
	if item.tear_size_mult != 1.0: parts.append(str(item.tear_size_mult) + "x Bullet Size")
	if parts.size() == 0: return "???"
	return "\n".join(parts)

func update_minimap(level_gen: Node, room_pos: Vector2) -> void:
	level_generator = level_gen
	current_room_grid_pos = room_pos
	$"HUD_UI".queue_redraw()

func register_boss(boss: Node2D) -> void:
	current_boss = boss
	boss_health = boss.health
	boss_max_health = boss.max_health
	
	if not boss.health_changed.is_connected(_on_boss_health_changed):
		boss.health_changed.connect(_on_boss_health_changed)
	if not boss.boss_defeated.is_connected(_on_boss_defeated):
		boss.boss_defeated.connect(_on_boss_defeated)
		
	GlitchManager.glitch_triggered.connect(_on_glitch_triggered)
	$"HUD_UI".queue_redraw()

func _on_glitch_triggered(type: String, duration: float) -> void:
	var desc = "CRITICAL FAILURE"
	match type:
		"OVERCLOCK": desc = "FIRE RATE OVERRIDE ACTIVE"
		"LAG_SPIKE": desc = "LATENCY SPIKE DETECTED"
		"DATA_CORRUPTION": desc = "DAMAGE OUTPUT CORRUPTED (2x)"
		
	popup_messages.append({
		"text": "!!! " + type + " !!!",
		"desc": desc,
		"lifetime": 4.0,
		"y_offset": -100.0,
		"color": Color.RED
	})

func _on_boss_health_changed(hp: float, max_hp: float) -> void:
	boss_health = hp
	boss_max_health = max_hp
	$"HUD_UI".queue_redraw()

func _on_boss_defeated() -> void:
	current_boss = null
	$"HUD_UI".queue_redraw()

func _on_hud_ui_draw() -> void:
	# Use standard Control draw function on the sub-node
	var ui = $"HUD_UI"
	
	# --- Draw Health (Top Left) ---
	var start_x = 20
	var start_y = 20
	var heart_spacing = 30
	var heart_size = 8.0
	
	for i in range(int(max_health)):
		var pos = Vector2(start_x + (i * heart_spacing), start_y)
		var color = Color(0.9, 0.1, 0.2) if i < int(current_health) else Color(0.2, 0.2, 0.2) # Filled/Empty
		
		# Draw simple square hearts
		ui.draw_rect(Rect2(pos.x - heart_size, pos.y - heart_size, heart_size * 2, heart_size * 2), color)
		# Inner highlight
		if i < int(current_health):
			ui.draw_rect(Rect2(pos.x - heart_size + 2, pos.y - heart_size + 2, heart_size * 1.5, heart_size * 1.5), Color(1.0, 0.4, 0.5))

	# --- Draw Bandwidth (Left Side below health) ---
	var cons_y = start_y + 35
	
	# Bandwidth Icon (Cyan glowing data fragment)
	var bw_color = Color(0.2, 0.8, 1.0)
	var pts = PackedVector2Array([Vector2(start_x, cons_y - 6), Vector2(start_x + 6, cons_y), Vector2(start_x, cons_y + 6), Vector2(start_x - 6, cons_y)])
	ui.draw_colored_polygon(pts, bw_color)
	ui.draw_string(ThemeDB.fallback_font, Vector2(start_x + 15, cons_y + 5), "MEM: " + str(bandwidth).pad_zeros(3), 0, -1, 16, Color.WHITE)

	# --- Draw Active Item (Top Left, below Bandwidth) ---
	var active_y = cons_y + 30
	ui.draw_rect(Rect2(start_x - 10, active_y - 12, 50, 50), Color(0.1, 0.1, 0.1, 0.8))
	ui.draw_rect(Rect2(start_x - 10, active_y - 12, 50, 50), Color(0.3, 0.3, 0.3), false, 2)
	
	if player_stats and player_stats.active_item:
		# Item Name (tiny)
		ui.draw_string(ThemeDB.fallback_font, Vector2(start_x - 5, active_y + 3), player_stats.active_item.item_name, 0, 40, 10, Color.WHITE)
		
		# Charge Bar
		var max_c = player_stats.active_item.max_charges
		var cur_c = player_stats.active_item_charge
		var bar_w = 40.0
		var bar_h = 6.0
		var bar_x = start_x - 5
		var bar_y = active_y + 25
		
		ui.draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2)) # Background
		if max_c > 0:
			var fill = float(cur_c) / float(max_c)
			var cur_color = Color.GREEN if cur_c >= max_c else Color.YELLOW
			ui.draw_rect(Rect2(bar_x, bar_y, bar_w * fill, bar_h), cur_color)
			
		# Text charge
		ui.draw_string(ThemeDB.fallback_font, Vector2(start_x + 6, active_y + 22), str(cur_c) + "/" + str(max_c), 0, -1, 10, Color.WHITE)
	else:
		# Empty slot text
		ui.draw_string(ThemeDB.fallback_font, Vector2(start_x + 3, active_y + 15), "SPACE", 0, -1, 10, Color(0.4, 0.4, 0.4))

	# --- Draw Stats (Left Side below Active Item) ---
	if player_stats:
		var stat_y = active_y + 60
		var line_spacing = 20
		
		# Simple custom font / default font text drawing
		ui.draw_string(ThemeDB.fallback_font, Vector2(start_x, stat_y), "Damage: " + str(snappedf(player_stats.damage, 0.1)), 0, -1, 16, Color.WHITE)
		ui.draw_string(ThemeDB.fallback_font, Vector2(start_x, stat_y + line_spacing), "Speed: " + str(snappedf(player_stats.speed, 0.1)), 0, -1, 16, Color.WHITE)
		ui.draw_string(ThemeDB.fallback_font, Vector2(start_x, stat_y + line_spacing * 2), "Fire Rate: " + str(snappedf(player_stats.fire_rate, 0.01)), 0, -1, 16, Color.WHITE)
		ui.draw_string(ThemeDB.fallback_font, Vector2(start_x, stat_y + line_spacing * 3), "Range: " + str(snappedf(player_stats.range, 0.1)), 0, -1, 16, Color.WHITE)

	# --- Draw Minimap (Top Right) ---
	if level_generator and level_generator.get("logical_map"):
		var map = level_generator.logical_map
		var screen_width = get_viewport().get_visible_rect().size.x
		var mm_center = Vector2(screen_width - 150, 100) # Anchored Top-Right
		var mm_scale = 15.0
		
		# Draw background box for minimap
		ui.draw_rect(Rect2(mm_center.x - 100, mm_center.y - 70, 200, 140), Color(0.1, 0.1, 0.1, 0.8))
		
		# Floor label
		var floor_num = 1
		if player_stats and player_stats.get("current_floor"):
			floor_num = player_stats.current_floor
		var floor_names = ["Localhost", "Staging", "Production", "The Root Directory"]
		var floor_name = floor_names[mini(floor_num - 1, floor_names.size() - 1)]
		ui.draw_string(ThemeDB.fallback_font, Vector2(mm_center.x - 90, mm_center.y - 55), "ENV: " + floor_name, 0, -1, 14, Color(0.2, 0.8, 1.0))
		
		# Version Number (Bottom Right)
		var screen_height = get_viewport().get_visible_rect().size.y
		ui.draw_string(ThemeDB.fallback_font, Vector2(screen_width - 80, screen_height - 10), "v1.3.0", 0, -1, 12, Color(1, 1, 1, 0.5))
		
		# Collect explored positions for adjacency check
		var explored_set = {}
		for pos in map.keys():
			if level_generator.room_grid.has(pos):
				var room = level_generator.room_grid[pos]
				if room.is_cleared or room.enemies_spawned or pos == Vector2.ZERO:
					explored_set[pos] = true
		
		# Draw unexplored adjacent rooms as faint outlines
		var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		var drawn_unexplored = {}
		for exp_pos in explored_set.keys():
			for dir in directions:
				var adj = exp_pos + dir
				if map.has(adj) and not explored_set.has(adj) and not drawn_unexplored.has(adj):
					drawn_unexplored[adj] = true
					
					var relative_adj = adj - current_room_grid_pos
					if abs(relative_adj.x) > 5.5 or abs(relative_adj.y) > 3.5:
						continue
						
					var map_pos = mm_center + (relative_adj * mm_scale)
					ui.draw_rect(Rect2(map_pos.x - mm_scale/2.5, map_pos.y - mm_scale/2.5, mm_scale * 0.8, mm_scale * 0.8), Color(0.25, 0.25, 0.25, 0.5))
		
		# Draw explored rooms
		for pos in map.keys():
			if not explored_set.has(pos) and not drawn_unexplored.has(pos):
				continue # Skip completely unknown rooms
				
			var relative_pos = pos - current_room_grid_pos
			if abs(relative_pos.x) > 5.5 or abs(relative_pos.y) > 3.5:
				continue
				
			var map_pos = mm_center + (relative_pos * mm_scale)
			var room_color = Color(0.4, 0.4, 0.4) # Default explored
			
			if not explored_set.has(pos):
				continue # Already drawn as outline above
			
			if pos == current_room_grid_pos:
				# Pulsing white indicator
				var pulse = (sin(Time.get_ticks_msec() / 200.0) + 1.0) / 2.0
				room_color = Color(0.7 + pulse * 0.3, 0.7 + pulse * 0.3, 0.7 + pulse * 0.3)
			elif level_generator.room_grid.has(pos) and level_generator.room_grid[pos].is_boss_room:
				room_color = Color(0.8, 0.1, 0.1) # Boss Room (Red)
			elif level_generator.room_grid.has(pos) and level_generator.room_grid[pos].get("is_item_room") == true:
				room_color = Color(1.0, 0.8, 0.2) # Item Room (Gold)
			elif level_generator.room_grid.has(pos) and level_generator.room_grid[pos].get("is_shop_room") == true:
				room_color = Color(0.2, 0.8, 0.2) # Shop Room (Green)
			elif level_generator.room_grid.has(pos) and level_generator.room_grid[pos].get("is_secret_room") == true:
				room_color = Color(0.9, 0.9, 0.2) # Secret Room (Bright Yellow)
				
			ui.draw_rect(Rect2(map_pos.x - mm_scale/2.5, map_pos.y - mm_scale/2.5, mm_scale * 0.8, mm_scale * 0.8), room_color)

	# --- Draw Items (Under Minimap) ---
	if player_stats and player_stats.inventory.size() > 0:
		var screen_width = get_viewport().get_visible_rect().size.x
		var item_start_y = 260 # Below minimap
		var line_spacing = 20
		
		# Draw title
		ui.draw_string(ThemeDB.fallback_font, Vector2(screen_width - 150, item_start_y), "- Inventory -", 0, -1, 16, Color(1.0, 0.8, 0.0))
		
		# Draw each item name
		var mouse_pos = ui.get_local_mouse_position()
		var hovered_item: ItemData = null
		var hover_y: float = 0.0
		
		var index = 1
		for item in player_stats.inventory:
			var iy = item_start_y + (index * line_spacing)
			var item_rect = Rect2(screen_width - 165, iy - 14, 165, line_spacing)
			
			var is_hovered = item_rect.has_point(mouse_pos)
			var text_color = Color(1.0, 0.9, 0.3) if is_hovered else Color.WHITE
			ui.draw_string(ThemeDB.fallback_font, Vector2(screen_width - 160, iy), "• " + item.item_name, 0, -1, 14, text_color)
			
			if is_hovered:
				hovered_item = item
				hover_y = iy
			index += 1
		
		# Draw tooltip for hovered item
		if hovered_item:
			var desc = _get_item_desc(hovered_item)
			var desc_lines = desc.split("\n")
			var box_w = 200.0
			var line_h = 14
			var box_h = 20 + (desc_lines.size() * line_h)
			var tooltip_x = screen_width - 370
			var tooltip_y = hover_y - 10
			
			# Background
			ui.draw_rect(Rect2(tooltip_x, tooltip_y, box_w, box_h), Color(0.0, 0.0, 0.0, 0.92))
			ui.draw_rect(Rect2(tooltip_x, tooltip_y, box_w, box_h), Color(0.8, 0.7, 0.2, 0.7), false, 1.5)
			
			# Name
			ui.draw_string(ThemeDB.fallback_font, Vector2(tooltip_x + 6, tooltip_y + 14), hovered_item.item_name, 0, int(box_w - 12), 13, Color(1.0, 0.9, 0.3))
			# Description lines
			for di in range(desc_lines.size()):
				ui.draw_string(ThemeDB.fallback_font, Vector2(tooltip_x + 6, tooltip_y + 28 + (di * line_h)), desc_lines[di], 0, int(box_w - 12), 11, Color(0.8, 0.8, 0.8))
			
	# --- Draw Animated Popups (Over Player) ---
	if popup_messages.size() > 0:
		var screen_width = get_viewport().get_visible_rect().size.x
		var screen_height = get_viewport().get_visible_rect().size.y
		var center_x = screen_width / 2.0
		var base_y = (screen_height / 2.0) - 40.0
		
		for popup in popup_messages:
			var alpha = clamp(popup.lifetime / 1.5, 0.0, 1.0)
			var name_color = Color(1.0, 0.9, 0.2, alpha)
			var desc_color = Color(0.8, 0.8, 0.8, alpha * 0.9)
			var py = base_y + popup.y_offset
			
			# Background box
			var box_w = 300.0
			ui.draw_rect(Rect2(center_x - box_w/2, py - 8, box_w, 40), Color(0.0, 0.0, 0.0, alpha * 0.7))
			
			# Item name (gold, large)
			ui.draw_string(ThemeDB.fallback_font, Vector2(center_x - box_w/2 + 10, py + 10), popup.text, 0, int(box_w - 20), 18, name_color)
			# Description (grey, smaller)
			if popup.has("desc"):
				ui.draw_string(ThemeDB.fallback_font, Vector2(center_x - box_w/2 + 10, py + 28), popup.desc, 0, int(box_w - 20), 13, desc_color)

	# --- Draw Boss Health (Bottom Center) ---
	if current_boss and is_instance_valid(current_boss):
		var screen_width = get_viewport().get_visible_rect().size.x
		var screen_height = get_viewport().get_visible_rect().size.y
		
		var bar_width = 600.0
		var bar_height = 20.0
		var bar_x = (screen_width / 2.0) - (bar_width / 2.0)
		var bar_y = screen_height - 40.0
		
		# Background outline (black)
		ui.draw_rect(Rect2(bar_x - 2, bar_y - 2, bar_width + 4, bar_height + 4), Color.BLACK)
		
		# Empty health (dark red)
		ui.draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color(0.2, 0.0, 0.0))
		
		# Current health (bright red)
		var fill_width = (boss_health / boss_max_health) * bar_width
		ui.draw_rect(Rect2(bar_x, bar_y, fill_width, bar_height), Color(0.8, 0.1, 0.1))
		
		# Boss Name
		var b_name = current_boss.boss_name if "boss_name" in current_boss else "THE BOSS"
		var text_size = ThemeDB.fallback_font.get_string_size(b_name, 0, -1, 16).x
		ui.draw_string(ThemeDB.fallback_font, Vector2((screen_width / 2.0) - (text_size / 2.0), bar_y - 10.0), b_name, 0, -1, 16, Color.RED)

