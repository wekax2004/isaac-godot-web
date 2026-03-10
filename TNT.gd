extends Area2D

var damage: float = 10.0
var health: float = 1.0
var is_exploded: bool = false

func _ready() -> void:
	add_to_group("obstacles")
	add_to_group("explosives")
	
	var sprite = Sprite2D.new()
	sprite.texture = load("res://assets/tnt_sprite.png")
	sprite.scale = Vector2(0.25, 0.25)
	add_child(sprite)

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		explode()

func explode() -> void:
	if is_exploded: return
	is_exploded = true
	
	SFX.play_explosion()
	
	# Visual
	var splash_scene = preload("res://HitSplash.tscn")
	var splash = splash_scene.instantiate()
	splash.global_position = global_position
	splash.scale = Vector2(4, 4)
	splash.color = Color(1.0, 0.4, 0.0)
	get_tree().current_scene.call_deferred("add_child", splash)
	
	# Damage radius
	var blast_radius = 120.0
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			if global_position.distance_to(e.global_position) <= blast_radius:
				e.take_damage(20.0) # High damage
				
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p) and p.has_method("take_damage"):
			if global_position.distance_to(p.global_position) <= blast_radius:
				p.take_damage(1) # Standard 1 heart damage
	
	# Chain reaction for other TNTs
	var other_tnt = get_tree().get_nodes_in_group("explosives")
	for t in other_tnt:
		if t != self and is_instance_valid(t) and t.has_method("explode"):
			if global_position.distance_to(t.global_position) <= blast_radius:
				t.call_deferred("explode")

	queue_free()

