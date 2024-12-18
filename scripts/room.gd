extends Node2D
class_name Room

@onready var exits: Node2D = $Exits
@onready var enemies: Node2D = $Enemies
@onready var bullets: Node2D = $Bullets
@onready var timer: Timer = $Timer
@onready var walls: Node2D = $Walls
@onready var obstacles: Node2D = $NavigationRegion2D/Obstacles

@export_category("Room Elements")
@export var wall_horizontal_scene : PackedScene
@export var wall_horizontal_door_scene : PackedScene
@export var wall_vertical_scene : PackedScene
@export var wall_vertical_door_scene : PackedScene
@export var obstacle_horizontal_scene : PackedScene
@export var obstacle_vertical_scene : PackedScene

@export_category("Enemies")
@export var turret_enemy_scene : PackedScene
@export var bosses : Array[PackedScene] = []

@export_category("Misc")
@export var explosion_scene : PackedScene
@export var indicator_scene : PackedScene
@export var gate_key_scene : PackedScene
@export var pickup_scene : PackedScene
@export var map_pickup_scene : PackedScene

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

var respawn_interval : int = 120
var pickup_respawn_interval : int = 300
var enemy_spawn_interval : float = 0.5

var max_enemies : int
var enemies_spawned : int = 0
var enemies_killed : int = 0
var last_spawn_postion : Vector2 = Vector2.ZERO

var level : int
var depth : int
var room_data : RoomData

var base_pos = Vector2i(32, 32)
var temporarily_occupied : Array[Vector2i] = []
var permanently_occupied : Array[Vector2i] = []

var enemies_array : Array[Enemy] = []

var waiting_for_respawn : bool = false

signal room_exited(coords : Vector2i, exit_index : int)
signal enemy_destroyed(exp_value : int)

func _ready() -> void:
	configure_room()
	player.died.connect(_on_player_died)
	EventBus.game_completed.connect(_on_game_completed)
	if room_data.last_cleared == 0:
		Globals.rng.seed = room_data.first_visited
		room_data.rng_seed = room_data.first_visited
	else:
		Globals.rng.seed = room_data.rng_seed

	var current_time : int = int(Time.get_unix_time_from_system())
	var time_since_last_clear: int = current_time - room_data.last_cleared
	
	depth  = Utils.get_depth(room_data.coords)
	level = floor(depth / (6 - Settings.difficulty))
	max_enemies = min(randi_range(6 + depth / 2, 10 + depth / 2), 30)
	enemy_spawn_interval = max(1.0 - 0.05 * depth, 0.4)
	
	if !Globals.gate_key_coords.has(room_data.coords):
		if room_data.last_cleared == 0 or time_since_last_clear > respawn_interval:
			activate_doors()
			spawn_turret(min(0.035 + depth * 0.005, 0.075))
			EnemySpawner.setup(level)	
			timer.start(randf_range(enemy_spawn_interval, enemy_spawn_interval * 1.25))
		else:
			var time_left_to_respawn = respawn_interval - time_since_last_clear
			waiting_for_respawn = true
			if !Globals.game_completed:
				timer.start(time_left_to_respawn)
	
	
		if room_data.coords != Vector2i.ZERO:
			create_obstacles()
			if room_data.pickup_spawned:
				spawn_pickup()
			elif room_data.pickup_collect_time > 0:
				var time_since_last_pickup : int = current_time - room_data.pickup_collect_time
				if time_since_last_pickup > pickup_respawn_interval and randf() < 0.025:
					spawn_pickup()
			elif randf() < 0.09:
				spawn_pickup()
				
			if Globals.map_pickup_coords.has(room_data.coords):
				spawn_map_pickup()
		
		else:
			place_key_collector()
		
	
	elif !room_data.boss_defeated:
		activate_doors()
		spawn_boss()
		SoundManager.switch_music(SoundManager.Music.BATTLE_MUSIC)
	

	
	
	await get_tree().process_frame
	create_navigation_polygon()
	

