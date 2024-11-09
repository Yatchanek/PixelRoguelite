extends HBoxContainer
class_name UpgradeManager

const card_scene = preload("res://scenes/upgrade_card.tscn")

var selected_upgrades : Array[Upgrades] = []
var cards_added : int = 0
var cards_to_add : int = 2

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
	Upgrades.BULLET_SPEED : "Bullet\nSpeed",
	Upgrades.BULLET_DAMAGE : "Power",
}

var upgrade_probabilities : Dictionary = {
	Upgrades.SPEED : 0.35,
	Upgrades.FIRERATE : 0.25,
	Upgrades.HITPOINTS : 0.15,
	Upgrades.BULLET_SPEED : 0.2,
	Upgrades.BULLET_DAMAGE : 0.05,	
}

func add_card():
	print("Adding card")
	var candidates : Array[Upgrades] = get_possible_upgrades()
	if candidates.size() == 1 and get_child_count() == 0:
		cards_to_add = 1
		
	var selected_upgrade : Upgrades = select_upgrade_type()
	var amount : int = get_amount(selected_upgrade)
	
	var upgrade_data = UpgradeData.new()
	upgrade_data.initialize(selected_upgrade, amount)
	
	var card : UpgradeCard = card_scene.instantiate()
	card.upgrade_equipped = upgrade_data
	
	selected_upgrades.append(selected_upgrade)
	
	card.card_added.connect(_on_card_added)
	card.card_pressed.connect(_on_card_pressed)
	call_deferred("add_child", card)
	
func show_cards():
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tw.set_parallel()
	for idx in get_child_count():
		tw.tween_property(get_child(idx), "position:y", 320, 1.0).set_delay(idx * 0.25)


func hide_cards():
	selected_upgrades = []
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.set_parallel()
	for idx in get_child_count():
		tw.tween_property(get_child(idx), "position:y", 0, 1.0).set_delay(idx * 0.25)
	await tw.finished
	for card in get_children():
		card.queue_free()
	Globals.leveled_up = false
	await get_tree().create_timer(1.0).timeout
	get_tree().paused = false

func select_upgrade_type() -> Upgrades:
	var candidate : Upgrades
	var candidate_pool : Array[Upgrades] = get_possible_upgrades()
	
	var roll : float = randf()
	var total_chance : float = 0
	
	for upgrade : Upgrades in upgrade_probabilities.keys():
		total_chance += upgrade_probabilities[upgrade]
		if roll < total_chance:
			candidate = upgrade
			break

	return candidate

func get_amount(upgrade : Upgrades):
	match upgrade:
		Upgrades.SPEED:
			return 16
		Upgrades.BULLET_DAMAGE:
			return 1
		Upgrades.FIRERATE:
			return 0.1
		Upgrades.BULLET_SPEED:
			return 16
		Upgrades.HITPOINTS:
			return 5	

func get_possible_upgrades() -> Array[Upgrades]:
	var candidates : Array[Upgrades] = [Upgrades.SPEED, Upgrades.FIRERATE, Upgrades.HITPOINTS, Upgrades.BULLET_SPEED, Upgrades.BULLET_DAMAGE]
	if Globals.player.speed >= 320:
		candidates.erase(Upgrades.SPEED)
	if Globals.player.power >= 5:
		candidates.erase(Upgrades.BULLET_DAMAGE)
	if Globals.player.fire_rate <= 0.1:
		candidates.erase(Upgrades.FIRERATE)	
	if Globals.player.bullet_speed >= 720:
		candidates.erase(Upgrades.BULLET_SPEED)
	
	return candidates

func is_upgrade_possible(upgrade : Upgrades) -> bool:
	if selected_upgrades.has(upgrade):
		return false
	match upgrade:
		Upgrades.SPEED:
			if Globals.player.speed >= 320:
				return false
		Upgrades.BULLET_DAMAGE:
			if Globals.player.power >= 5:
				return false
		Upgrades.FIRERATE:
			if Globals.player.fire_rate <= 0.1:
				return false
		Upgrades.BULLET_SPEED:
			if Globals.player.bullet_speed >= 720:
				return false
	return true
	
func _on_card_added():
	cards_added += 1
	if cards_added < cards_to_add:
		add_card()
	else:
		show_cards()

func _on_card_pressed():
	for card : UpgradeCard in get_children():
		card.disable()
