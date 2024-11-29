extends Enemy
class_name BasicEnemyTitleScreen

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer
@onready var shoot_timer: Timer = $ShootTimer
@onready var body: AnimatedSprite2D = $Body
@onready var chasis: Sprite2D = $Body/Chasis

const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")
const explosion_scene : PackedScene = preload("res://scenes/explosion.tscn")


var enemies : Array[Enemy]

var elapsed_time : float = 0.0

var tick : int = 0

var current_state : State
var previous_state : State

var wander_ratio : float
var idle_chance : float

var steering_force : float = 0.15

enum State {
	IDLE,
	CRUISE,
	BATTLE,
	KNOCKBACK
}

signal bullet_fired(bullet : Node2D, pos : Vector2)

func _ready() -> void:
	setup()
	
	apply_color_palette()
	set_physics_process(false)
	set_process(false)	
	var tw : Tween = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(body, "modulate:a", 1.0, 1.0)
	await tw.finished
	tw = create_tween()
	tw.tween_interval(0.15)
	await tw.finished
	set_physics_process(true)
	set_process(true)
	body.play("walk")
	wander_ratio = randf_range(1.0, 2.0)
	idle_chance = randf_range(0.1, 0.2)
	shoot_timer.start(fire_interval)
	current_state = State.CRUISE

func level_up():
	await get_tree().create_timer(0.1).timeout
	level += 1
	steering_force += 0.05
	secondary_color = Globals.color_palettes[Globals.current_palette][5]
	chasis.self_modulate = secondary_color
	setup()
	health_bar.hide()
	current_state = State.CRUISE

func set_target():
	if enemies.size() < 2:
		return
	if randf() < 0.5:
		var min_dist : float = 100000000
		var closest_enemy : Enemy
		for enemy in enemies:
			if enemy == self:
				continue
			var dist : float = global_position.distance_squared_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_enemy = enemy
				
		target = closest_enemy
	else:
		target = enemies.pick_random()
		while target == self:
			target = enemies.pick_random()
			
	current_state = State.BATTLE

func _process(delta: float) -> void:
	if current_state == State.BATTLE:
		elapsed_time += delta
		if elapsed_time >= 0.05 and is_instance_valid(target):
			nav_agent.target_position = target.global_position
			elapsed_time -= 0.05
	elif current_state == State.CRUISE:
		elapsed_time += delta
		if elapsed_time > wander_ratio:
			if randf() < idle_chance:
				current_state = State.IDLE
				elapsed_time = 0
			else:
				nav_agent.target_position = Vector2i(32, 32) + Utils.get_random_coords(0, 10, 0, 5) * 64
				elapsed_time -= wander_ratio
				
	elif current_state == State.IDLE:
		elapsed_time += delta
		if elapsed_time > 0.3:
			elapsed_time = 0
			current_state = State.CRUISE
	
	health_bar_pivot.global_rotation = 0	

func _physics_process(_delta: float) -> void:
	if current_state == State.KNOCKBACK:
		velocity = lerp(velocity, Vector2.ZERO, 0.15)
		if velocity.length_squared() < 100:
			elapsed_time = 0.0
			current_state = previous_state
		else:
			move_and_slide()
	elif current_state == State.BATTLE:
		if nav_agent.is_navigation_finished() or !is_instance_valid(target):
			velocity = lerp(velocity, Vector2.ZERO, 0.1)
			
		elif global_position.distance_squared_to(target.global_position) > 2500:
			var intended_velocity : Vector2 = global_position.direction_to(nav_agent.get_next_path_position()) * speed
			nav_agent.set_velocity(intended_velocity)
	#
		elif global_position.distance_squared_to(target.global_position) < 1600:
			
			if check_linesight():
				var intended_velocity : Vector2 = global_position.direction_to(nav_agent.get_next_path_position()) * speed
				nav_agent.set_velocity(intended_velocity)
			else:
				var intended_velocity : Vector2 = global_position.direction_to(target.global_position) * -speed * 3.0
				nav_agent.set_velocity(intended_velocity)
			
		else:
			var intended_velocity : Vector2  = global_transform.x * 0.0
			nav_agent.set_velocity(intended_velocity)


		if can_shoot and global_transform.x.dot(global_position.direction_to(target.global_position)) > 0.98:
			shoot()
	elif current_state == State.CRUISE:
		var intended_velocity : Vector2 = global_position.direction_to(nav_agent.get_next_path_position()) * speed
		nav_agent.set_velocity(intended_velocity)
		
	else:
		velocity = lerp(velocity, Vector2.ZERO, 0.5)
			
func shoot():	
	var bullet : Node2D = bullet_scene.instantiate()
	bullet.rotation = global_rotation
	bullet.speed = min(speed * 3.0, 512)
	bullet.color = body.self_modulate
	bullet.damage = power
	bullet_fired.emit(bullet, global_position + global_transform.x * 12)
	can_shoot = false
	shoot_timer.start(fire_interval)
	#SoundManager.play_effect(SoundManager.Effects.ENEMY_SHOOT)


func check_linesight() -> bool:
	var query : PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, global_position + global_position.direction_to(target.global_position)  * 32, 4)
	var state : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	
	var result : Dictionary = state.intersect_ray(query)
	if result:
		return true
		
	return false

func take_damage(amount : int, dir : Vector2):
	if dead:
		return
	hp -= amount
	if hp <= 0:
		dead = true
		explode(dir)
		destroyed.emit(self)
		queue_free()
	else:
		health_bar.show()
		health_bar.value = hp
		health_bar.tint_progress = Globals.color_palettes[Globals.current_palette][3]
		knockback(dir)	

func apply_color_palette():
	primary_color = Globals.color_palettes[Globals.current_palette][2]
	if level == 0:
		secondary_color = Globals.color_palettes[Globals.current_palette][3]
	else:
		secondary_color = Globals.color_palettes[Globals.current_palette][5]
	body.self_modulate = primary_color
	chasis.self_modulate = secondary_color

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if current_state != State.BATTLE and current_state != State.CRUISE:
		return
	velocity = lerp(velocity, safe_velocity, steering_force)
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
	tw.tween_interval(0.1)
	tw.tween_property(body, "self_modulate", primary_color, 0.1)
	tw.parallel().tween_property(chasis, "self_modulate", secondary_color, 0.1)
	
	velocity = dir * speed * 1.25
	previous_state = current_state
	current_state = State.KNOCKBACK


func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func explode(_dir : Vector2):
	var explosion : Explosion = explosion_scene.instantiate()
	var colors : Array[Color] = [primary_color, secondary_color]
		
	explosion.initialize(Vector2.ZERO, colors)
	exploded.emit(explosion, global_position)
