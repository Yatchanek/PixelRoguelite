extends Resource
class_name UpgradeData


var upgrade_names : Dictionary = {
	UpgradeManager.Upgrades.SPEED : "Speed",
	UpgradeManager.Upgrades.FIRERATE : "Firerate",
	UpgradeManager.Upgrades.HITPOINTS : "Max\nHealth",
	UpgradeManager.Upgrades.SHIELD_STRENGTH : "Shield\nPower",
	UpgradeManager.Upgrades.BULLET_SPEED : "Bullet\nSpeed",
	UpgradeManager.Upgrades.BULLET_DAMAGE : "Power",
	UpgradeManager.Upgrades.AUTOFIRE : "Autofire",
}

var type : UpgradeManager.Upgrades
var upgrade_name : String
var amount : float

func initialize(_type : UpgradeManager.Upgrades, _amount : float):
	type = _type
	upgrade_name = upgrade_names[type]
	amount = _amount
