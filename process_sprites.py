import os
from PIL import Image

artifacts_dir = r"C:\Users\home\.gemini\antigravity\brain\98c388c2-3820-487f-9d01-24baf58a2781"
out_dir = r"D:\isaac-godot\assets\sprites"

if not os.path.exists(out_dir):
    os.makedirs(out_dir)

files = {
    "player_rogue": "player.png",
    "projectile_dagger": "dagger.png",
    "enemy_chaser": "skeleton.png",
    "enemy_shooter": "goblin.png",
    "enemy_tank": "orc.png",
    "enemy_flanker": "bat.png",
    "boss_necromancer": "necromancer.png"
}

def remove_white(img_path, out_path):
    img = Image.open(img_path).convert("RGBA")
    data = img.getdata()
    new_data = []
    for item in data:
        # Check if it's very close to white
        if item[0] >= 220 and item[1] >= 220 and item[2] >= 220:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
    img.putdata(new_data)
    
    # create cropped bounding box to remove excess transparency
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        
    # Standardize size for enemies to roughly 64x64 or aspect ratio
    # Just save raw cropped for now to maintain aspect ratio
    img.save(out_path, "PNG")

for prefix, final_name in files.items():
    latest = None
    latest_time = 0
    for file in os.listdir(artifacts_dir):
        if file.startswith(prefix) and file.endswith(".png"):
            path = os.path.join(artifacts_dir, file)
            t = os.path.getmtime(path)
            if t > latest_time:
                latest_time = t
                latest = path
    if latest:
        remove_white(latest, os.path.join(out_dir, final_name))
        print(f"Processed {final_name}")
