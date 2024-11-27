extends Boss
class_name NinthGuardian

@onready var shoot_timer: Timer = $ShootTimer
@onready var body: Sprite2D = $Body
@onready var chasis: Sprite2D = $Body/Chasis
@onready var top: Sprite2D = $Body/Top
@onready var timer: Timer = $Timer


const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")

var current_state : State

var attack_mode : AttackMode

enum AttackMode {
	BULLET,
	LASER,
	CHARGE,
	NONE
}

enum State {
	MOVE,
	KNOCKBACK,
	PREPARE,
	CHARGE,
	REST,
}

var muzzles : Array = []
var lasers : Array = []

var rotation_speed_bullet : float
var rotation_speed_laser : float

var bullet_phase : int = 0

var charge_speed : int

var charge_dir : Vector2

signal bullet_fired(bullet : Node2D, pos : Vector2)


func _ready() -> void:
	setup()
	muzzles = get_tree().get_nodes_in_group("Cannons")
	lasers = get_tree().get_nodes_in_group("Lasers")
	apply_color_palette()
	target = Globals.player
	charge_speed = speed * 3

	rotation_speed_bullet = TAU * 1.5
	rotation_speed_laser = PI * 0.25
	for laser : Laser in lasers:
		laser.shoot_duration = 2.0
	
	var laser : Laser = lasers[0]
	laser.charged.connect(_on_lasers_charged)
	laser.fired.connect(_on_lasers_fired)
	
	set_physics_process(false)
	set_process(false)
		
	var tw : Tween = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(body, "modulate:a", 1.0, 1.0)
	#tw.parallel().tween_property(chasis, "modulate:a", 1.0, 1.0)
	#tw.parallel().tween_property(top, "modulate:a", 1.0, 1.0)
	
	await tw.finished
	set_physics_process(true)
	set_process(true)

	current_state = State.MOVE
	attack_mode = AttackMode.NONE
	change_attack_mode()

	#shoot_timer.start(fire_interval)
	#timer.start(randf_range(3, 5))
	
func place_muzzles():
	var angle_increment : float = TAU / 8
	for i in muzzles.size():
		var muzzle : Marker2D = muzzles[i]
		muzzle.position = Vector2(30 * cos(angle_increment * i), 30 * sin(angle_increment * i))
		muzzle.rotation = angle_increment * i	

func _process(delta: float) -> void:
	health_bar_pivot.global_rotation = 0
	if current_state == State.MOVE:
		elapsed_time += delta
		if elapsed_time > wander_interval:
			waypoint = select_destination(1, 6, 1, 2, 128)
			elapsed_time -= wander_interval
			wander_interval = randf_range(1.25, 2.0)
	
	if attack_mode == AttackMode.BULLET:
		body.rotation += rotation_speed_bullet * delta
	elif attack_mode == AttackMode.LASER:
		body.rotation += rotation_speed_laser * delta
	else:
		body.rotation += rotation_speed_bullet * 2.0 * delta

	rotation_speed_bullet = wrapf(rotation_speed_bullet + 0.015, TAU * 1.5 - 0.2, TAU * 1.5 + 0.2)
	rotation_speed_laser = wrapf(rotation_speed_bullet + 0.015, PI * 0.25 - 0.15, PI * 0.25 + 0.15)
	

func _physics_process(delta: float) -> void:
	if current_state == State.KNOCKBACK:
		velocity = lerp(velocity, Vector2.ZERO, 0.15)
		if velocity.length_squared() < 100:
			current_state = State.MOVE
		move_and_slide()
		
	elif current_state == State.MOVE:
		if position.distance_squared_to(waypoint) < 500:
			waypoint = select_destination(1, 6, 1, 2, 128)
		else:
			velocity = lerp(velocity, position.direction_to(waypoint) * speed, 0.25)

		move_and_slide()
	
	elif current_state == State.PREPARE:
		if is_instance_valid(target):
			charge_dir = global_position.direction_to(target.global_position)
	
	elif current_state == State.CHARGE:
		velocity = lerp(velocity, charge_dir * charge_speed, 0.09)
		
		var collision : KinematicCollision2D = move_and_collide(velocity * delta)
		if collision:
			velocity = Vector2.ZERO
			current_state = State.REST
			power -= 5
			timer.start(1.0)
		
	if can_shoot:
		
		shoot()	
			

