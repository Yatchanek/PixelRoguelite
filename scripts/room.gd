extends Node2D
class_name Room

@onready var exits: Area2D = $Exits
@onready var exit_markers: Node2D = $ExitMarkers
@onready var enemies: Node2D = $Enemies
@onready var bullets: Node2D = $Bullets
@onready var timer: Timer = $Timer
@onready var doors: Node2D = $Doors
@onready var walls: Line2D = $Walls
@onready var obstacles: Node2D = $NavigationRegion2D/Obstacles

const enemy_scene = preload("res://scenes/basic_enemy.tscn")
const explosion_scene = preload("res://scenes/explosion.tscn")
const obstacle_scene = preload("res://scenes/obstacle.tscn")

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

var obstacle_shapes : Array[PackedVector2Array] = [
	[
		Vector2(0, 0), Vector2(Globals.WALL_THICKNESS, 0), Vector2(Globals.WALL_THICKNESS, 40), Vector2(0, 40)
	],
	[
		Vector2(0, 0), Vector2(40, 0), Vector2(40, Globals.WALL_THICKNESS), Vector2(Globals.WALL_THICKNESS, Globals.WALL_THICKNESS),
		Vector2(Globals.WALL_THICKNESS, 40 + Globals.WALL_THICKNESS), Vector2(0, 40 + Globals.WALL_THICKNESS)
	],
	[
		Vector2(0, 0), Vector2(40, 0),
	]
]

var obstacle_rects : Array[Rect2] = []

var player : Player


var coords : Vector2

var first_visited : int

var last_visited : int

var respawn_interval : int = 30

var max_enemies : int
var enemies_spawned : int = 0
var enemies_killed : int = 0

var obstacle_count : int

var is_first_room : bool = false

var room_data : RoomData

signal room_exited(coords : Vector2, exit_index : int)


func _ready() -> void:
	if room_data.last_visited == room_data.first_visited:
		Globals.rng.seed = room_data.first_visited
		room_data.rng_seed = room_data.first_visited
		room_data.max_enemies = Globals.rng.randi_range(2, 5)
		room_data.obstacle_count = Globals.rng.randi_range(0, 5)
		
	else:
		Globals.rng.seed = room_data.rng_seed
		max_enemies = room_data.max_enemies
		obstacle_count = room_data.obstacle_count
		
	
	var time_since_last_visit : int = Time.get_ticks_msec() - last_visited
	
	if room_data.last_visited == room_data.first_visited or time_since_last_visit > respawn_interval * 1000:
		activate_doors()
		timer.start(randf_range(2.0, 3.0))
	else:
		var time_left_to_respawn = respawn_interval * 1000 - time_since_last_visit
		enemies_spawned = room_data.max_enemies
		timer.start(time_left_to_respawn * 0.001)
		
	create_walls()
	configure_room()
	if !is_first_room:
		for i in room_data.obstacle_count:
			create_obstacles()
	await get_tree().process_frame
	create_navigation_polygon()

func create_navigation_polygon():
	var points : PackedVector2Array = []
	for corner in corners:
		points.append(corner)

	$NavigationRegion2D.navigation_polygon.add_outline(points)
	$NavigationRegion2D.bake_navigation_polygon()

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
	
	for i in exits.get_child_count():
		exits.get_child(i).position = position_offsets[i]
		exit_markers.get_child(i).position = position_offsets[i]
		doors.get_child(i).position = position_offsets[i]
		
		if room_data.layout_type & exit_mappings[i] != 0:
			exit_markers.get_child(i).show()
			if enemies_spawned == room_data.max_enemies:
				exits.get_child(i).set_deferred("disabled", false)

func create_obstacles():
	var shape : PackedVector2Array = get_obstacle_polygon()
	var new_bounding_rect : Rect2 = get_obstacle_bounding_rect(shape)
	var fits : bool = false
	var pos_candidate : Vector2
	var attempts : int = 0
	while !fits:
		if attempts > 10:
			break
		pos_candidate = Vector2(Globals.rng.randf_range(-Globals.PLAYFIELD_WIDTH * 0.5 + new_bounding_rect.size.x * 0.5 + 24, Globals.PLAYFIELD_WIDTH * 0.5 - 24 - new_bounding_rect.size.x * 0.5), Globals.rng.randf_range(-Globals.PLAYFIELD_HEIGHT * 0.5 + new_bounding_rect.size.y * 0.5 + 24, Globals.PLAYFIELD_HEIGHT * 0.5 - 24 - new_bounding_rect.size.y * 0.5))
		new_bounding_rect.position = pos_candidate
		
		var intersects : bool = false
		for other_rect in obstacle_rects:
			if new_bounding_rect.intersects(other_rect):
				attempts += 1
				intersects = true
				break
				
		fits = !intersects
		
	if fits:
		var obstacle : Obstacle = obstacle_scene.instantiate()
		obstacle.shape = shape
		obstacle.position = pos_candidate
		obstacles.call_deferred("add_child", obstacle)
		obstacle_rects.append(new_bounding_rect)


