extends Boss
class_name FourthGuardian

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer
@onready var shoot_timer: Timer = $ShootTimer
@onready var base: Sprite2D = $Base
@onready var middle: Sprite2D = $Middle
@onready var turret: Sprite2D = $Turret
@onready var top: Sprite2D = $Turret/Top

@onready var muzzle_1: Marker2D = $Turret/Muzzle1
@onready var muzzle_2: Marker2D = $Turret/Muzzle2
@onready var missile_muzzle_1: Marker2D = $Turret/MissileMuzzle1
@onready var missile_muzzle_2: Marker2D = $Turret/MissileMuzzle2
@onready var lasers: Node2D = $Base/Lasers


const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")
const missile_scene : PackedScene = preload("res://scenes/missile.tscn")

var current_state : State

var shots_fired : int = 0
var attack_mode : AttackMode
var rotation_dir : int
var rotation_speed : float


enum AttackMode {
	BULLET,
	LASER,
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
	target = Globals.player
	for laser : Laser in lasers.get_children():
		laser.shoot_duration = 5.0
		laser.power = power
		
	
	apply_color_palette()
	
	set_physics_process(false)
	set_process(false)
		
	var tw : Tween = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(base, "modulate:a", 1.0, 1.0)
	tw.parallel().tween_property(middle, "modulate:a", 1.0, 1.0)
	tw.parallel().tween_property(turret, "modulate:a", 1.0, 1.0)
	await tw.finished
	set_physics_process(true)
	set_process(true)

	current_state = State.MOVE

	wander_interval = randf_range(1.25, 1.75)
	switch_attack_mode()


func _process(delta: float) -> void:
	health_bar_pivot.global_rotation = 0
	if !is_instance_valid(target):
		return
	if current_state == State.MOVE:
		wander(delta)
	
		var target_transform = turret.global_transform.looking_at(target.global_position)
		turret.global_transform = turret.global_transform.interpolate_with(target_transform, 0.25)		
	
	if attack_mode == AttackMode.LASER:
		base.rotation += rotation_speed * rotation_dir * delta


func _physics_process(_delta: float) -> void:
	if current_state == State.KNOCKBACK:
		velocity = lerp(velocity, Vector2.ZERO, 0.15)
		if velocity.length_squared() < 100:
			current_state = State.MOVE

	else:	
		if position.distance_squared_to(waypoint) < 500:
			waypoint = select_destination()

		velocity = lerp(velocity, position.direction_to(waypoint) * speed, 0.25)

	if can_shoot:
		shoot()	
	
	if attack_mode != AttackMode.LASER:	
		move_and_slide()

func shoot():
	if attack_mode == AttackMode.BULLET:
		var bullet : Bullet = bullet_scene.instantiate()
		bullet.rotation = muzzle_1.global_rotation
		bullet.damage = power
		bullet.speed = 448
		bullet_fired.emit(bullet, muzzle_1.global_position)
		
		bullet = bullet_scene.instantiate()
		bullet.rotation = muzzle_2.global_rotation
		bullet.damage = power
		bullet.speed = 448
		bullet_fired.emit(bullet, muzzle_2.global_position)
		can_shoot = false
		shoot_timer.start(fire_interval)
		
		SoundManager.play_effect(SoundManager.Effects.ENEMY_SHOOT)
	
	elif attack_mode == AttackMode.MISSILE:
		var missile : Missile = missile_scene.instantiate()
		var selected_muzzle : Marker2D = [missile_muzzle_1, missile_muzzle_2].pick_random()
		missile.power = power * 2
		missile.level = level
		missile.rotation = selected_muzzle.global_rotation
		missile_fired.emit(missile, selected_muzzle.global_position)
		shots_fired += 1
		if shots_fired == 4:
			switch_attack_mode()
		else:
			can_shoot = false
			shoot_timer.start(fire_interval)

func switch_attack_mode():
	if attack_mode == AttackMode.LASER:
		if randf() < 0.5:
			switch_to_bullet_attack()
		else:
			switch_to_missile_attack()

	elif attack_mode == AttackMode.BULLET:
		if randf() < 0.5:
			switch_to_laser_attack()	
		else:
			switch_to_missile_attack()
			
	elif attack_mode == AttackMode.MISSILE:
		if randf() < 0.5:
			switch_to_laser_attack()
		else:
			switch_to_bullet_attack()
			
	else:
		var chance : float = randf()
		if chance < 0.33:
			switch_to_laser_attack()
		elif chance < 0.66:
			switch_to_bullet_attack()
		else:
			switch_to_missile_attack()
			
func switch_to_laser_attack():
	attack_mode = AttackMode.LASER
	rotation_dir = pow(-1, randi() % 2)
	rotation_speed = randf_range(PI * 0.25, PI * 0.33)

	fire_interval = 0.25
	shots_fired = 0
	var duration : float = randf_range(3.0, 5.0)

	for laser : Laser in lasers.get_children():
		laser.shoot_duration = duration
		laser.charge_beam()

func switch_to_bullet_attack():
	attack_mode = AttackMode.BULLET
	fire_interval = 0.15
	shoot_timer.start(fire_interval * 3)
	timer.start(randf_range(2.5, 4.5))
	
func switch_to_missile_attack():
	attack_mode = AttackMode.MISSILE
	fire_interval = 1.5
	shots_fired = 0
	shoot_timer.start(fire_interval)

func apply_color_palette():
	primary_color = Globals.color_palettes[Globals.current_palette][5]
	secondary_color = Globals.color_palettes[Globals.current_palette][4]
	tertiary_color = Globals.color_palettes[Globals.current_palette][2]
	
	base.self_modulate = primary_color
	middle.self_modulate = secondary_color
	turret.self_modulate = tertiary_color
	
	top.self_modulate = Globals.color_palettes[Globals.current_palette][6]
	
	for cannon : Sprite2D in get_tree().get_nodes_in_group("Cannons"):
		cannon.self_modulate = Globals.color_palettes[Globals.current_palette][2]

func knockback(dir : Vector2):
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(base, "self_modulate", Color.WHITE, 0.1)
	tw.parallel().tween_property(turret, "self_modulate", Color.WHITE, 0.1)
	tw.tween_interval(0.15)
	tw.tween_property(base, "self_modulate",primary_color, 0.1)
	tw.parallel().tween_property(turret, "self_modulate", tertiary_color, 0.1)

	velocity = dir * speed * 1.25
	current_state = State.KNOCKBACK

func _on_shoot_timer_timeout() -> void:
	can_shoot = true


func _on_timer_timeout() -> void:
	switch_attack_mode()


func _on_laser_charged() -> void:
	for laser : Laser in lasers.get_children():
		laser.fire()


func _on_laser_fired() -> void:
	switch_attack_mode()
