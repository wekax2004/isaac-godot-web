extends Area2D

# 24 unique items with diverse effects
const ITEM_COUNT = 30
@export var item_id: int = -1
@export var price: int = 0
@export var price_hp: int = 0

var player_nearby: bool = false
var tooltip_bob: float = 0.0

# Item database: [name, description]
const ITEM_DB = [
	["Damage Core", "+1.5 Damage"],
	["Speed Boots", "+40 Speed"],
	["Scope", "+150 Range"],
	["Scattergun", "3-Way Spread\n0.7x Damage"],
	["Acid Rounds", "Poison DoT\nEnemies take damage over time"],
	["Neural Tracker", "Homing Bullets\nProjectiles seek enemies"],
	["Heavy Caliber", "HUGE Bullets\n+50% Damage, Slower fire"],
	["Sacred Core", "Homing + 2.3x Damage\nVery slow, +1 HP"],
	["Hyper-Accelerator", "Machine Gun!\n0.2x Damage, Tiny bullets"],
	["Power Node", "1.5x Damage Multiplier"],
	["Overclock", "Fast Fire + Speed\nHalf Range"],
	["Mutant Serum", "+1 Damage\n+30 Speed"],
	["Omni-Cell", "ALL Stats Up!\nDMG, SPD, Range, HP, Size"],
	["Phase Rounds", "Piercing + Big Bullets\n-30% Range"],
	["Energy Blade", "3x Damage!\n-75% Range, Slow fire"],
	["Explosive Munitions", "Exploding Bullets!\nAoE splash damage"],
	["Adrenaline Injector", "+1 Damage\n+100 Range"],
	["Frenzy Cell", "Fast Fire + Speed\n-20% Damage"],
	["Void Catalyst", "+1 Damage\nPiercing Bullets"],
	["Laser Module", "Piercing + Range\nFaster fire, Green laser"],
	["Defense Matrix", "Orbital Familiar\nBlocks shots, deals contact damage"],
	["Spectral Drone", "Follower Familiar\nShoots spectral bullets"],
	["Energy Shield", "ACTIVE (3 rooms)\nGrants temporary invincibility"],
	["Drone Swarm", "ACTIVE (2 rooms)\nSpawns 3 friendly attack drones"],
	["Scrap Metal", "It's just scrap.\nDoes absolutely nothing."],
	["Particle Cannon", "Energy Beam!\nCharge to fire a devastating laser"],
	["Auto-Feeder", "Fire rate UP\nDamage DOWN"],
	["Macro Lens", "Mega Bullets\nDamage UP, Fire rate DOWN"],
	["Splinter Rounds", "Split!\nBullets split on impact"],
	["Ricochet Modules", "Bouncing Bullets\nBullets bounce off walls"],
]

func _ready() -> void:
	if item_id == -1:
		item_id = randi() % ITEM_COUNT
	queue_redraw()

func _process(_delta: float) -> void:
	# Check if player is nearby for tooltip
	var players = get_tree().get_nodes_in_group("player")
	var was_nearby = player_nearby
	player_nearby = false
	
	if players.size() > 0:
		var dist = global_position.distance_to(players[0].global_position)
		if dist < 80.0:
			player_nearby = true
	
	if player_nearby:
		tooltip_bob += _delta * 3.0
	
	if player_nearby != was_nearby:
		queue_redraw()

