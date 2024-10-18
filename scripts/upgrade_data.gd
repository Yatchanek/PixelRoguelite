extends Resource
class_name UpgradeData

enum Upgrades {
	SPEED,
	FIRERATE,
	HITPOINTS,
	BULLET_SPEED,
	BULLET_DAMAGE
}

var upgrade_names : Dictionary = {
	Upgrades.SPEED : "Speed",
	Upgrades.FIRERATE : "Firerate",
	Upgrades.HITPOINTS : "Hitpoints",
	Upgrades.BULLET_SPEED : "Bullet Speed",
	Upgrades.BULLET_DAMAGE : "Power",
}

var current_type : Upgrades
var upgrade_name : String
var amount : float

var upgrade_pool : Array[Upgrades] = [
	Upgrades.SPEED,
	Upgrades.FIRERATE,
	Upgrades.HITPOINTS,
	Upgrades.BULLET_SPEED,
	Upgrades.BULLET_DAMAGE
]


func configure(player : Player, other_upgrades : Array[Upgrades]):
	var candidate_pool : Array[Upgrades] = upgrade_pool.duplicate()
	if other_upgrades.size() > 0:
		for upgrade : Upgrades in other_upgrades:
			candidate_pool.erase(upgrade)
			
	if player.speed >= 256:
		candidate_pool.erase(Upgrades.SPEED)
	if player.fire_rate <= 0.1:
		candidate_pool.erase(Upgrades.FIRERATE)
	if player.hp >= 20:
		candidate_pool.erase(Upgrades.HITPOINTS)
	if player.bullet_speed >= 768:
		candidate_pool.erase(Upgrades.BULLET_SPEED)
	if player.power >= 5:
		candidate_pool.erase(Upgrades.BULLET_DAMAGE)
		
	current_type = candidate_pool.pick_random()
	upgrade_name = upgrade_names[current_type]
	
	set_amount(player)
	
func set_amount(player : Player):
	if current_type == Upgrades.SPEED:
		amount = clamp(32 * randi_range(1, 2), 32, 256 - player.speed)
	if current_type == Upgrades.FIRERATE:
		amount = clamp(0.05 * randi_range(1, 2), 0.05, player.fire_rate - 0.1)
	if current_type == Upgrades.HITPOINTS:
		amount = clamp(randi_range(1, 3), 1, 20 - player.hp)
	if current_type == Upgrades.BULLET_SPEED:
		amount = clamp(32 * randi_range(1,3), 32, 768 - player.bullet_speed)
	if current_type == Upgrades.BULLET_DAMAGE:
		amount = clamp(randi_range(1, 3), 1, 5 - player.power)
