extends Boss
class_name FirstGuardian

@onready var timer: Timer = $Timer
@onready var shoot_timer: Timer = $ShootTimer
@onready var body: Sprite2D = $Body
@onready var chasis: Sprite2D = $Body/Chasis
@onready var muzzle_pivot: Marker2D = $MuzzlePivot
@onready var sides: Sprite2D = $Body/Sides

const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")
const missile_scene : PackedScene = preload("res://scenes/missile.tscn")


var current_state : State

var shots_fired : int = 0
var attack_mode : AttackMode
var rotation_dir : int
var rotation_speed : float

enum AttackMode {
	ROTATE,
	PULSE,
	MISSILE
}

enum State {
	MOVE,
	KNOCKBACK
}

signal bullet_fired(bullet : Node2D, pos : Vector2)
signal missile_fired(missile : Node2D, pos : Vector2)


func _ready() -> void:
	setup()
	
	rotation_dir = pow(-1, randi() % 2)
	rotation_speed = randf_range(PI * 1.5, TAU)	
	apply_color_palette()
	place_muzzles()
	
	set_physics_process(false)
	set_process(false)
		
	var tw : Tween = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(body, "modulate:a", 1.0, 1.0)
	await tw.finished
	set_physics_process(true)
	set_process(true)

	current_state = State.MOVE

	
	switch_attack_mode()
	

func place_muzzles():
	var angle_increment : float = TAU / 8
	for i in 8:
		var muzzle : Marker2D = muzzle_pivot.get_child(i)
		muzzle.position = Vector2(30 * cos(angle_increment * i), 30 * sin(angle_increment * i))
		muzzle.rotation = angle_increment * i

func _process(delta: float) -> void:
	if current_state == State.MOVE:
		wander(delta)
			
	health_bar_pivot.global_rotation = 0
	chasis.rotation -= PI * 0.5 * delta
	
	if attack_mode == AttackMode.ROTATE:
		muzzle_pivot.rotation += rotation_speed * rotation_dir * delta

func _physics_process(_delta: float) -> void:
	if current_state == State.KNOCKBACK:
		velocity = lerp(velocity, Vector2.ZERO, 0.15)
		if velocity.length_squared() < 100:
			current_state = State.MOVE

	else:	
		if position.distance_squared_to(waypoint) < 100:
			waypoint = select_destination()

		velocity = lerp(velocity, position.direction_to(waypoint) * speed, 0.25)

	if can_shoot:
		shoot()	
		
	move_and_slide()

func shoot():
	if attack_mode == AttackMode.MISSILE:
		if shots_fired == 3:
			switch_attack_mode()
			return
		var missile : Missile = missile_scene.instantiate()
		var muzzle : Marker2D = find_best_muzzle()
		missile.rotation = muzzle.global_rotation
		missile.power = power * 2
		missile_fired.emit(missile, muzzle.global_position + muzzle.global_transform.x * 8)
		can_shoot = false
		
		shots_fired += 1
		
		if shots_fired == 3:
			fire_interval = 1.0
			
		shoot_timer.start(fire_interval)
				
		
	else:
		if shots_fired == 9:
			switch_attack_mode()
			return
		for i in muzzle_pivot.get_child_count():
			var muzzle : Marker2D = muzzle_pivot.get_child(i)
			var bullet : Node2D = bullet_scene.instantiate()
			bullet.rotation = muzzle.global_rotation
			bullet.speed = min(speed * 3.0, 512)
			bullet.color = Globals.color_palettes[Globals.current_palette][3]
			bullet.damage = power
			if attack_mode == AttackMode.ROTATE:
				bullet.velocity = muzzle.global_transform.y * rotation_speed * 32
			bullet_fired.emit(bullet, muzzle.global_position)
			can_shoot = false
				
		if attack_mode == AttackMode.PULSE:
			shots_fired += 1
			if shots_fired % 3 == 0 and shots_fired < 9:
				fire_interval = 0.5
				shoot_timer.start(fire_interval)
			else:
				fire_interval = max(base_fire_interval - fire_interval_per_level * level, min_fire_interval)
				shoot_timer.start(fire_interval)
		else:
			shoot_timer.start(fire_interval)
		


func find_best_muzzle() -> Marker2D:
	var best_muzzle : Marker2D
	var dir_to_player : Vector2 = global_position.direction_to(Globals.player.global_position)
	var best_dot_product : float = -1.0
	
	for candidate_muzzle : Marker2D in muzzle_pivot.get_children():
		var dir_to_muzzle : Vector2 = global_position.direction_to(candidate_muzzle.global_position)
		var dot_product : float = dir_to_muzzle.dot(dir_to_player)
		
		if dot_product > best_dot_product:
			best_dot_product = dot_product
			best_muzzle = candidate_muzzle 
		
	return best_muzzle

func switch_attack_mode():
	if attack_mode == AttackMode.ROTATE:
		if randf() < 0.5:
			switch_to_pulse_attack()
		else:
			switch_to_missile_attack()

	elif attack_mode == AttackMode.PULSE:
		if randf() < 0.5:
			switch_to_rotate_attack()	
		else:
			switch_to_missile_attack()
			
	elif attack_mode == AttackMode.MISSILE:
		if randf() < 0.5:
			switch_to_rotate_attack()
		else:
			switch_to_pulse_attack()
			
	else:
		var chance : float = randf()
		if chance < 0.33:
			switch_to_rotate_attack()
		elif chance < 0.66:
			switch_to_pulse_attack()
		else:
			switch_to_missile_attack()
			
func switch_to_rotate_attack():
	attack_mode = AttackMode.ROTATE
	rotation_dir = pow(-1, randi() % 2)
	rotation_speed = randf_range(PI * 1.5, TAU)

	fire_interval = max(base_fire_interval - fire_interval_per_level * level, min_fire_interval)
	shots_fired = 0
	shoot_timer.start(fire_interval)
	timer.start(randf_range(1.75, 3.25))

func switch_to_pulse_attack():
	attack_mode = AttackMode.PULSE
	fire_interval = max(base_fire_interval - fire_interval_per_level * level, min_fire_interval)
	shots_fired = 0
	shoot_timer.start(fire_interval)
	
func switch_to_missile_attack():
	attack_mode = AttackMode.MISSILE
	fire_interval = 1.5
	shots_fired = 0
	shoot_timer.start(fire_interval)

func apply_color_palette():
	primary_color = Globals.color_palettes[Globals.current_palette][5]
	secondary_color = Globals.color_palettes[Globals.current_palette][4]
	tertiary_color = Globals.color_palettes[Globals.current_palette][3]
	
	body.self_modulate = primary_color
	chasis.self_modulate = secondary_color
	sides.self_modulate = tertiary_color
	
	for cannon : Sprite2D in get_tree().get_nodes_in_group("Cannons"):
		cannon.self_modulate = Globals.color_palettes[Globals.current_palette][2]

func knockback(dir : Vector2):
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(body, "self_modulate", Color.WHITE, 0.1)
	tw.parallel().tween_property(chasis, "self_modulate", Color.WHITE, 0.1)
	tw.tween_interval(0.1)
	tw.tween_property(body, "self_modulate",primary_color, 0.1)
	tw.parallel().tween_property(chasis, "self_modulate", secondary_color, 0.1)
	tw.parallel().tween_property(sides, "self_modulate", tertiary_color, 0.1)

	velocity = dir * speed * 1.25
	current_state = State.KNOCKBACK
	


func _on_shoot_timer_timeout() -> void:
	can_shoot = true


func _on_timer_timeout() -> void:
	switch_attack_mode()
