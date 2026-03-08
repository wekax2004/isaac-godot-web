extends Node

# Persistent Achievements Singleton
signal achievement_unlocked(id: String, title: String)

var achievements_def = {
	"hello_world": {"title": "Hello World", "desc": "Reach Floor 2"},
	"root_access": {"title": "Root Access", "desc": "Defeat the first Boss"},
	"memory_leak": {"title": "Memory Leak", "desc": "Reach 12+ Memory Units in one run"},
	"overclocker": {"title": "Overclocker", "desc": "Reach Fire Rate < 0.15"},
	"cyber_warrior": {"title": "Cyber Warrior", "desc": "Collect 10+ items in one run"}
}

func _ready() -> void:
	# Connect to global signals if any, otherwise check conditions in process or via calls
	pass

func check_floor_reached(floor: int) -> void:
	if floor >= 2:
		unlock("hello_world")

func check_boss_killed() -> void:
	unlock("root_access")

func check_stats(stats: Node) -> void:
	if stats.fire_rate <= 0.15:
		unlock("overclocker")
	if stats.inventory.size() >= 10:
		unlock("cyber_warrior")

func check_bandwidth(amount: int) -> void:
	if amount >= 12:
		unlock("memory_leak")

func unlock(id: String) -> void:
	if not achievements_def.has(id): return
	
	if not SaveSystem.has_achievement(id):
		SaveSystem.unlock_achievement(id)
		achievement_unlocked.emit(id, achievements_def[id].title)
		print("ACHIEVEMENT UNLOCKED: ", achievements_def[id].title)
