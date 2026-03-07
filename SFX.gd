extends Node

# Procedural retro SFX generator utility
# Usage: SFX.play_shoot(), SFX.play_hit(), etc.
# Generates simple waveforms at runtime - no audio files needed!

func play_sfx(frequency: float, duration: float, volume_db: float = -10.0, type: String = "square") -> void:
	var player = AudioStreamPlayer.new()
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = duration + 0.1
	player.stream = gen
	player.volume_db = volume_db
	add_child(player)
	player.play()
	
	var playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		player.queue_free()
		return
	
	var sample_rate = gen.mix_rate
	var total_samples = int(sample_rate * duration)
	var phase = 0.0
	
	for i in range(total_samples):
		var t = float(i) / float(total_samples) # 0.0 to 1.0 progress
		var envelope = 1.0 - t # Linear fade out
		var sample = 0.0
		
		# Frequency sweep (optional pitch drop)
		var freq = frequency * (1.0 - t * 0.3) if type == "sweep" else frequency
		
		match type:
			"square":
				sample = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
			"noise":
				sample = randf_range(-1.0, 1.0)
			"sine":
				sample = sin(phase * TAU)
			"sweep":
				sample = sin(phase * TAU)
		
		sample *= envelope * 0.3 # Master volume
		playback.push_frame(Vector2(sample, sample))
		phase += freq / sample_rate
	
	# Auto-cleanup
	await get_tree().create_timer(duration + 0.2).timeout
	if is_instance_valid(player):
		player.queue_free()

# --- Prebuilt SFX ---

func play_shoot() -> void:
	play_sfx(800.0, 0.08, -12.0, "square")

func play_hit() -> void:
	play_sfx(200.0, 0.1, -8.0, "noise")

func play_explosion() -> void:
	play_sfx(100.0, 0.3, -5.0, "noise")

func play_pickup() -> void:
	play_sfx(1200.0, 0.12, -10.0, "sine")

func play_dash() -> void:
	play_sfx(600.0, 0.15, -12.0, "sweep")

func play_death() -> void:
	play_sfx(150.0, 0.5, -6.0, "sweep")

func play_door_unlock() -> void:
	play_sfx(500.0, 0.15, -10.0, "sine")

func play_boss_roar() -> void:
	play_sfx(80.0, 0.4, -4.0, "noise")
