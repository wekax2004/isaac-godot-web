extends Resource
class_name RoomTemplate

@export var name: String = "Generic Room"
# Array of dictionaries: {"pos": Vector2, "type": int, "subtype": String}
# pos is local relative to room center (0,0)
@export var layouts: Array[Dictionary] = []

# Types: 0=Obstacle, 1=Hazard (TNT/Turret), 2=Enemy
