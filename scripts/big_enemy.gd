extends Enemy
class_name BigEnemy

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var body: Sprite2D = $Body
@onready var chasis: Sprite2D = $Body/Chasis
@onready var sides: Sprite2D = $Body/Sides

const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")

var elapsed_time : float = 0.0
var can_shoot : bool = true

signal bullet_fired(bullet : Node2D, pos : Vector2)

var tick : int = 0

var current_state : State

enum State {
	MOVE,
	KNOCKBACK
}


func _ready() -> void:
	apply_color_palette()
	set_physics_process(false)
	set_process(false)
	$Hitbox.deactivate()
	var tw : Tween = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(body, "modulate:a", 1.0, 0.5)
	await tw.finished
	$Hitbox.activate()
	tw = create_tween()
	tw.tween_interval(0.15)
	await tw.finished
	set_physics_process(true)
	set_process(true)
	hp = min(6 + level * 2, 16)
	fire_interval = max(1.5 - 0.15 * level, 0.8)
	speed = mini(72 + level * 16, 128)	
	current_state = State.MOVE
	shoot_timer.start(fire_interval)

func _process(_delta: float) -> void:
	if current_state == State.MOVE:
		tick += 1
		if tick % 2 == 0 and target:
			nav_agent.target_position = target.global_position
		
func _physics_process(delta: float) -> void:
	if current_state == State.KNOCKBACK:
		velocity = lerp(velocity, Vector2.ZERO, 0.1)
		if velocity.length_squared() < 25:
			current_state = State.MOVE
		else:
			move_and_slide()
		if can_shoot and global_transform.x.dot(global_position.direction_to(target.global_position)) > 0.99:
			shoot()	
	else:	
		if nav_agent.is_navigation_finished() or !target:
			velocity = lerp(velocity, Vector2.ZERO, 0.1)
			move_and_slide()
			if can_shoot and global_transform.x.dot(global_position.direction_to(target.global_position)) > 0.99:
				shoot()	
			return
		
		if global_position.distance_squared_to(target.global_position) > 900:
			var intended_velocity : Vector2 = global_position.direction_to(nav_agent.get_next_path_position()) * speed
			nav_agent.set_velocity(intended_velocity)
	#
		elif global_position.distance_squared_to(target.global_position) < 400:
			var intended_velocity : Vector2
			if check_linesight():
				intended_velocity = global_position.direction_to(nav_agent.get_next_path_position()) * speed
			else:
				intended_velocity = global_position.direction_to(target.global_position) * -speed * 3.0
			nav_agent.set_velocity(intended_velocity)
			
		else:
			var intended_velocity : Vector2 = global_transform.x * 0.0
			nav_agent.set_velocity(intended_velocity)


		if can_shoot and global_transform.x.dot(global_position.direction_to(target.global_position)) > 0.99:
			shoot()	

func shoot():
	var query : PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, global_position + global_transform.x * 500, 7)
	var state : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	
	var result : Dictionary = state.intersect_ray(query)	
	if result and result.collider.collision_layer != 1:
			return
	
	query = PhysicsRayQueryParameters2D.create(global_position - global_transform.y * 8, global_position - global_transform.y * 3 + global_transform.x * 500, 7)
	
	result = state.intersect_ray(query)	
	if result and result.collider.collision_layer != 1:
		return
		
	query = PhysicsRayQueryParameters2D.create(global_position + global_transform.y * 8, global_position + global_transform.y * 3 + global_transform.x * 500, 7)
	
	result = state.intersect_ray(query)	
	if result and result.collider.collision_layer != 1:
		return
			
	var bullet : Node2D = bullet_scene.instantiate()
	bullet.rotation = global_rotation
	bullet.damage = power
	bullet.speed = speed * 3.0
	bullet.color = body.self_modulate	
	bullet_fired.emit(bullet, global_position + global_transform.x * 16 + global_transform.y * 8)
	bullet = bullet_scene.instantiate()
	bullet.rotation = global_rotation
	bullet.damage = power
	bullet.speed = speed * 3.0
	bullet.color = body.self_modulate	
	bullet_fired.emit(bullet, global_position + global_transform.x * 16 - global_transform.y * 8)
	
	can_shoot = false
	shoot_timer.start()


func check_linesight() -> bool:
	var query : PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, global_position + global_position.direction_to(target.global_position)  * 32, 4)
	var state : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	
	var result : Dictionary = state.intersect_ray(query)
	if result:
		return true
		
	return false

func apply_color_palette():
	body.self_modulate = Globals.color_palettes[Globals.current_palette][3]
	chasis.self_modulate = Globals.color_palettes[Globals.current_palette][4]
	sides.self_modulate = Globals.color_palettes[Globals.current_palette][2]

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if current_state != State.MOVE:
		return
	velocity = safe_velocity
	if safe_velocity != Vector2.ZERO:
		rotation = velocity.angle()
	elif is_instance_valid(target):
		var target_transform = global_transform.looking_at(target.global_position)
		global_transform = global_transform.interpolate_with(target_transform, 0.75)
		
	move_and_slide()

func knockback(dir : Vector2):
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(body, "self_modulate", Color.WHITE, 0.1)
	tw.parallel().tween_property(chasis, "self_modulate", Color.WHITE, 0.1)
	tw.parallel().tween_property(sides, "self_modulate", Color.WHITE, 0.1)
	tw.tween_property(body, "self_modulate", Globals.color_palettes[Globals.current_palette][3], 0.1)
	tw.parallel().tween_property(chasis, "self_modulate", Globals.color_palettes[Globals.current_palette][4], 0.1)
	tw.parallel().tween_property(sides, "self_modulate", Globals.color_palettes[Globals.current_palette][2], 0.1)

	velocity = dir * speed
	current_state = State.KNOCKBACK
	if target:
		nav_agent.target_position = target.global_position


func _on_shoot_timer_timeout() -> void:
	can_shoot = true
