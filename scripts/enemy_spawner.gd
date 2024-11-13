extends Node

@export var basic_enemy_scene : PackedScene
@export var kamikaze_enemy_scene : PackedScene
@export var missile_enemy_scene : PackedScene
@export var rapid_fire_enemy_scene : PackedScene
@export var laser_enemy_scene : PackedScene

enum Enemies {
	BASIC_ENEMY,
	KAMIKAZE_ENEMY,
	MISSILE_ENEMY,
	RAPID_FIRE_ENEMY,
	LASER_ENEMY
}

var scenes : Dictionary = {}

const weights : Dictionary = {
	Enemies.BASIC_ENEMY : 100,
	Enemies.KAMIKAZE_ENEMY : 15,
	Enemies.MISSILE_ENEMY : 10,
	Enemies.RAPID_FIRE_ENEMY : 20,
	Enemies.LASER_ENEMY	: 5
}

func _ready() -> void:
	scenes  = {
	Enemies.BASIC_ENEMY : basic_enemy_scene,
	Enemies.KAMIKAZE_ENEMY : kamikaze_enemy_scene,
	Enemies.MISSILE_ENEMY : missile_enemy_scene,
	Enemies.RAPID_FIRE_ENEMY : rapid_fire_enemy_scene,
	Enemies.LASER_ENEMY	: laser_enemy_scene	
}
	select_enemy(0)

func select_enemy(depth : int) -> PackedScene:
	var enemy : PackedScene
	var possible_enemies : Array[Enemies] = get_possible_enemies(depth)
	
	var total_weights : int = 0
	for e in possible_enemies:
		total_weights += int(weights[e])

	var roll = randf_range(0, total_weights)
	var total_chance : int = 0
	for e in possible_enemies:
		total_chance += weights[e]
		if roll < total_chance:
			enemy = scenes[e]
			break

	return enemy
	
func get_possible_enemies(depth : int) -> Array[Enemies]:
	var enemies : Array[Enemies] = [Enemies.BASIC_ENEMY]
	
	if depth > 2:
		enemies.append(Enemies.KAMIKAZE_ENEMY)
	if depth > 3:
		enemies.append(Enemies.RAPID_FIRE_ENEMY)
	if depth > 4:
		enemies.append(Enemies.MISSILE_ENEMY)
	if depth > 5:
		enemies.append(Enemies.LASER_ENEMY)
		
	return enemies
