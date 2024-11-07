extends Node2D

@onready var navigation_region_2d: NavigationRegion2D = $NavigationRegion2D
const enemy_scnene = preload("res://scenes/basic_enemy_title_screen.tscn")

var enemies : Array[Enemy] = []


var occupied_coords : Array[Vector2i] = []

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var points : PackedVector2Array = [
		Vector2(0, 0),
		Vector2(640, 0),
		Vector2(640, 320),
		Vector2(0, 320)
	]
	navigation_region_2d.navigation_polygon.add_outline(points)
	navigation_region_2d.bake_navigation_polygon(
		
	)
	await get_tree().create_timer(1.0).timeout

	spawn_dummies()
	
func spawn_dummies():
	occupied_coords = []
	for i in 10 - enemies.size():
		var enemy : Enemy = enemy_scnene.instantiate()
		#enemy.is_dummy = true
		var pos : Vector2i = Vector2i(32, 32) + Utils.get_random_coords(0, 8, 0, 5) * 64
		while occupied_coords.has(pos):
			pos = Vector2i(32, 32) + Utils.get_random_coords(0, 8, 0, 5) * 64
		
		enemy.bullet_fired.connect(_on_bullet_fired)
		enemy.exploded.connect(_on_explosion)
		enemy.destroyed.connect(_on_enemy_destroyed)
		enemy.position = pos
		enemy.level = 0
		occupied_coords.append(pos)
		enemies.append(enemy)
		call_deferred("add_child", enemy)	

func start_battle():		
	for enemy in enemies:
		enemy.enemies = enemies
		enemy.set_target()


func _on_bullet_fired(bullet: Node2D, pos: Vector2) -> void:
	bullet.position = to_local(pos)
	call_deferred("add_child", bullet)

func _on_explosion(explosion : Explosion, pos : Vector2):
	if !is_inside_tree():
		return

	else:
		explosion.position = to_local(pos)
		call_deferred("add_child", explosion)
	
func _on_enemy_destroyed(enemy : Enemy):
	enemies.erase(enemy)
	if enemies.size() > 1:
		for other_enemy in enemies:
			if other_enemy.target == enemy:
				other_enemy.enemies = enemies
				other_enemy.set_target()
				
	else:
		enemies[0].level_up()
		spawn_dummies()
