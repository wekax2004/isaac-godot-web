extends CharacterBody2D

var health: float = 8.0
var shoot_cooldown: float = 2.0
var timer: float = 0.0
var player: Node2D = null

var bullet_scene: PackedScene = preload("res://EnemyBullet.tscn")

func _ready() -> void:
	add_to_group("enemies")
	
	# Find player
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player): return
	
	timer += delta
	if timer >= shoot_cooldown:
		timer = 0
		_shoot()
	
	queue_redraw()

func _shoot() -> void:
	if bullet_scene:
		var b = bullet_scene.instantiate()
		b.global_position = global_position
		b.direction = (player.global_position - global_position).normalized()
		get_tree().root.call_deferred("add_child", b)

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	queue_free()

func _draw() -> void:
	# Draw a stationary stone turret
	draw_rect(Rect2(-12, -12, 24, 24), Color(0.4, 0.4, 0.4))
	draw_rect(Rect2(-12, -12, 24, 24), Color(0.2, 0.2, 0.2), false, 2.0)
	# Red eye
	draw_circle(Vector2.ZERO, 4, Color(0.8, 0.1, 0.1))