func _draw() -> void:
	# Draw Sci-Fi/Mutation item icon
	var center = Vector2(0, 0)
	match item_id:
		0: # Damage Core (Red glowing core)
			draw_circle(center, 8, Color(0.2, 0.2, 0.2))
			draw_circle(center, 5, Color(0.9, 0.1, 0.1))
			draw_circle(center, 2, Color(1.0, 0.5, 0.5))
		1: # Speed Boots (Thruster boots)
			draw_rect(Rect2(-5, -5, 4, 10), Color(0.3, 0.3, 0.4))
			draw_rect(Rect2(1, -5, 4, 10), Color(0.3, 0.3, 0.4))
			draw_rect(Rect2(-4, 5, 2, 4), Color(0.2, 0.8, 1.0)) # Thruster flame
			draw_rect(Rect2(2, 5, 2, 4), Color(0.2, 0.8, 1.0))
		2: # Scope (Cybernetic Eye)
			draw_circle(center, 7, Color(0.4, 0.4, 0.4))
			draw_circle(Vector2(2, -2), 3, Color.CYAN)
			draw_line(Vector2(-7, 0), Vector2(-12, 0), Color.CYAN, 2)
		3: # Scattergun (Multi-barrel weapon)
			draw_rect(Rect2(-6, -4, 12, 8), Color(0.2, 0.2, 0.2))
			for i in range(3):
				draw_rect(Rect2(6, -3 + (i*3), 4, 2), Color(0.5, 0.5, 0.5))
		4: # Acid Rounds (Green glowing canister)
			draw_rect(Rect2(-5, -8, 10, 16), Color(0.1, 0.8, 0.2))
			draw_rect(Rect2(-5, -6, 10, 2), Color(0.2, 0.2, 0.2))
			draw_rect(Rect2(-5, 4, 10, 2), Color(0.2, 0.2, 0.2))
		5: # Neural Tracker (Purple headband/chip)
			draw_rect(Rect2(-8, -2, 16, 4), Color(0.6, 0.2, 0.8))
			draw_circle(Vector2(0,0), 3, Color(0.9, 0.5, 1.0))
		6: # Heavy Caliber (Massive Bullet)
			draw_rect(Rect2(-4, -10, 8, 14), Color(0.8, 0.7, 0.2))
			draw_circle(Vector2(0, -10), 4, Color(0.8, 0.7, 0.2)) # Bullet tip
			draw_rect(Rect2(-5, 4, 10, 4), Color(0.4, 0.4, 0.4)) # Casing base
		7: # Sacred Core (White/Gold glowing core)
			draw_circle(center, 9, Color(1.0, 0.9, 0.2))
			draw_circle(center, 6, Color.WHITE)
			var pts = PackedVector2Array([Vector2(-4,-4), Vector2(4,-4), Vector2(0, 6)])
			draw_colored_polygon(pts, Color(0.9, 0.1, 0.2))
		8: # Hyper-Accelerator (Spinning gear/motor)
			draw_circle(center, 6, Color(0.6, 0.6, 0.7))
			for i in range(6):
				var angle = i * TAU / 6
				var p1 = center + Vector2(cos(angle), sin(angle)) * 6
				var p2 = center + Vector2(cos(angle), sin(angle)) * 10
				draw_line(p1, p2, Color(0.8, 0.8, 0.9), 3)
		9: # Power Node (Lightning battery)
			draw_rect(Rect2(-6, -8, 12, 16), Color(0.2, 0.3, 0.8))
			draw_rect(Rect2(-3, -11, 6, 3), Color(0.7, 0.7, 0.7)) # Terminal
			draw_polyline(PackedVector2Array([Vector2(-2,-4), Vector2(2,0), Vector2(-2,2), Vector2(2,6)]), Color.YELLOW, 2)
		10: # Overclock (Yellow Chip)
			draw_rect(Rect2(-7, -7, 14, 14), Color(0.9, 0.9, 0.1))
			draw_rect(Rect2(-4, -4, 8, 8), Color(0.2, 0.2, 0.2))
			draw_line(Vector2(0, -7), Vector2(0, -10), Color(0.9, 0.9, 0.1), 2)
			draw_line(Vector2(0, 7), Vector2(0, 10), Color(0.9, 0.9, 0.1), 2)
		11: # Mutant Serum (Syringe)
			draw_rect(Rect2(-3, -8, 6, 12), Color(0.8, 0.8, 0.8)) # Barrel
			draw_rect(Rect2(-2, -7, 4, 8), Color(0.2, 0.9, 0.3)) # Liquid
			draw_line(Vector2(0, 4), Vector2(0, 10), Color(0.6, 0.6, 0.6), 2) # Needle
			draw_rect(Rect2(-5, -10, 10, 2), Color(0.4, 0.4, 0.4)) # Plunger top
		12: # Omni-Cell (Glowing rainbow cube)
			var c1 = Color(1.0, 0.2, 0.2)
			var c2 = Color(0.2, 1.0, 0.2)
			var c3 = Color(0.2, 0.2, 1.0)
			draw_rect(Rect2(-8, -8, 8, 8), c1)
			draw_rect(Rect2(0, -8, 8, 8), c2)
			draw_rect(Rect2(-8, 0, 8, 8), c3)
			draw_rect(Rect2(0, 0, 8, 8), Color(0.9, 0.9, 0.2))
			draw_circle(center, 4, Color.WHITE)
		13: # Phase Rounds (Purple aura ring)
			draw_arc(center, 8, 0, TAU, 16, Color(0.6, 0.2, 0.8), 3)
			draw_circle(center, 3, Color(0.9, 0.6, 1.0))
		14: # Energy Blade (Lightsaber)
			draw_rect(Rect2(-2, 2, 4, 8), Color(0.4, 0.4, 0.4)) # Hilt
			draw_rect(Rect2(-1, -12, 2, 14), Color(1.0, 1.0, 1.0)) # Core
			draw_rect(Rect2(-3, -12, 6, 14), Color(0.2, 0.6, 1.0, 0.5)) # Glow
		15: # Explosive Munitions (Bomb/Missile shell)
			draw_circle(center, 7, Color(0.2, 0.2, 0.2))
			draw_rect(Rect2(-2, -9, 4, 3), Color(0.8, 0.8, 0.8)) # fuse/cap
			draw_circle(Vector2(-3, -3), 2, Color(1.0, 0.3, 0.0)) # Warning light
		16: # Adrenaline Injector (Red Syringe)
			draw_rect(Rect2(-3, -8, 6, 12), Color(0.8, 0.8, 0.8)) # Barrel
			draw_rect(Rect2(-2, -7, 4, 8), Color(0.9, 0.1, 0.1)) # Red Liquid
			draw_line(Vector2(0, 4), Vector2(0, 10), Color(0.6, 0.6, 0.6), 2) # Needle
		17: # Frenzy Cell (Erratic zigzag chip)
			draw_rect(Rect2(-6, -6, 12, 12), Color(0.8, 0.4, 0.1))
			draw_polyline(PackedVector2Array([Vector2(-4,-4), Vector2(4,-2), Vector2(-4,2), Vector2(4,4)]), Color.CYAN, 2)
		18: # Void Catalyst (Black hole)
			draw_circle(center, 9, Color(0.4, 0.1, 0.5))
			draw_circle(center, 7, Color(0.1, 0.0, 0.1))
			draw_circle(center, 3, Color.BLACK)
		19: # Laser Module (Green pointer)
			draw_rect(Rect2(-3, -8, 6, 16), Color(0.2, 0.2, 0.2)) # Casing
			draw_rect(Rect2(-2, -12, 4, 4), Color(0.2, 1.0, 0.3)) # Lens
			draw_line(Vector2(0, -12), Vector2(0, -20), Color(0.2, 1.0, 0.3, 0.5), 2) # Beam
		20: # Defense Matrix (Shield generator)
			draw_arc(center, 10, -PI/2 - 0.5, -PI/2 + 0.5, 8, Color(0.2, 0.6, 1.0), 3)
			draw_circle(center, 5, Color(0.4, 0.4, 0.5))
		21: # Spectral Drone (Floating scanner)
			draw_circle(Vector2(0, -4), 6, Color(0.8, 0.9, 1.0))
			draw_rect(Rect2(-4, 0, 8, 4), Color(0.3, 0.3, 0.4))
			draw_circle(Vector2(0, -4), 2, Color.BLUE)
		22: # Energy Shield (Hexagon shield active item)
			var pts = PackedVector2Array()
			for i in range(6):
				var angle = i * TAU / 6
				pts.append(center + Vector2(cos(angle), sin(angle)) * 10)
			draw_colored_polygon(pts, Color(0.2, 0.5, 1.0, 0.4))
			for i in range(6):
				draw_line(pts[i], pts[(i+1)%6], Color(0.4, 0.8, 1.0), 2)
		23: # Drone Swarm (Drone deployer box)
			draw_rect(Rect2(-8, -6, 16, 12), Color(0.3, 0.3, 0.35))
			draw_circle(Vector2(-4, 0), 2, Color(0.2, 0.9, 0.1))
			draw_circle(Vector2(4, 0), 2, Color(0.2, 0.9, 0.1))
			draw_line(Vector2(-8, -6), Vector2(8, -6), Color.WHITE, 2)
		24: # Scrap Metal (Pile of junk)
			draw_rect(Rect2(-6, 2, 8, 4), Color(0.4, 0.4, 0.4))
			draw_rect(Rect2(0, 0, 6, 6), Color(0.5, 0.5, 0.5))
			draw_line(Vector2(-4, -4), Vector2(2, 2), Color(0.3, 0.3, 0.3), 3)
		26: # Auto-Feeder (Bullet belt)
			for i in range(4):
				draw_rect(Rect2(-6 + (i*4), -4, 2, 8), Color(0.8, 0.7, 0.2))
				draw_circle(Vector2(-5 + (i*4), -4), 1, Color(0.8, 0.7, 0.2))
		27: # Macro Lens (Magnifying glass / large lens)
			draw_circle(Vector2(-2, -2), 8, Color(0.6, 0.6, 0.7))
			draw_circle(Vector2(-2, -2), 6, Color(0.8, 0.9, 1.0, 0.5))
			draw_line(Vector2(3, 3), Vector2(8, 8), Color(0.4, 0.4, 0.4), 4)
		28: # Splinter Rounds (Shattered bullet)
			draw_rect(Rect2(-4, -6, 8, 10), Color(0.8, 0.7, 0.2))
			draw_line(Vector2(0, -6), Vector2(-2, 0), Color.BLACK, 1)
			draw_line(Vector2(-2, 0), Vector2(2, 4), Color.BLACK, 1)
		29: # Ricochet Modules (Spring/Bouncer)
			draw_rect(Rect2(-4, -8, 8, 2), Color(0.6, 0.6, 0.6))
			draw_rect(Rect2(-5, -4, 10, 2), Color(0.6, 0.6, 0.6))
			draw_rect(Rect2(-4, 0, 8, 2), Color(0.6, 0.6, 0.6))
			draw_circle(Vector2(0, -10), 3, Color(1.0, 0.5, 0.1))
		
	# Price tag
	if price > 0:
		draw_string(ThemeDB.fallback_font, Vector2(-10, 25), str(price) + "c", 0, -1, 14, Color(1.0, 0.8, 0.0))
	elif price_hp > 0:
		draw_string(ThemeDB.fallback_font, Vector2(-18, 25), str(price_hp) + " Max HP", 0, -1, 11, Color(1.0, 0.2, 0.2))

	# --- TOOLTIP when player is nearby ---
	if player_nearby and item_id >= 0 and item_id < ITEM_DB.size():
		var info = ITEM_DB[item_id]
		var item_name = info[0]
		var item_desc = info[1]
		var bob_y = sin(tooltip_bob) * 2.0
		
		# Background box
		var lines = item_desc.split("\n")
		var box_w = 220
		var box_height = 24 + (lines.size() * 16)
		var box_y = -30 - box_height + bob_y
		var box_x = -box_w / 2
		draw_rect(Rect2(box_x, box_y, box_w, box_height), Color(0.0, 0.0, 0.0, 0.85))
		draw_rect(Rect2(box_x, box_y, box_w, box_height), Color(0.8, 0.7, 0.3, 0.6), false, 1.5)
		
		# Item name (gold)
		draw_string(ThemeDB.fallback_font, Vector2(box_x + 8, box_y + 16), item_name, 0, box_w - 16, 14, Color(1.0, 0.9, 0.3))
		
		# Description lines (white)
		for i in range(lines.size()):
			draw_string(ThemeDB.fallback_font, Vector2(box_x + 8, box_y + 32 + (i * 16)), lines[i], 0, box_w - 16, 12, Color(0.8, 0.8, 0.8))