func get_obstacle_polygon() -> PackedVector2Array:
	var points : PackedVector2Array = []
	
	var size : int = snappedi(Globals.rng.randf_range(40, 80), 2)
	
	var type : int = Globals.rng.randi() % 2
	
	if type == 0:
		points = [
			Vector2(-size * 0.5, -Globals.WALL_THICKNESS * 0.5), Vector2(size * 0.5, -Globals.WALL_THICKNESS * 0.5), 
			Vector2(size * 0.5, Globals.WALL_THICKNESS * 0.5), Vector2(-size * 0.5, Globals.WALL_THICKNESS * 0.5)
		] 
	
	elif type == 1:
		points = [
			Vector2(-Globals.WALL_THICKNESS * 0.5, -Globals.WALL_THICKNESS * 0.5),
			Vector2(-Globals.WALL_THICKNESS * 0.5 + size, -Globals.WALL_THICKNESS * 0.5),
			Vector2(-Globals.WALL_THICKNESS * 0.5 + size, Globals.WALL_THICKNESS * 0.5),
			Vector2(Globals.WALL_THICKNESS * 0.5, Globals.WALL_THICKNESS * 0.5),
			Vector2(Globals.WALL_THICKNESS * 0.5, Globals.WALL_THICKNESS * 0.5 + size),
			Vector2(-Globals.WALL_THICKNESS * 0.5, Globals.WALL_THICKNESS * 0.5 + size),
			#Vector2(0, 0), Vector2(size, 0), 
			#Vector2(size, Globals.WALL_THICKNESS), Vector2(0, Globals.WALL_THICKNESS)
		]
	var xform : Transform2D = Transform2D(snappedf(Globals.rng.randf_range(0, TAU), PI / 16), Vector2.ZERO)
		
	return xform * points

func get_obstacle_bounding_rect(polygon : PackedVector2Array):
	var min_vec : = Vector2(1000, 1000)
	var max_vec : Vector2 = Vector2(-1000, -1000)

	for vertex in polygon:
		min_vec = minv(min_vec, vertex)
		max_vec = maxv(max_vec, vertex)

	return Rect2(Vector2.ZERO, (max_vec - min_vec) + Vector2(32, 32))

func minv(curvec : Vector2 ,newvec : Vector2 ):
	return Vector2(min(curvec.x,newvec.x),min(curvec.y,newvec.y))

func maxv(curvec : Vector2 ,newvec : Vector2 ):
	return Vector2(max(curvec.x,newvec.x),max(curvec.y,newvec.y))
	
func activate_doors():
	for i in exits.get_child_count():
		if room_data.layout_type & exit_mappings[i] != 0:
				var tw : Tween = create_tween()
				tw.tween_property(doors.get_child(i), "modulate:a", 1.0, 0.5)
			
func deactivate_doors():
	for i in exits.get_child_count():
		if room_data.layout_type & exit_mappings[i] != 0:
			var col_shape : CollisionShape2D = exits.get_child(i)
			col_shape.set_deferred("disabled", false)
			var tw : Tween = create_tween()
			tw.tween_property(doors.get_child(i), "modulate:a", 0.0, 0.5)


func _on_exits_body_shape_entered(_body_rid: RID, _body: Node2D, _body_shape_index: int, local_shape_index: int) -> void:
	room_exited.emit(room_data.coords, local_shape_index)


func _on_timer_timeout() -> void:
	if enemies_spawned == room_data.max_enemies:
		enemies_spawned = 0
		enemies_killed = 0
		activate_doors()
		timer.start(randf_range(1.0, 2.0))
	else:
		var enemy : Enemy = enemy_scene.instantiate() as Enemy
		var corner : Vector2 = corners.pick_random()
		while corner.distance_squared_to(to_local(player.global_position)) < 900:
			corner = corners.pick_random()
		
		var dist : float = randf_range(16, corner.distance_to(to_local(player.global_position)) * 0.75)
		enemy.position = corner + corner.direction_to(to_local(player.global_position)) * dist

		enemy.target = player
		
		enemy.bullet_fired.connect(_on_bullet_fired)
		enemy.exploded.connect(_on_explosion)
		enemy.tree_exited.connect(_on_enemy_destroyed)

		enemies.call_deferred("add_child", enemy)
		
		enemies_spawned += 1
		if enemies_spawned < room_data.max_enemies:
			timer.start(randf_range(1.0, 2.0))
			

func _on_explosion(pos : Vector2):
	var explosion : GPUParticles2D = explosion_scene.instantiate()
	explosion.position = to_local(pos)
	explosion.emitting = true
	
	call_deferred("add_child", explosion)


func _on_bullet_fired(bullet: Node2D, pos: Vector2) -> void:
	bullet.position = to_local(pos)
	call_deferred("add_child", bullet)

func _on_enemy_destroyed():
	if is_inside_tree():
		enemies_killed += 1
		if enemies_killed == room_data.max_enemies:
			await get_tree().create_timer(1.0).timeout
			deactivate_doors()
			timer.start(respawn_interval)