func create_navigation_polygon():
	var points : PackedVector2Array = []
	for corner in corners:
		points.append(corner)
	points = Geometry2D.offset_polygon(points, 8)[0]

	$NavigationRegion2D.navigation_polygon.add_outline(points)
	$NavigationRegion2D.bake_navigation_polygon()


func change_color_palette():
	apply_color_palette()
	for enemy in enemies.get_children():
		enemy.apply_color_palette()
	for obstacle in obstacles.get_children():
		obstacle.apply_color_palette()

func apply_color_palette():
	for wall : Wall in walls.get_children():
		wall.apply_color_palette()

func configure_room():
	for i in 4:
		var wall : Wall
		if i % 2 == 0:
			if room_data.layout_type & exit_mappings[i] == 0:
				wall = wall_horizontal_scene.instantiate() as Wall
			else:
				wall = wall_horizontal_door_scene.instantiate() as Wall
				wall.door_entered.connect(_on_door_entered)
		else:
			if room_data.layout_type & exit_mappings[i] == 0:
				wall = wall_vertical_scene.instantiate() as Wall
			else:
				wall = wall_vertical_door_scene.instantiate() as Wall
				wall.door_entered.connect(_on_door_entered)

		wall.orientation = i
		wall.position = corners[i]
		wall.rotation = corners[i].direction_to(corners[wrapi(i + 1, 0, 4)]).angle()
		walls.call_deferred("add_child", wall)

func create_obstacles():
	for x in range(1, 4):
		for y in range(1, 4, 2):
			var obstacle : Obstacle
			var rotation_offset : int = get_obstacle_rotation_offset(x, y)
			if rotation_offset % 2 == 0:
				obstacle = obstacle_horizontal_scene.instantiate() as Obstacle
			else:
				obstacle = obstacle_vertical_scene.instantiate() as Obstacle
				
			obstacle.position = Vector2(x * 128, y * 64)
			obstacle.rotation = PI / 2 * rotation_offset
			
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

func spawn_map_pickup():
	var map_pickup : Area2D = map_pickup_scene.instantiate()
	if room_data.map_spawned:
		map_pickup.position = base_pos + room_data.map_coords * 64
	else:
		var coords : Vector2i
		var coords_accepted : bool = false
		while !coords_accepted:
			coords = Utils.get_random_coords()
			if !permanently_occupied.has(coords):
				coords_accepted = true
				
		map_pickup.position = base_pos + coords * 64
		room_data.map_coords = coords
		permanently_occupied.append(room_data.map_coords)
		room_data.map_spawned = true
		
	call_deferred("add_child", map_pickup)

func spawn_pickup():
	var pickup : Pickup = pickup_scene.instantiate()
	if room_data.pickup_spawned:
		pickup.position = base_pos + room_data.pickup_coords * 64
		pickup.type = room_data.pickup_type
	else:
		var coords : Vector2i
		var coords_accepted : bool = false
		while !coords_accepted:
			coords = Utils.get_random_coords()
			if !permanently_occupied.has(coords):
				coords_accepted = true
				
		
		pickup.position = base_pos + coords * 64
		pickup.type = randi() % 2
		room_data.pickup_coords = coords
		permanently_occupied.append(room_data.pickup_coords)
		room_data.pickup_spawned = true
		room_data.pickup_type = pickup.type
		
	
	pickup.collected.connect(_on_pickup_collected)

	call_deferred("add_child", pickup)

func _on_pickup_collected():
	room_data.pickup_collect_time = int(Time.get_unix_time_from_system())
	room_data.pickup_spawned = false

func place_key_collector():
	var collector : Node2D = load("res://scenes/key_collector.tscn").instantiate()
	collector.position = Vector2(48, 48)
	collector.all_keys_collected.connect(_on_all_keys_collected)
	call_deferred("add_child", collector)

func place_gate():
	var gate : Node2D = load("res://scenes/gate.tscn").instantiate()
	gate.position = Vector2(Globals.PLAYFIELD_WIDTH - 48, Globals.PLAYFIELD_HEIGHT - 48)
	call_deferred("add_child", gate)

