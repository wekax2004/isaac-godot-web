extends Node

signal glitch_triggered(type: String, duration: float)
signal glitch_ended(type: String)

var active_glitches = {}
var glitch_timer: float = 60.0 # Next glitch in 60s

func _process(delta: float) -> void:
	glitch_timer -= delta
	if glitch_timer <= 0:
		_trigger_random_glitch()
		glitch_timer = randf_range(90.0, 150.0)
	
	# Update active glitches
	var to_remove = []
	for type in active_glitches.keys():
		active_glitches[type] -= delta
		if active_glitches[type] <= 0:
			to_remove.append(type)
	
	for type in to_remove:
		_end_glitch(type)

func _trigger_random_glitch() -> void:
	var types = ["OVERCLOCK", "LAG_SPIKE", "DATA_CORRUPTION"]
	var type = types[randi() % types.size()]
	var duration = 10.0
	
	match type:
		"OVERCLOCK":
			Engine.time_scale = 1.0 # Ensure base
			duration = 10.0
		"LAG_SPIKE":
			Engine.time_scale = 0.5
			duration = 8.0
		"DATA_CORRUPTION":
			duration = 6.0
			
	active_glitches[type] = duration
	glitch_triggered.emit(type, duration)
	print("!!! GLITCH DETECTED: ", type, " !!!")

func _end_glitch(type: String) -> void:
	active_glitches.erase(type)
	match type:
		"LAG_SPIKE":
			Engine.time_scale = 1.0
	glitch_ended.emit(type)
	print("System Restored: ", type)

func is_glitch_active(type: String) -> bool:
	return active_glitches.has(type)

func get_glitch_mult(type: String) -> float:
	if type == "DATA_CORRUPTION" and active_glitches.has("DATA_CORRUPTION"):
		return 2.0
	if type == "OVERCLOCK" and active_glitches.has("OVERCLOCK"):
		return 0.5 # Fire rate reduction (faster)
	return 1.0
