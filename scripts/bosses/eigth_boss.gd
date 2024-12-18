extends Boss
class_name EigthGuardian

@onready var shoot_timer: Timer = $ShootTimer
@onready var body: Sprite2D = $Body
@onready var chasis: Sprite2D = $Chasis
@onready var muzzle_pivot: Marker2D = $MuzzlePivot
@onready var muzzle: Marker2D = $MuzzlePivot/Sprite2D2/Muzzle
@onready var muzzle_2: Marker2D = $MuzzlePivot/Sprite2D3/Muzzle2
@onready var timer: Timer = $Timer
@onready var swarm_spot: Marker2D = $SwarmSpot



const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")
const swarm_enemy_scene : PackedScene = preload("res://scenes/enemies/swarm_enemy.tscn")

var current_state : State

var attack_mode : AttackMode

var muzzles : Array[Marker2D] = []
var current_muzzle : int = 0

enum AttackMode {
	SWARM,
	BULLET,
	WAIT
}

enum State {
	MOVE,
	KNOCKBACK,
	DEPLOY
}

var swarmlings_spawned : int = 0

signal bullet_fired(bullet : Node2D, pos : Vector2)


func _ready() -> void:
	setup()
	apply_color_palette()
	target = Globals.player
		
	set_physics_process(false)
	set_process(false)
		
	var tw : Tween = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(body, "modulate:a", 1.0, 1.0)
	tw.parallel().tween_property(chasis, "modulate:a", 1.0, 1.0)
	tw.parallel().tween_property(muzzle_pivot, "modulate:a", 1.0, 1.0)
	await tw.finished
	set_physics_process(true)
	set_process(true)

	current_state = State.MOVE
	attack_mode = AttackMode.BULLET
	muzzles = [muzzle, muzzle_2]
	shoot_timer.start(fire_interval)
	timer.start(fire_interval + randf_range(5, 7))
	

func _process(delta: float) -> void:
	health_bar_pivot.global_rotation = 0
	if current_state == State.MOVE:
		elapsed_time += delta
		if elapsed_time > wander_interval:
			waypoint = select_destination(1, 6, 1, 2, 128)
			elapsed_time -= wander_interval
			wander_interval = randf_range(1.25, 2.0)
	
	if is_instance_valid(target) and !target.dead:
		var target_transform : Transform2D = global_transform.looking_at(target.global_position)
		global_transform = global_transform.interpolate_with(target_transform, 0.5)

		target_transform = muzzle.global_transform.looking_at(target.global_position)
		muzzle.global_transform = muzzle.global_transform.interpolate_with(target_transform, 0.25)
		target_transform = muzzle_2.global_transform.looking_at(target.global_position)
		muzzle_2.global_transform = muzzle_2.global_transform.interpolate_with(target_transform, 0.25)


func _physics_process(_delta: float) -> void:
	if current_state == State.KNOCKBACK:
		velocity = lerp(velocity, Vector2.ZERO, 0.15)
		if velocity.length_squared() < 100:
			current_state = State.MOVE

	elif current_state == State.MOVE:
		if position.distance_squared_to(waypoint) < 500:
			waypoint = select_destination(1, 6, 1, 2, 128)
		else:
			velocity = lerp(velocity, position.direction_to(waypoint) * speed, 0.25)

		
	if can_shoot:
		shoot()	
			
	move_and_slide()

func shoot():
	if !check_linesight(body) or Globals.player.dead:
		return

	var bullet : Bullet = bullet_scene.instantiate() as Bullet
	bullet.damage = power
	bullet.rotation = muzzles[current_muzzle].global_rotation
	bullet_fired.emit(bullet, muzzles[current_muzzle].global_position)
	can_shoot = false
	shoot_timer.start(fire_interval * 0.5)
	current_muzzle = wrapi(current_muzzle + 1, 0, 2)	


				
func apply_color_palette():
	primary_color = Globals.color_palettes[Globals.current_palette][5]
	secondary_color = Globals.color_palettes[Globals.current_palette][3]
	
	body.self_modulate = primary_color
	chasis.self_modulate = secondary_color
	
	for cannon : Sprite2D in get_tree().get_nodes_in_group("Cannons"):
		cannon.self_modulate = Globals.color_palettes[Globals.current_palette][2]

func add_swarm():
	if !is_inside_tree() or Globals.player.dead:
		return
	await get_tree().create_timer(1.0).timeout
	swarmlings_spawned = randi_range(6, 8)
	for i in swarmlings_spawned:
		var enemy : SwarmEnemy = swarm_enemy_scene.instantiate() as SwarmEnemy
		enemy.position = get_parent().to_local(swarm_spot.global_position + Vector2.RIGHT.rotated(randf() * TAU) * 8)
		enemy.target = Globals.player
		enemy.tree_exited.connect(_on_swarmling_killed)
		
		get_parent().call_deferred("add_child", enemy)
	if !is_inside_tree():
		return	
	await get_tree().create_timer(1.0).timeout
	shoot_timer.start(randf_range(1.0, 1.5))
	body.region_rect.position.x = 0	
	current_state = State.MOVE
	timer.start(randf_range(5, 7))

func knockback(dir : Vector2):
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(body, "self_modulate", Color.WHITE, 0.1)
	tw.parallel().tween_property(chasis, "self_modulate", Color.WHITE, 0.1)
	tw.tween_interval(0.1)
	tw.tween_property(body, "self_modulate",primary_color, 0.1)
	tw.parallel().tween_property(chasis, "self_modulate", secondary_color, 0.1)

	if current_state != State.DEPLOY:
		velocity = dir * speed * 1.25
		current_state = State.KNOCKBACK

func check_linesight(origin : Node2D):
	var shape : RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(640, 48)
	var query : PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = origin.global_transform.translated(origin.global_transform.x * 320)	
	query.collision_mask = 4096
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var state : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	
	var result : Array[Dictionary] = state.intersect_shape(query)
	
	if result.size() > 0:
		var closest_dist : float = INF
		for hit_result : Dictionary in result:
			var dist : float = global_position.distance_squared_to(hit_result.collider.global_position)
			if dist < closest_dist:
				closest_dist = dist
		if global_position.distance_squared_to(Globals.player.global_position) > closest_dist:
			return false
		else:
			return true
	else:
		return true
	

func _on_swarmling_killed():
	swarmlings_spawned -= 1

		
func _on_shoot_timer_timeout() -> void:
	can_shoot = true



func _on_timer_timeout() -> void:
	if attack_mode == AttackMode.BULLET:
		can_shoot = false
		shoot_timer.stop()
		if randf() < 0.33:
			shoot_timer.start(randf_range(1.0, 1.5))
			timer.start(shoot_timer.time_left + randf_range(5, 7))
		else:
			body.region_rect.position.x = 32
			current_state = State.DEPLOY
			velocity = Vector2.ZERO
			add_swarm()
		
		
