extends SceneTree

func _init():
	var artifacts_dir = "C:/Users/home/.gemini/antigravity/brain/98c388c2-3820-487f-9d01-24baf58a2781"
	var out_dir = "res://assets/sprites"
	var dir = DirAccess.open(artifacts_dir)
	if dir == null:
		print("Could not open artifacts dir")
		quit()
		return
		
	if not DirAccess.dir_exists_absolute("res://assets"):
		DirAccess.make_dir_absolute("res://assets")
	if not DirAccess.dir_exists_absolute("res://assets/sprites"):
		DirAccess.make_dir_absolute("res://assets/sprites")
	
	var files_map = {
		"player_rogue": "player.png",
		"projectile_dagger": "dagger.png",
		"enemy_chaser": "skeleton.png",
		"enemy_shooter": "goblin.png",
		"enemy_tank": "orc.png",
		"enemy_flanker": "bat.png",
		"boss_necromancer": "necromancer.png",
		"env_floor": "floor.png",
		"env_wall": "wall.png",
		"env_door": "door.png",
		"obs_rock": "rock.png",
		"obs_hole": "hole.png",
		"pickup_heart": "heart.png",
		"pickup_coin": "coin.png",
		"pickup_key": "key.png",
		"pickup_bomb": "bomb.png",
		"item_upgrade": "book.png"
	}
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var candidates = {}
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			for prefix in files_map:
				if file_name.begins_with(prefix):
					var path = artifacts_dir + "/" + file_name
					# Find newest file
					if not candidates.has(prefix):
						candidates[prefix] = path
					else:
						var cur_time = FileAccess.get_modified_time(path)
						var best_time = FileAccess.get_modified_time(candidates[prefix])
						if cur_time > best_time:
							candidates[prefix] = path
		file_name = dir.get_next()
		
	for prefix in candidates:
		var in_path = candidates[prefix]
		var out_name = files_map[prefix]
		
		var img = Image.new()
		var err = img.load(in_path)
		if err != OK:
			print("Err loading ", in_path)
			continue
			
		img.convert(Image.FORMAT_RGBA8)
		
		var min_x = img.get_width()
		var max_x = 0
		var min_y = img.get_height()
		var max_y = 0
		
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var c = img.get_pixel(x, y)
				# 0.9 = 230/255 -> nearly white
				if c.r > 0.9 and c.g > 0.9 and c.b > 0.9:
					img.set_pixel(x, y, Color(1, 1, 1, 0)) # transparent
				else:
					if x < min_x: min_x = x
					if x > max_x: max_x = x
					if y < min_y: min_y = y
					if y > max_y: max_y = y
					
		var crop_w = max_x - min_x + 1
		var crop_h = max_y - min_y + 1
		if crop_w > 0 and crop_h > 0:
			var cropped = img.get_region(Rect2i(min_x, min_y, crop_w, crop_h))
			cropped.save_png("res://assets/sprites/" + out_name)
			print("Saved: " + out_name)
			
	quit()
