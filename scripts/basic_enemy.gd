extends Enemy

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer
@onready var shoot_timer: Timer = $ShootTimer
@onready var body: Sprite2D = $Body
@onready var indicator: Sprite2D = $Indicator
@onready var chasis: Sprite2D = $Body/Chasis

const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")

var elapsed_time : float = 0.0
var can_shoot : bool = true

signal bullet_fired(bullet : Node2D, pos : Vector2)

var tick : int = 0

func _ready() -> void:
	apply_color_palette()
	set_physics_process(false)
	set_process(false)
	$Hitbox.deactivate()
	var tw : Tween = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(indicator, "modulate:a", 0.65, 0.25)
	tw.parallel().tween_property(indicator, "scale", Vector2.ONE, 0.25)
	tw.tween_property(indicator, "modulate:a", 0.0, 0.125)
	tw.parallel().tween_property(indicator, "scale", Vector2.ZERO, 0.25)
	tw.tween_interval(0.25)
	tw.tween_property(body, "modulate:a", 1.0, 0.5)
	#tw.parallel().tween_property(chasis, "modulate:a", 1.0, 0.5)
	tw.tween_interval(0.15)
	await tw.finished
	$Hitbox.activate()
	set_physics_process(true)
	set_process(true)
	timer.start()

func _process(_delta: float) -> void:
	tick += 1
	if tick % 4 == 0 and target:
		nav_agent.target_position = target.global_position
		

func _physics_process(_delta: float) -> void:
	if nav_agent.is_navigation_finished() or !target:
		velocity = lerp(velocity, Vector2.ZERO, 0.1)
		move_and_slide()
		return
	
	if global_position.distance_squared_to(target.global_position) > 900:
		var intended_velocity : Vector2 = global_position.direction_to(nav_agent.get_next_path_position()) * speed
		nav_agent.set_velocity(intended_velocity)
#
	elif global_position.distance_squared_to(target.global_position) < 400:
		var intended_velocity : Vector2 = global_position.direction_to(target.global_position) * -speed * 3.0
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
	
	query = PhysicsRayQueryParameters2D.create(global_position - global_transform.y * 3, global_position - global_transform.y * 3 + global_transform.x * 500, 7)
	
	result = state.intersect_ray(query)	
	if result and result.collider.collision_layer != 1:
		return
		
	query = PhysicsRayQueryParameters2D.create(global_position + global_transform.y * 3, global_position + global_transform.y * 3 + global_transform.x * 500, 7)
	
	result = state.intersect_ray(query)	
	if result and result.collider.collision_layer != 1:
		return
			
	var bullet : Node2D = bullet_scene.instantiate()
	bullet.rotation = global_rotation
	
	bullet_fired.emit(bullet, global_position + global_transform.x * 12)
	can_shoot = false
	shoot_timer.start()

func apply_color_palette():
	body.self_modulate = Globals.color_palettes[Globals.current_palette][2]
	chasis.self_modulate = Globals.color_palettes[Globals.current_palette][3]
	indicator.self_modulate = Globals.color_palettes[Globals.current_palette][2]

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = lerp(velocity, safe_velocity, 0.25)
	if safe_velocity != Vector2.ZERO:
		rotation = velocity.angle()
	elif is_instance_valid(target):
		var target_transform = global_transform.looking_at(target.global_position)
		global_transform = global_transform.interpolate_with(target_transform, 0.75)
		
	move_and_slide()


func _on_timer_timeout() -> void:
	if target:
		nav_agent.target_position = target.global_position


func _on_shoot_timer_timeout() -> void:
	can_shoot = true