func place_gate_key(pos : Vector2):
	var gate_key : GateKey = gate_key_scene.instantiate()
	gate_key.coords = room_data.coords
	gate_key.number = Globals.gate_key_coords[room_data.coords]
	gate_key.collected.connect(_on_gate_key_collected)
	gate_key.position = pos
	call_deferred("add_child", gate_key)

func spawn_turret(probability : float):
	if randf() > probability or room_data.coords == Vector2i.ZERO:
		return
	var enemy : Enemy = turret_enemy_scene.instantiate() as TurretEnemy
	var coords_accepted : bool = false
	var coords : Vector2i
	while !coords_accepted:
		coords = Utils.get_random_coords(1, 6, 1, 2)
		if !permanently_occupied.has(coords):
			coords_accepted = true
			permanently_occupied.append(coords)
			
	enemy.position = Vector2(base_pos + coords * 64)
	enemy.target = player
	enemy.bullet_fired.connect(_on_bullet_fired)
	enemy.exploded.connect(_on_explosion)
	call_deferred("add_child", enemy)
	
	probability *= 0.25
	spawn_turret(probability)
		
	
func _on_gate_key_collected():
	room_data.gate_key_collected = true

func activate_doors():
	if !is_inside_tree():
		return
	await get_tree().create_timer(0.25).timeout
	for wall : Wall in walls.get_children():
		wall.activate_door()
			
func deactivate_doors():
	if !is_inside_tree():
		return
	await get_tree().create_timer(1.25).timeout
	for wall : Wall in walls.get_children():
		wall.deactivate_door()
		
	if Globals.leveled_up:
		EventBus.upgrade_time.emit()	

func _on_door_entered(idx : int) -> void:
	room_exited.emit(room_data.coords, idx)

func _on_timer_timeout() -> void:
	if Globals.game_completed:
		return
	if waiting_for_respawn:
		enemies_spawned = 0
		enemies_killed = 0
		activate_doors()
		timer.start(randf_range(enemy_spawn_interval, 1.25 * enemy_spawn_interval))
	else:	
		temporarily_occupied = []
		var enemies_to_spawn : int = clamp(randi_range(1, min(1 + int(depth), 5)), 1, max(max_enemies - enemies_spawned, 1))	
		var coords_array : Array[Vector2i] = []
		for i in enemies_to_spawn:		
			var accepted : bool = false
			var attempts : int = 0
			var candidate_coords : Vector2i
			while !accepted:
				if attempts > 10:
					break
				candidate_coords = Utils.get_random_coords()
				
				for enemy : Enemy in enemies_array:
					if (base_pos + candidate_coords * 64).distance_squared_to(enemy.position) < 1024:
						attempts += 1
						break
				
				if temporarily_occupied.has(candidate_coords) or permanently_occupied.has(candidate_coords) or Utils.get_manhattan_distance(candidate_coords, Utils.get_coords(to_local(player.global_position))) < 3:
					attempts += 1
				else:
					accepted = true
					
			if accepted:
				coords_array.append(candidate_coords)
				temporarily_occupied.append(candidate_coords)
			
		if coords_array.size() > 0:
			spawn_indicators(coords_array)
		else:
			timer.start(randf_range(enemy_spawn_interval, 1.25 * enemy_spawn_interval))	


func spawn_indicators(coords_array : Array[Vector2i]):	
	if !is_inside_tree() or Globals.game_completed or player.dead:
		return
		
	for i in coords_array.size():
		var indicator : Sprite2D = indicator_scene.instantiate()
		indicator.position = base_pos + coords_array[i] * 64
		call_deferred("add_child", indicator)
		if i == coords_array.size() - 1:
			indicator.tree_exited.connect(spawn_enemies.bind(coords_array))

