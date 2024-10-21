extends Node2D
class_name Room

@onready var exits: Node2D = $Exits
@onready var exit_markers: Node2D = $ExitMarkers
@onready var enemies: Node2D = $Enemies
@onready var bullets: Node2D = $Bullets
@onready var timer: Timer = $Timer
@onready var doors: Node2D = $Doors
@onready var walls: Line2D = $Walls
@onready var obstacles: Node2D = $NavigationRegion2D/Obstacles

const door_scene = preload("res://scenes/door.tscn")
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
		Vector2(-Globals.PLAYFIELD_WIDTH, -Globals.PLAYFIELD_HEIGHT) * 0.5, 
		Vector2(Globals.PLAYFIELD_WIDTH, -Globals.PLAYFIELD_HEIGHT) * 0.5,
		Vector2(Globals.PLAYFIELD_WIDTH, Globals.PLAYFIELD_HEIGHT) * 0.5, 
		Vector2(-Globals.PLAYFIELD_WIDTH, Globals.PLAYFIELD_HEIGHT) * 0.5
		]
		
var exit_mappings : Dictionary = {
	0 : 0b0001,
	1 : 0b0010,
	2 : 0b0100,
	3 : 0b1000,
}

var position_offsets : Array = [
	Vector2(0.0, -Globals.PLAYFIELD_HEIGHT * 0.5),
	Vector2(Globals.PLAYFIELD_WIDTH * 0.5, 0.0),
	Vector2(0.0, Globals.PLAYFIELD_HEIGHT * 0.5),
	Vector2(-Globals.PLAYFIELD_WIDTH * 0.5, 0.0),
]



var obstacle_rects : Array[Rect2] = []

var player : Player


var coords : Vector2

var first_visited : int

var last_visited : int

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

signal room_exited(coords : Vector2, exit_index : int)
signal enemy_destroyed(exp_value : int)

func _ready() -> void:
	if room_data.last_visited == room_data.first_visited:
		Globals.rng.seed = room_data.first_visited
		room_data.rng_seed = room_data.first_visited
	else:
		Globals.rng.seed = room_data.rng_seed

	
	max_enemies = randi_range(3, 6 + level)
	
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
		
	create_walls()
	configure_room()
	#prints(room_data.coords, room_data.coords == Vector2i.ZERO)
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
	walls.default_color = Globals.color_palettes[Globals.current_palette][5]
	for exit in exit_markers.get_children():
		exit.self_modulate = Globals.color_palettes[Globals.current_palette][7]
		
	for door in doors.get_children():
		door.color = Globals.color_palettes[Globals.current_palette][3]

func create_walls():
	walls.width = Globals.WALL_THICKNESS
	walls.add_point(Vector2(-Globals.PLAYFIELD_WIDTH * 0.5, -Globals.PLAYFIELD_HEIGHT * 0.5))
	walls.add_point(Vector2(Globals.PLAYFIELD_WIDTH * 0.5, -Globals.PLAYFIELD_HEIGHT * 0.5))
	walls.add_point(Vector2(Globals.PLAYFIELD_WIDTH * 0.5, Globals.PLAYFIELD_HEIGHT * 0.5))
	walls.add_point(Vector2(-Globals.PLAYFIELD_WIDTH * 0.5, Globals.PLAYFIELD_HEIGHT * 0.5))


func configure_room():
	$Borders/TopBorder.shape.distance = -Globals.PLAYFIELD_HEIGHT * 0.5 + Globals.WALL_THICKNESS * 0.5
	$Borders/RightBorder.shape.distance = -Globals.PLAYFIELD_WIDTH * 0.5 + Globals.WALL_THICKNESS * 0.5
	$Borders/BottomBorder.shape.distance = -Globals.PLAYFIELD_HEIGHT * 0.5 + Globals.WALL_THICKNESS * 0.5
	$Borders/LeftBorder.shape.distance = -Globals.PLAYFIELD_WIDTH * 0.5 + Globals.WALL_THICKNESS * 0.5
	
	for i in exit_markers.get_child_count():
		exit_markers.get_child(i).position = position_offsets[i]
		
		if room_data.layout_type & exit_mappings[i] != 0:
			exit_markers.get_child(i).show()
			var door : Door = door_scene.instantiate()
			door.position = position_offsets[i]
			door.idx = i
			door.orientation = i % 2
			door.active_on_enter = enemies_spawned != max_enemies
			door.entered.connect(_on_door_entered)
			doors.call_deferred("add_child", door)
	
	apply_color_palette()