func shoot():
	if Globals.player.dead:
		return


	for i in muzzles.size():
		var bullet : Bullet = bullet_scene.instantiate() as Bullet
		bullet.color = Globals.color_palettes[Globals.current_palette][0]
		bullet.damage = power
		bullet.rotation = muzzles[i].global_rotation
		bullet_fired.emit(bullet, muzzles[i].global_position)
		muzzles[i].rotation = i * PI * 0.5 + randf_range(-PI / 4, PI / 4)
	
	bullet_phase += 1	
	can_shoot = false
	shoot_timer.start(fire_interval)


				
func apply_color_palette():
	primary_color = Globals.color_palettes[Globals.current_palette][5]
	secondary_color = Globals.color_palettes[Globals.current_palette][3]
	tertiary_color = Globals.color_palettes[Globals.current_palette][4]
	
	body.self_modulate = primary_color
	chasis.self_modulate = secondary_color
	top.self_modulate = tertiary_color
	
	for muzzle in muzzles:
		muzzle.get_child(0).self_modulate = Globals.color_palettes[Globals.current_palette][1]
	for laser in lasers:
		laser.get_child(0).self_modulate = Globals.color_palettes[Globals.current_palette][1]

func knockback(dir : Vector2):
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(body, "self_modulate", Color.WHITE, 0.1)
	tw.parallel().tween_property(chasis, "self_modulate", Color.WHITE, 0.1)
	tw.parallel().tween_property(top, "self_modulate", Color.WHITE, 0.1)
	tw.tween_interval(0.1)
	tw.tween_property(body, "self_modulate",primary_color, 0.1)
	tw.parallel().tween_property(chasis, "self_modulate", secondary_color, 0.1)
	tw.parallel().tween_property(top, "self_modulate", tertiary_color, 0.1)
	
	if current_state != State.CHARGE and current_state != State.PREPARE and current_state != State.REST:
		velocity = dir * speed * 1.25
		current_state = State.KNOCKBACK


func change_attack_mode():
	can_shoot = false
	shoot_timer.stop()
	
	if attack_mode == AttackMode.BULLET:
		var tw : Tween = create_tween()
		tw.set_parallel()
		for muzzle : Marker2D in muzzles:
			tw.tween_property(muzzle.get_child(0), "modulate:a", 0.0, 0.25)
		await tw.finished
		
	elif attack_mode == AttackMode.LASER:
		var tw : Tween = create_tween()
		tw.set_parallel()
		for laser : Marker2D in lasers:
			tw.tween_property(laser.get_node("Sprite2D"), "modulate:a", 0.0, 0.25)
		await tw.finished		
	
	var roll : float = randf()
	if roll < 0.7:
		switch_to_bullet_attack()
	elif roll < 0.9:
		switch_to_laser_attack()
	elif attack_mode != AttackMode.CHARGE:
		current_state = State.PREPARE
		attack_mode = AttackMode.CHARGE
		velocity = Vector2.ZERO
		timer.start(0.15)
	else:
		switch_to_bullet_attack()
	
func switch_to_bullet_attack():
	attack_mode = AttackMode.BULLET
	var tw : Tween = create_tween()
	tw.set_parallel()
	for muzzle : Marker2D in muzzles:
		tw.tween_property(muzzle.get_child(0), "modulate:a", 1.0, 0.75)
	await tw.finished
	shoot_timer.start(fire_interval + 0.25)
	timer.start(randf_range(3, 5))
	
func switch_to_laser_attack():
	attack_mode = AttackMode.LASER
	var tw : Tween = create_tween()
	tw.set_parallel()	
	for laser : Laser in lasers:
		tw.tween_property(laser.get_node("Sprite2D"), "modulate:a", 1.0, 0.75)
	await tw.finished		
	for laser : Laser in lasers:
		laser.charge_beam()

		
func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func _on_timer_timeout() -> void:
	if current_state == State.PREPARE:
		current_state = State.CHARGE
		power += 5
		
	elif current_state == State.REST:
		current_state = State.MOVE
		change_attack_mode()
		
	elif current_state == State.MOVE or current_state == State.KNOCKBACK:
		change_attack_mode()
		
func _on_lasers_charged():
	for laser : Laser in lasers:
		laser.fire()

func _on_lasers_fired():
	change_attack_mode()
