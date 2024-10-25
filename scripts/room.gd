extends Node2D
class_name Room

@onready var exits: Node2D = $Exits
@onready var enemies: Node2D = $Enemies
@onready var bullets: Node2D = $Bullets
@onready var timer: Timer = $Timer
@onready var walls: Node2D = $Walls
@onready var obstacles: Node2D = $NavigationRegion2D/Obstacles

const door_scene = preload("res://scenes/door.tscn")
const outer_wall_scene = preload("res://scenes/outer_wall.tscn")
const basic_enemy_scene = preload("res://scenes/basic_enemy.tscn")
const kamikaze_enemy_scene = preload("res://scenes/kamikaze_enemy.tscn")
const turret_enemy_scene = preload("res://scenes/turret_enemy.tscn")
const missile_enemy_scene = preload("res://scenes/missile_enemy.tscn")
const rapid_fire_enemy_scene = preload("res://scenes/rapid_fire_enemy.tscn")
const big_enemy_scene = preload("res://scenes/big_enemy.tscn")
const explosion_scene = preload("res://scenes/explosion.tscn")
const obstacle_scene = preload("res://scenes/obstacle.tscn")
const indicator_scene = preload("res://scenes/indicator.tscn")

var exit_layout : int

var corners : Array[Vector2] = [
		Vector2(0, 0),
		Vector2(Globals.PLAYFIELD_WIDTH, 0),
		Vector2(Globals.PLAYFIELD_WIDTH, Globals.PLAYFIELD_HEIGHT), 
		Vector2(0, Globals.PLAYFIELD_HEIGHT)
		]
		
var exit_mappings : Dictionary = {
	0 : 0b0001,
	1 : 0b0010,
	2 : 0b0100,
	3 : 0b1000,
}

var position_offsets : Array = [
	Vector2(Globals.PLAYFIELD_WIDTH * 0.5, 0),
	Vector2(Globals.PLAYFIELD_WIDTH, Globals.PLAYFIELD_HEIGHT * 0.5),
	Vector2(Globals.PLAYFIELD_WIDTH * 0.5, Globals.PLAYFIELD_HEIGHT),
	Vector2(0, Globals.PLAYFIELD_HEIGHT * 0.5),
]


var player : Player

var respawn_interval : int = 60
var pickup_respawn_interval : int = 300
var enemy_spawn_interval : float = 1.0

var max_enemies : int
var enemies_spawned : int = 0
var enemies_killed : int = 0
var last_spawn_postion : Vector2 = Vector2.ZERO

var total_rooms : int
var level : int

var room_data : RoomData

var base_pos = Vector2i(32, 32)
var temporarily_occupied : Array[Vector2i] = []
var permanently_occupied : Array[Vector2i] = []

signal room_exited(coords : Vector2, exit_index : int)
signal enemy_destroyed(exp_value : int)

func _ready() -> void:
	if room_data.last_visited == room_data.first_visited:
		Globals.rng.seed = room_data.first_visited
		room_data.rng_seed = room_data.first_visited
	else:
		Globals.rng.seed = room_data.rng_seed

	
	max_enemies = min(randi_range(2, 4 + 2 * level), 20)
	
	var time_since_last_visit : int = Time.get_ticks_msec() - room_data.last_visited
	
	if room_data.last_visited == room_data.first_visited or time_since_last_visit > respawn_interval * 1000:
		activate_doors()
		timer.start(randf_range(2.0, 3.0))
	else:
		var time_left_to_respawn = respawn_interval * 1000 - time_since_last_visit
		enemies_spawned = max_enemies
		timer.start(time_left_to_respawn * 0.001)
	
	level = floori(total_rooms / 10)
	enemy_spawn_interval = max(1.0 - 0.05 * level, 0.2)
		
	configure_room()

	if !room_data.coords == Vector2i.ZERO:

		create_obstacles()
	await get_tree().process_frame
	create_navigation_polygon()
	

func create_navigation_polygon():
	var points : PackedVector2Array = []
	for corner in corners:
		points.append(corner)
	points = Geometry2D.offset_polygon(points, 18)[0]

	$NavigationRegion2D.navigation_polygon.add_outline(points)
	$NavigationRegion2D.bake_navigation_polygon()


func change_color_palette():
	apply_color_palette()
	for enemy in enemies.get_children():
		enemy.apply_color_palette()
	for obstacle in obstacles.get_children():
		obstacle.apply_color_palette()

func apply_color_palette():
	for wall : OuterWall in walls.get_children():
		wall.apply_color_palette()

func configure_room():
	for i in 4:
		var wall : OuterWall = outer_wall_scene.instantiate() as OuterWall
		wall.orientation = i
		wall.has_door = room_data.layout_type & exit_mappings[i] != 0
		wall.position = corners[i]
		wall.door_entered.connect(_on_door_entered)
		walls.call_deferred("add_child", wall)

func create_obstacles():
	for x in range(1, 4):
		for y in range(1, 4, 2):
			var obstacle : Obstacle = obstacle_scene.instantiate() as Obstacle
			obstacle.rotation_offset = get_obstacle_rotation_offset(x, y)
			obstacle.position = Vector2(x * 128, y * 64)
			
			obstacles.call_deferred("add_child", obstacle)

