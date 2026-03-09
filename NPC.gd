extends Area2D
class_name NPC

signal interacted

var is_player_nearby: bool = false
var interaction_label: String = "[E] INTERACT"

func _ready() -> void:
	add_to_group("npcs")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _process(_delta: float) -> void:
	if is_player_nearby and Input.is_action_just_pressed("interact"):
		interact()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = true
		queue_redraw()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = false
		queue_redraw()

func interact() -> void:
	interacted.emit()
	_on_interact()

func _on_interact() -> void:
	# Virtual function
	pass

func _draw() -> void:
	if is_player_nearby:
		draw_string(ThemeDB.fallback_font, Vector2(-40, -40), interaction_label, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
