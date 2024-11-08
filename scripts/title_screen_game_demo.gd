extends Node2D

@onready var battle_timer: Timer = $BattleTimer
@onready var navigation_region_2d: NavigationRegion2D = $NavigationRegion2D

const enemy_scnene = preload("res://scenes/basic_enemy_title_screen.tscn")

var enemies : Array[Enemy] = []

var spawn_called : bool = false
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

	spawn_dummies(10)
	
func spawn_dummies(amount : int):
	if amount == 0:
		battle_timer.start(randf_range(10, 20))
		return
		
	
	#enemy.is_dummy = true
	var pos : Vector2i
	var accepted : bool = false
	var attempts : int = 0
	while !accepted:
		if attempts > 20:
			break
		pos = Vector2i(32, 32) + Utils.get_random_coords(0, 8, 0, 5) * 64
		var too_close : bool = false
		for other_enemy : Enemy in enemies:
			if pos.distance_squared_to(other_enemy.position) < 900:
				too_close = true
				attempts += 1
				break
		if !too_close:
			accepted = true
			
	if accepted:
		var enemy : Enemy = enemy_scnene.instantiate()
		enemy.bullet_fired.connect(_on_bullet_fired)
		enemy.exploded.connect(_on_explosion)
		enemy.destroyed.connect(_on_enemy_destroyed)
		enemy.position = pos
		enemy.level = 0
		enemies.append(enemy)
		call_deferred("add_child", enemy)
		await get_tree().create_timer(0.25).timeout
	
		spawn_dummies(amount - 1)
	else:
		spawn_dummies(amount)
		
	

func start_battle():
	spawn_called = false	
	for enemy in enemies:
		enemy.enemies = enemies
		enemy.set_target()

func apply_color_palette():
	for enemy : Enemy in enemies:
		enemy.apply_color_palette()

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
		if enemies.size() > 0:
			enemies[0].level_up()
		if !spawn_called:
			spawn_dummies(10 - enemies.size())
			spawn_called = true


func _on_battle_timer_timeout() -> void:
	start_battle()