func spawn_enemies(coords_array : Array[Vector2i]):
	if !is_inside_tree() or Globals.game_completed:
		return
		
	for coords : Vector2i in coords_array:			
		var enemy_scenes : Array[PackedScene] = EnemySpawner.select_enemy(depth)
		if enemy_scenes.size() == 0:
			return
		var multiple : bool = enemy_scenes.size() > 1
	
		while enemy_scenes.size() > 0:
			var enemy : Enemy = enemy_scenes.pop_back().instantiate() as Enemy

			if multiple:
				enemy.position = Vector2(base_pos + coords * 64) + (Vector2.RIGHT * 9).rotated(randf_range(0, TAU))
			else:
				enemy.position = base_pos + coords * 64
			enemy.target = player
			enemy.level = level
			
			if enemy.has_signal("bullet_fired"):
				enemy.bullet_fired.connect(_on_bullet_fired)
			
			if enemy.has_signal("missile_fired"):
				enemy.missile_fired.connect(_on_missile_fired)
				
			enemy.exploded.connect(_on_explosion)
			enemy.destroyed.connect(_on_enemy_destroyed)		
			enemies.call_deferred("add_child", enemy)
			enemies_array.append(enemy)
			
		enemies_spawned += 1
		
	if enemies_spawned < max_enemies:
		timer.start(randf_range(enemy_spawn_interval, 1.25 * enemy_spawn_interval))
		
		
func spawn_boss():
	await get_tree().create_timer(enemy_spawn_interval).timeout
	
	if is_inside_tree():
		var boss : Boss = bosses[Globals.gate_key_coords[room_data.coords]].instantiate() as Boss
		
		var accepted : bool = false
		var candidate_coords : Vector2i
		while !accepted:
			candidate_coords = Utils.get_random_coords(2, 5, 2, 3)
			if Utils.get_manhattan_distance(candidate_coords, Utils.get_coords(to_local(player.global_position))) < 3:
				continue
			else:
				accepted = true
		
		boss.position = base_pos + candidate_coords * 64
		if boss.has_signal("bullet_fired"):
			boss.bullet_fired.connect(_on_bullet_fired)
		if boss.has_signal("missile_fired"):
			boss.missile_fired.connect(_on_missile_fired)
		boss.exploded.connect(_on_explosion)
		boss.destroyed.connect(_on_boss_destroyed)
		enemies.call_deferred("add_child", boss)
		enemies_array.append(boss)



	


func _on_explosion(explosion : Explosion, pos : Vector2):
	if !is_inside_tree():
		return

	else:
		explosion.position = to_local(pos)
		call_deferred("add_child", explosion)


func _on_bullet_fired(bullet: Node2D, pos: Vector2) -> void:
	bullet.position = to_local(pos)
	if bullet is RectangleGrenade:
		bullet.fragment_fired.connect(_on_bullet_fired)
	elif bullet is Mine:
		bullet.exploded.connect(_on_explosion)
		bullet.fragment_fired.connect(_on_bullet_fired)
	call_deferred("add_child", bullet)
	
func _on_missile_fired(missile: Node2D, pos: Vector2) -> void:
	missile.position = to_local(pos)
	missile.target = player
	missile.exploded.connect(_on_explosion)
	call_deferred("add_child", missile)

func _on_boss_destroyed(enemy : Enemy):
	SoundManager.switch_music(SoundManager.Music.MAIN_MUSIC)
	#enemy_destroyed.emit(200)
	room_data.boss_defeated = true
	place_gate_key(enemy.position)
	deactivate_doors()
	room_data.last_cleared = int(Time.get_unix_time_from_system())

func _on_enemy_destroyed(enemy : Enemy):
	if is_inside_tree():
		enemies_killed += 1
		enemy_destroyed.emit(enemy.exp_value)
		enemies_array.erase(enemy)
		if enemies_killed == max_enemies:
			room_data.last_cleared = int(Time.get_unix_time_from_system())
			deactivate_doors()
			waiting_for_respawn = true
			timer.start(respawn_interval)

func _on_all_keys_collected():
	place_gate()

func _on_player_died():
	timer.stop()
	for enemy : Enemy in enemies_array:
		enemy.disable()

func _on_game_completed():
	for enemy in enemies_array:
		enemy.queue_free()
	for bullet in bullets.get_children():
		bullet.queue_free()
	timer.stop()
