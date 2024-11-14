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
	UpgradeManager.Upgrades.DASH_DURATION : "Dash\nDuration",
	UpgradeManager.Upgrades.DASH_REGEN : "Dash\n regen rate",
	UpgradeManager.Upgrades.DASH_ENERGY : "Dash\n energy",	
}

var amounts_verbose: Dictionary = {
	UpgradeManager.Upgrades.SPEED : "+16 px/s",
	UpgradeManager.Upgrades.FIRERATE : "-0.1 s/shot",
	UpgradeManager.Upgrades.HITPOINTS : "+5",
	UpgradeManager.Upgrades.SHIELD_STRENGTH : "+3",
	UpgradeManager.Upgrades.BULLET_SPEED : "+32 px/s",
	UpgradeManager.Upgrades.BULLET_DAMAGE : "+1",
	UpgradeManager.Upgrades.AUTOFIRE : "",
	UpgradeManager.Upgrades.DASH_DURATION : "+0.1 s",
	UpgradeManager.Upgrades.DASH_REGEN : "-0.1 s",
	UpgradeManager.Upgrades.DASH_ENERGY : "+5",	
}

var type : UpgradeManager.Upgrades
var upgrade_name : String
var amount : float
var amount_desc : String

func initialize(_type : UpgradeManager.Upgrades, _amount : float):
	type = _type
	upgrade_name = upgrade_names[type]
	amount = _amount
	amount_desc = amounts_verbose[type]
