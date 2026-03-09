extends Resource
class_name CharacterData

@export var character_name: String = ""
@export var character_id: String = "" # e.g. "0x01"

@export_group("Base Stats")
@export var health: int = 3
@export var damage: float = 3.5
@export var speed: float = 300.0
@export var fire_rate: float = 0.4
@export var range: float = 400.0

@export_group("Visuals")
@export var sprite_texture: Texture2D
@export var sprite_scale: Vector2 = Vector2(0.3, 0.3)
@export var sprite_color: Color = Color.WHITE

@export_group("Loadout")
@export var starting_items: Array[int] = [] # IDs of items to add on start
@export var starting_bandwidth: int = 20

@export_group("Narrative")
@export var description: String = ""
@export var passive_description: String = ""
@export var unlocked_by_achievement: String = "" # ID of achievement required