var has_been_picked_up = false

func _on_body_entered(body: Node2D) -> void:
	if has_been_picked_up: return
	
	if body.is_in_group("player"):
		if price > 0:
			var p_coins = body.get("coins")
			if p_coins == null or p_coins < price:
				return
			body.add_consumable("coin", -price)
			
		if price_hp > 0:
			var stats = body.get("stats")
			if stats == null or stats.max_health <= price_hp: # Must survive the deal!
				return
			
			stats.max_health -= price_hp
			body.current_health = mini(body.current_health, stats.max_health)
			body.health_changed.emit(body.current_health, stats.max_health)
			SFX.play_hit()
			
			# Screen shake for the painful transaction
			var level_gen = get_tree().get_first_node_in_group("level_generator")
			if level_gen and level_gen.has_method("shake_camera"):
				level_gen.shake_camera(15.0, 0.15)
			
		has_been_picked_up = true
		_apply_item(body)
		call_deferred("queue_free")

func _apply_item(player: Node2D) -> void:
	var stats = player.get("stats")
	if not stats: return
	
	var item_data = ItemData.new()
	
	match item_id:
		0:
			item_data.item_name = "Damage Core"
			item_data.flat_damage = 1.5
		1:
			item_data.item_name = "Speed Boots"
			item_data.flat_speed = 40.0
		2:
			item_data.item_name = "Scope"
			item_data.flat_range = 150.0
		3:
			item_data.item_name = "Scattergun"
			item_data.is_shotgun = true
			item_data.mult_damage = 0.7
			item_data.tear_color_override = Color(1.0, 0.5, 0.1)
		4:
			item_data.item_name = "Acid Rounds"
			item_data.is_poison = true
			item_data.tear_color_override = Color(0.2, 0.9, 0.1)
		5:
			item_data.item_name = "Neural Tracker"
			item_data.is_homing = true
			item_data.tear_color_override = Color(0.6, 0.2, 0.8)
		6:
			item_data.item_name = "Heavy Caliber"
			item_data.tear_size_mult = 1.8
			item_data.mult_damage = 1.5
			item_data.mult_fire_rate = 1.3
		7:
			item_data.item_name = "Sacred Core"
			item_data.is_homing = true
			item_data.mult_damage = 2.3
			item_data.mult_fire_rate = 1.5
			item_data.flat_health = 1
			item_data.tear_color_override = Color(1.0, 0.9, 0.9)
		8:
			item_data.item_name = "Hyper-Accelerator"
			item_data.mult_fire_rate = 0.15
			item_data.mult_damage = 0.2
			item_data.tear_size_mult = 0.5
		9:
			item_data.item_name = "Power Node"
			item_data.mult_damage = 1.5
		10:
			item_data.item_name = "Overclock"
			item_data.mult_fire_rate = 0.6
			item_data.mult_range = 0.5
			item_data.flat_speed = 30.0
			item_data.tear_color_override = Color(0.9, 0.9, 0.2)
		11:
			item_data.item_name = "Mutant Serum"
			item_data.flat_damage = 1.0
			item_data.flat_speed = 30.0
		12:
			item_data.item_name = "Omni-Cell"
			item_data.flat_damage = 1.0
			item_data.flat_speed = 20.0
			item_data.flat_range = 50.0
			item_data.mult_fire_rate = 0.9
			item_data.flat_health = 1
			item_data.tear_size_mult = 1.2
		13:
			item_data.item_name = "Phase Rounds"
			item_data.is_piercing = true
			item_data.tear_size_mult = 1.4
			item_data.mult_range = 0.7
			item_data.tear_color_override = Color(0.5, 0.4, 0.6)
		14:
			item_data.item_name = "Energy Blade"
			item_data.is_knife = true
			item_data.mult_damage = 3.0
			item_data.mult_range = 0.25
			item_data.mult_fire_rate = 1.5
			item_data.tear_size_mult = 1.5
		15:
			item_data.item_name = "Explosive Munitions"
			item_data.is_explosive = true
			item_data.flat_damage = 0.5
			item_data.tear_color_override = Color(1.0, 0.3, 0.0)
		16:
			item_data.item_name = "Adrenaline Injector"
			item_data.flat_damage = 1.0
			item_data.flat_range = 100.0
			item_data.tear_color_override = Color(0.8, 0.1, 0.1)
		17:
			item_data.item_name = "Frenzy Cell"
			item_data.mult_fire_rate = 0.6
			item_data.mult_damage = 0.8
			item_data.flat_speed = 25.0
		18:
			item_data.item_name = "Void Catalyst"
			item_data.flat_damage = 1.0
			item_data.is_piercing = true
			item_data.tear_color_override = Color(0.3, 0.05, 0.05)
		19:
			item_data.item_name = "Laser Module"
			item_data.is_laser = true
			item_data.is_piercing = true
			item_data.flat_range = 200.0
			item_data.mult_fire_rate = 0.8
			item_data.tear_color_override = Color(0.2, 1.0, 0.3)
		20:
			item_data.item_name = "Defense Matrix"
			item_data.is_familiar = true
			item_data.familiar_name = "Defense Matrix"
		21:
			item_data.item_name = "Spectral Drone"
			item_data.is_familiar = true
			item_data.familiar_name = "Spectral Drone"
		22:
			item_data.item_name = "Energy Shield"
			item_data.is_active_item = true
			item_data.max_charges = 3
		23:
			item_data.item_name = "Drone Swarm"
			item_data.is_active_item = true
			item_data.max_charges = 2
		24: # Joke item - does nothing!
			item_data.item_name = "Scrap Metal"
			item_data.description = "It's just scrap."
		25:
			item_data.item_name = "Particle Cannon"
			item_data.is_brimstone = true
			item_data.mult_damage = 2.0
			item_data.mult_fire_rate = 2.5 # Slower "charge" cycle
			item_data.tear_color_override = Color(0.8, 0.1, 0.1)
		26:
			item_data.item_name = "Auto-Feeder"
			item_data.mult_fire_rate = 0.15 # EXTREMELY FAST
			item_data.mult_damage = 0.2
			item_data.tear_size_mult = 0.5
		27:
			item_data.item_name = "Macro Lens"
			item_data.mult_fire_rate = 2.5
			item_data.mult_damage = 4.0
			item_data.tear_size_mult = 2.5
		28:
			item_data.item_name = "Splinter Rounds"
			item_data.is_parasite = true
			item_data.description = "Bullets split on impact"
		29:
			item_data.item_name = "Ricochet Modules"
			item_data.is_rubber_cement = true
			item_data.description = "Bouncing bullets"
		
	print("Picked up ", item_data.item_name, "!")
	stats.add_item(item_data)
			
	# Heal player if item grants health
	if item_data.flat_health > 0:
		player.current_health = mini(player.current_health + item_data.flat_health, stats.max_health)
		player.health_changed.emit(player.current_health, stats.max_health)
			
	# Update HUD stats display
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("set_player_stats"):
		hud.set_player_stats(stats)
