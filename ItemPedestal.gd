extends Area2D
class_name ItemPedestal

# Assign the specific item resource in the Editor Inspector
@export var item_data: ItemData

@onready var sprite = $Sprite2D # The visual icon of the item

func _ready() -> void:
	if item_data and sprite and item_data.icon:
		sprite.texture = item_data.icon
		
		# Optional: Add a simple floating animation programmatically
		var tween = create_tween().set_loops()
		tween.tween_property(sprite, "position:y", -5.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)
		tween.tween_property(sprite, "position:y", 5.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Ensure the player actually has a StatManager node!
		var stat_mngr = body.get_node_or_null("StatManager")
		if stat_mngr and item_data:
			stat_mngr.add_item(item_data)
			queue_free() # Delete the pedestal
		else:
			print("Error: Player missing StatManager or Pedestal missing ItemData!")