func create_obstacles():
	for x in range(1, 4):
		for y in range(1, 4, 2):
			var obstacle : Obstacle = obstacle_scene.instantiate() as Obstacle
			obstacle.rotation_offset = get_obstacle_rotation_offset(x, y)
			obstacle.position = Vector2(x * 128, y * 64)- Vector2(Globals.PLAYFIELD_WIDTH, Globals.PLAYFIELD_HEIGHT) * 0.5
			
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
	await get_tree().create_timer(1.0).timeout
	for door : Door in doors.get_children():
		door.activate()
			
func deactivate_doors():
	if !is_inside_tree():
		return
	await get_tree().create_timer(1.25).timeout
	for door : Door in doors.get_children():
		door.deactivate()
		

func _on_door_entered(idx : int) -> void:
	room_exited.emit(room_data.coords, idx)

func _on_timer_timeout() -> void:
	if enemies_spawned == max_enemies:
		enemies_spawned = 0
		enemies_killed = 0
		activate_doors()
		timer.start(randf_range(enemy_spawn_interval, 2 * enemy_spawn_interval))
	else:
		var corner : Vector2 = corners.pick_random()
		while corner.distance_squared_to(to_local(player.global_position)) < 3600:
			corner = corners.pick_random()			
		
		var accepted : bool = false
		var attempts : int = 0
		while !accepted:
			if attempts > 5:
				timer.start(0.25)
				break
			var intersects : bool = false
			var candidate_pos : Vector2 = Vector2(32 + 64 * randi_range(0, 7), 32 + 64 * randi_range(0, 3))- 0.5 * Vector2(Globals.PLAYFIELD_WIDTH, Globals.PLAYFIELD_HEIGHT)
			if candidate_pos.is_equal_approx(last_spawn_postion) or candidate_pos.distance_squared_to(to_local(player.global_position)) < 10000:
				intersects = true
					
			if intersects:
				attempts += 1
			else:
				accepted = true
				spawn_indicator(candidate_pos)
				last_spawn_postion = candidate_pos

func spawn_indicator(pos : Vector2):
	var indicator : Sprite2D = indicator_scene.instantiate()
	indicator.position = pos
	indicator.tree_exited.connect(spawn_enemy.bind(pos))
	call_deferred("add_child", indicator)


func spawn_enemy(pos : Vector2):	
	if !is_inside_tree():
		return
		
	var enemy : Enemy
	var chance : float = randf()
	if chance < 0.0:
		enemy = basic_enemy_scene.instantiate() as BasicEnemy
	elif chance < 0.0:
		enemy = missile_enemy_scene.instantiate() as MissileEnemy 
	elif chance < 0.0:
		enemy = turret_enemy_scene.instantiate() as TurretEnemy
	elif chance < 1.85:
		enemy = rapid_fire_enemy_scene.instantiate() as RapidFireEnemy
	elif chance < 0.95:
		enemy = kamikaze_enemy_scene.instantiate() as KamikazeEnemy
	else:
		enemy = big_enemy_scene.instantiate() as BigEnemy
	
	enemy.position = pos
	enemy.target = player
	enemy.level = level
	
	if not enemy is KamikazeEnemy and not enemy is MissileEnemy:
		enemy.bullet_fired.connect(_on_bullet_fired)
	
	if enemy is MissileEnemy:
		enemy.missile_fired.connect(_on_missile_fired)
		
	enemy.exploded.connect(_on_explosion)
	enemy.tree_exited.connect(_on_enemy_destroyed.bind(enemy.exp_value))		
	enemies.call_deferred("add_child", enemy)
	
	enemies_spawned += 1
	
	if enemies_spawned < max_enemies:
		timer.start(randf_range(enemy_spawn_interval, 2 * enemy_spawn_interval))
			

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
		
