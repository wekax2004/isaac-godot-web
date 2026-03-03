extends GPUParticles2D
class_name BloodSplatter

func _ready() -> void:
	# Automatically start emitting exactly once
	emitting = true
	one_shot = true
	
	# Particles process via hardware, but the node itself stays in memory.
	# We hook into the finished signal to cleanly destroy the node once all particles disappear.
	finished.connect(_on_finished)

func _on_finished() -> void:
	queue_free()

# Note: In the Godot Editor, you MUST assign a ParticleProcessMaterial to this node.
# Set its properties:
# - Direction: Y = -1 (Upwards)
# - Spread: 45 to 90 degrees
# - Initial Velocity: ~150
# - Gravity: Y = 400 (Pulls the blood down quickly to the floor)
# - Color Ramp: Dark Red to Transparent Red
# - Scale: Start at 2 or 3, shrink to 0