func get_obstacle_rotation_offset(x : int, y : int) -> int:
	var rotation_offset : int 
	if x == 2:
		if y == 1:
			rotation_offset = [0, 1, 2][Globals.rng.randi() % 3]
		elif y == 3:
			rotation_offset = [0, 2, 3][Globals.rng.randi() % 3]
	else:
		rotation_offset = Globals.rng.randi() % 4
	
	return rotation_offset

func activate_doors():
	if !is_inside_tree():
		return
	await get_tree().create_timer(0.25).timeout
	for wall : OuterWall in walls.get_children():
		wall.activate_door()
			
func deactivate_doors():
	if !is_inside_tree():
		return
	await get_tree().create_timer(1.25).timeout
	for wall : OuterWall in walls.get_children():
		wall.deactivate_door()
		
	if Globals.leveled_up:
		EventBus.upgrade_time.emit()	

func _on_door_entered(idx : int) -> void:
	room_exited.emit(room_data.coords, idx)

func _on_timer_timeout() -> void:
	if enemies_spawned == max_enemies:
		enemies_spawned = 0
		enemies_killed = 0
		activate_doors()
		timer.start(randf_range(enemy_spawn_interval, 2 * enemy_spawn_interval))
	else:
		temporarily_occupied = []
		var enemies_to_spawn : int = clamp(randi_range(1, 3), 1, max_enemies - enemies_spawned)	
		for i in enemies_to_spawn:		
			var accepted : bool = false
			var attempts : int = 0
			while !accepted:
				if attempts > 10:
					timer.start(0.25)
					break
				var intersects : bool = false
				var candidate_coords : Vector2i = Vector2i(randi_range(0, 7), randi_range(0, 3))

				if temporarily_occupied.has(candidate_coords) or permanently_occupied.has(candidate_coords) or get_manhattan_distance(candidate_coords, get_coords(to_local(player.global_position))) < 3:
					attempts += 1
				else:
					accepted = true
					spawn_indicator(candidate_coords)
					enemies_spawned += 1
					temporarily_occupied.append(candidate_coords)
					
		if enemies_spawned < max_enemies:
			timer.start(randf_range(enemy_spawn_interval, 2 * enemy_spawn_interval))

func spawn_indicator(coords : Vector2i):
	var indicator : Sprite2D = indicator_scene.instantiate()
	indicator.position = base_pos + coords * 64
	indicator.tree_exited.connect(spawn_enemy.bind(coords))
	call_deferred("add_child", indicator)


func spawn_enemy(coords : Vector2i):	
	if !is_inside_tree():
		return
		
	var enemy : Enemy
	var chance : float = randf()
	if chance < 0.85:
		enemy = basic_enemy_scene.instantiate() as BasicEnemy
	elif chance < 0.88:
		enemy = missile_enemy_scene.instantiate() as MissileEnemy 
	elif chance < 0.0:
		enemy = turret_enemy_scene.instantiate() as TurretEnemy
	elif chance < 0.95:
		enemy = rapid_fire_enemy_scene.instantiate() as RapidFireEnemy
	elif chance < 1.01:
		enemy = kamikaze_enemy_scene.instantiate() as KamikazeEnemy
	else:
		enemy = big_enemy_scene.instantiate() as BigEnemy
	
	enemy.position = base_pos + coords * 64
	enemy.target = player
	enemy.level = level
	
	if not enemy is KamikazeEnemy and not enemy is MissileEnemy:
		enemy.bullet_fired.connect(_on_bullet_fired)
	
	if enemy is MissileEnemy:
		enemy.missile_fired.connect(_on_missile_fired)
	
	if enemy is TurretEnemy:
		permanently_occupied.append(coords)
		
	enemy.exploded.connect(_on_explosion)
	enemy.tree_exited.connect(_on_enemy_destroyed.bind(enemy.exp_value))		
	enemies.call_deferred("add_child", enemy)

func get_coords(pos : Vector2) -> Vector2i:
	return(Vector2i(int(pos.x / 64), int(pos.y / 64)))		


func get_manhattan_distance(coords_a : Vector2i, coords_b : Vector2i) -> int:
	return abs(coords_a.x - coords_b.x) + abs(coords_a.y - coords_b.y)

func is_too_close(coords_a : Vector2i, coords_b : Vector2i) -> bool:
	return abs(coords_a.x - coords_b.x) < 3 or abs(coords_a.y - coords_b.y) < 2

func _on_explosion(pos : Vector2):
	if !is_inside_tree():
		return
	var explosion : GPUParticles2D = explosion_scene.instantiate()
	explosion.position = to_local(pos)
	explosion.emitting = true
	
	call_deferred("add_child", explosion)


func _on_bullet_fired(bullet: Node2D, pos: Vector2) -> void:
	bullet.position = to_local(pos)
	call_deferred("add_child", bullet)
	
func _on_missile_fired(missile: Node2D, pos: Vector2) -> void:
	missile.position = to_local(pos)
	missile.target = player
	missile.exploded.connect(_on_explosion)
	call_deferred("add_child", missile)

func _on_enemy_destroyed(exp_amount : int):
	if is_inside_tree():
		enemies_killed += 1
		enemy_destroyed.emit(exp_amount)
		if enemies_killed == max_enemies:
	
			deactivate_doors()
			timer.start(respawn_interval)
		
