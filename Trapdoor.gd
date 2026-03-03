extends Area2D
class_name Trapdoor

# Export the next level scene (e.g., Level2.tscn)
@export var next_level: PackedScene

@onready var sprite = $Sprite2D

func _ready() -> void:
	# Optional: Play a sound or particles when spawning
	print("Trapdoor appeared!")
	
	# Simple pop-in animation
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1,1), 0.5).set_trans(Tween.TRANS_ELASTIC)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player entered the trapdoor! Descending...")
		call_deferred("transition_to_next_level")

func transition_to_next_level() -> void:
	if next_level:
		# Replace the entire current scene with the next floor!
		get_tree().change_scene_to_packed(next_level)
	else:
		print("YOU WIN! (No next level assigned)")
		# You could send them back to the main menu here
		get_tree().reload_current_scene()
