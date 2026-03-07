extends CPUParticles2D

func _ready() -> void:
	emitting = true
	# Give it slightly longer than its lifetime to ensure all particles clear
	var timer = get_tree().create_timer(lifetime + 0.1)
	timer.timeout.connect(queue_free)
