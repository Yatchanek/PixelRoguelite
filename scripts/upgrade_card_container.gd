extends HBoxContainer
class_name UpgradeManager

const card_scene = preload("res://scenes/ui_elements/upgrade_card.tscn")

var selected_upgrades : Array[Upgrades] = []
var cards_to_add : int = 3
var cards_added : int = 0

enum Upgrades {
	SPEED,
	FIRERATE,
	HITPOINTS,
	SHIELD_STRENGTH,
	BULLET_SPEED,
	BULLET_DAMAGE,
	DASH_DURATION,
	DASH_REGEN,
	DASH_ENERGY
}


const upgrade_probabilities : Dictionary = {
	Upgrades.SPEED : 0.25,
	Upgrades.FIRERATE : 0.20,
	Upgrades.HITPOINTS : 0.075,
	Upgrades.SHIELD_STRENGTH : 0.05,
	Upgrades.BULLET_SPEED : 0.15,
	Upgrades.BULLET_DAMAGE : 0.025,
	Upgrades.DASH_DURATION : 0.075,
	Upgrades.DASH_REGEN : 0.1,
	Upgrades.DASH_ENERGY : 0.0745,
}

const amounts: Dictionary = {
	Upgrades.SPEED : 16,
	Upgrades.FIRERATE : -0.05,
	Upgrades.HITPOINTS : 5,
	Upgrades.SHIELD_STRENGTH : 3,
	Upgrades.BULLET_SPEED : 32,
	Upgrades.BULLET_DAMAGE : 1,
	Upgrades.DASH_DURATION : -0.1,
	Upgrades.DASH_REGEN : -0.1,
	Upgrades.DASH_ENERGY : 5,	
}

const upgrade_names : Dictionary = {
	Upgrades.SPEED : "Speed",
	Upgrades.FIRERATE : "Firerate",
	Upgrades.HITPOINTS : "Max\nHealth",
	Upgrades.SHIELD_STRENGTH : "Shield\nPower",
	Upgrades.BULLET_SPEED : "Bullet\nSpeed",
	Upgrades.BULLET_DAMAGE : "Power",
	Upgrades.DASH_DURATION : "Dash\nDuration",
	Upgrades.DASH_REGEN : "Dash\n regen rate",
	Upgrades.DASH_ENERGY : "Dash\n energy",	
}

const properties: Dictionary = {
	Upgrades.SPEED : "speed",
	Upgrades.FIRERATE : "fire_rate",
	Upgrades.HITPOINTS : "max_hp",
	Upgrades.SHIELD_STRENGTH : "shield_hp",
	Upgrades.BULLET_SPEED : "bullet_speed",
	Upgrades.BULLET_DAMAGE : "power",
	Upgrades.DASH_DURATION : "dash_duration",
	Upgrades.DASH_REGEN : "dash_regen_speed",
	Upgrades.DASH_ENERGY : "dash_energy",	
}

const units: Dictionary = {
	Upgrades.SPEED : "px/s",
	Upgrades.FIRERATE : "s/shot",
	Upgrades.HITPOINTS : "",
	Upgrades.SHIELD_STRENGTH : "",
	Upgrades.BULLET_SPEED : "px/s",
	Upgrades.BULLET_DAMAGE : "",
	Upgrades.DASH_DURATION : "s",
	Upgrades.DASH_REGEN : "pt/s",
	Upgrades.DASH_ENERGY : "",	
}

signal cards_hidden

func add_cards():
	var candidates : Array[Upgrades] = get_possible_upgrades()
	for i in min(candidates.size(), cards_to_add):

		var selected_upgrade : Upgrades = select_upgrade_type(candidates)
	
		var card : UpgradeCard = card_scene.instantiate()
		card.upgrade_equipped = selected_upgrade
	
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
	cards_added = 0
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.set_parallel()
	for idx in get_child_count():
		tw.tween_property(get_child(idx), "position:y", 0, 0.75).set_delay(idx * 0.15)
	await tw.finished
	for card in get_children():
		card.queue_free()
	cards_hidden.emit()
	Globals.leveled_up = false
	get_tree().paused = false

func select_upgrade_type(candidate_pool : Array[Upgrades]) -> Upgrades:
	var candidate : Upgrades
	
	
	var total_weight : float = 0
	for c in candidate_pool:
		total_weight += upgrade_probabilities[c]
		
	var roll : float = randf() * total_weight
		
	var total_chance : float = 0
	
	for upgrade : Upgrades in candidate_pool:
		total_chance += upgrade_probabilities[upgrade]
		if roll < total_chance:
			candidate = upgrade
			candidate_pool.erase(upgrade)
			break
	
	return candidate


func get_possible_upgrades() -> Array[Upgrades]:
	var candidates : Array[Upgrades] = [Upgrades.HITPOINTS, Upgrades.DASH_ENERGY, Upgrades.SHIELD_STRENGTH]
	if Globals.player.speed < 320:
		candidates.append(Upgrades.SPEED)
	if Globals.player.power < 10:
		candidates.append(Upgrades.BULLET_DAMAGE)
	if Globals.player.fire_rate > 0.1:
		candidates.append(Upgrades.FIRERATE)	
	if Globals.player.bullet_speed < 768:
		candidates.append(Upgrades.BULLET_SPEED)
	if Globals.player.dash_duration < 0.5:
		candidates.append(Upgrades.DASH_DURATION)
	if Globals.player.dash_regen_speed > 0.1:
		candidates.append(Upgrades.DASH_REGEN)
		
	
	return candidates


func _on_card_pressed():
	for card : UpgradeCard in get_children():
		card.disable()
	await get_tree().create_timer(0.5).timeout
	hide_cards()

func _on_card_added():
	cards_added += 1
	if cards_added == cards_to_add:
		show_cards()
