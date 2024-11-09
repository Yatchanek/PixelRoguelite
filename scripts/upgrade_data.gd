extends Resource
class_name UpgradeData

var upgrade_names : Dictionary = {
	UpgradeManager.Upgrades.SPEED : "Speed",
	UpgradeManager.Upgrades.FIRERATE : "Firerate",
	UpgradeManager.Upgrades.HITPOINTS : "Hitpoints",
	UpgradeManager.Upgrades.BULLET_SPEED : "Bullet\nSpeed",
	UpgradeManager.Upgrades.BULLET_DAMAGE : "Power",
}

var upgrade_name : String
var amount : float

func initialize(type : UpgradeManager.Upgrades, _amount : float):
	upgrade_name = upgrade_names[type]
	amount = _amount
