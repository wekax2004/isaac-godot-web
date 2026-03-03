extends CharacterBody2D
class_name Boss

signal boss_health_changed(current: int, maximum: int)
signal boss_defeated

enum State { PHASE_1_SHOOT, PHASE_2_CHARGE }

@export var max_health: int = 100
@export var bullet_scene: PackedScene # The boss needs its own hostile tear scene
@export var charge_speed: float = 400.0

var current_health: int
var current_state: State = State.PHASE_1_SHOOT
var player_ref: Node2D

@onready var sprite = $Sprite2D
@onready var shoot_timer = Timer.new()
@onready var charge_timer = Timer.new()

var is_charging: bool = false
var charge_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	current_health = max_health
	player_ref = get_tree().get_first_node_in_group("player")
	
	# Setup Phase 1 Timer
	add_child(shoot_timer)
	shoot_timer.wait_time = 2.0
	shoot_timer.timeout.connect(_on_shoot_timer)
	shoot_timer.start()
	
	# Setup Phase 2 Charging Timer
	add_child(charge_timer)
	charge_timer.wait_time = 3.0
	charge_timer.timeout.connect(_start_charge)

func _physics_process(delta: float) -> void:
	if current_state == State.PHASE_1_SHOOT:
		# Hover slowly toward player or center of room
		if player_ref:
			velocity = (player_ref.global_position - global_position).normalized() * 50.0
		move_and_slide()
		
	elif current_state == State.PHASE_2_CHARGE:
		if is_charging:
			velocity = charge_direction * charge_speed
			# Rapid deceleration
			charge_direction = charge_direction.lerp(Vector2.ZERO, delta * 3.0)
			if charge_direction.length() < 0.1:
				is_charging = false
		else:
			# Slowly track player while waiting for next charge
			if player_ref:
				velocity = (player_ref.global_position - global_position).normalized() * 20.0
		
		move_and_slide()
		
		# Throb visual effect in Phase 2
		sprite.scale = Vector2(1.0, 1.0) * (1.0 + sin(Time.get_ticks_msec() / 100.0) * 0.1)

func _on_shoot_timer() -> void:
	if current_state != State.PHASE_1_SHOOT or not bullet_scene: return
	
	# Fire an 8-way ring of bullets
	var num_bullets = 8
	for i in range(num_bullets):
		var angle = (i * PI * 2) / num_bullets
		var dir = Vector2(cos(angle), sin(angle))
		
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.direction = dir
		# Make sure these bullets are marked hostile or use an EnemyTear.tscn
		get_tree().root.add_child(bullet)

func _start_charge() -> void:
	if current_state != State.PHASE_2_CHARGE or not player_ref: return
	
	# Lock onto player's current position and lunge
	charge_direction = (player_ref.global_position - global_position).normalized()
	is_charging = true

func take_damage(amount: int) -> void:
	current_health -= amount
	boss_health_changed.emit(current_health, max_health)
	
	# Visual hit flash
	sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	if current_state == State.PHASE_2_CHARGE:
		sprite.modulate = Color(1, 0.5, 0) # Stay angry orange
	else:
		sprite.modulate = Color(1, 1, 1)
	
	# Phase Transition Check
	if current_health <= max_health / 2 and current_state == State.PHASE_1_SHOOT:
		transition_to_phase_2()
		
	if current_health <= 0:
		die()

func transition_to_phase_2() -> void:
	current_state = State.PHASE_2_CHARGE
	sprite.modulate = Color(1, 0.5, 0) # Turn angry orange
	shoot_timer.stop()
	charge_timer.start()
	print("BOSS PHASE 2 ENRAGED!")

func die() -> void:
	boss_defeated.emit()
	queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_tear"):
		# ECS stat injection would go here
		take_damage(int(area.damage))
		
		if not area.is_piercing:
			area.queue_free()
