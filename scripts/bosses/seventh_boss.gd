extends Boss
class_name SeventhGuardian

@onready var shoot_timer: Timer = $ShootTimer
@onready var body: Sprite2D = $Body
@onready var chasis: Sprite2D = $Chasis
@onready var muzzle_pivot: Marker2D = $MuzzlePivot
@onready var top: Sprite2D = $Top
@onready var laser: Laser = $MuzzlePivot/Sprite2D/Laser
@onready var missile_muzzle_2: Marker2D = $MuzzlePivot/Sprite2D2/MissileMuzzle2
@onready var missile_muzzle: Marker2D = $MuzzlePivot/Sprite2D3/MissileMuzzle


const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")
const missile_scene : PackedScene = preload("res://scenes/missile.tscn")

var tick : int = 0

var current_state : State

var shots_fired : int = 0
var attack_mode : AttackMode
var rotation_dir : int
var rotation_speed : float

var consecutive_rockets : int = 0

var last_attacks : Array[AttackMode] = []

enum AttackMode {
	LASER,
	MISSILE
}

enum State {
	MOVE,
	KNOCKBACK,
	CHARGE,
	FIRE_LASER
}

signal missile_fired(missile : Node2D, pos : Vector2)


func _ready() -> void:
	setup()
	rotation_dir = 1 if randf() < 0.5 else -1
	rotation_speed = randf_range(PI * 1.5, TAU)	
	apply_color_palette()
	laser.power = power
	target = Globals.player
		
	set_physics_process(false)
	set_process(false)
		
	var tw : Tween = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(body, "modulate:a", 1.0, 1.0)
	tw.parallel().tween_property(chasis, "modulate:a", 1.0, 1.0)
	tw.parallel().tween_property(top, "modulate:a", 1.0, 1.0)
	tw.parallel().tween_property(muzzle_pivot, "modulate:a", 1.0, 1.0)
	await tw.finished
	set_physics_process(true)
	set_process(true)

	current_state = State.MOVE
	shoot_timer.start(fire_interval)
	

func _process(delta: float) -> void:
	health_bar_pivot.global_rotation = 0
	if current_state == State.MOVE:
		elapsed_time += delta
		if elapsed_time > wander_interval:
			waypoint = select_destination(1, 6, 1, 2, 128)
			elapsed_time -= wander_interval
			wander_interval = randf_range(1.25, 2.0)

	chasis.rotation -= rotation_dir * rotation_speed * delta
	body.rotation += rotation_dir * rotation_speed * delta
	
	if is_instance_valid(target) and !target.dead and current_state != State.FIRE_LASER:
		var target_transform : Transform2D = muzzle_pivot.global_transform.looking_at(target.global_position)
		muzzle_pivot.global_transform = muzzle_pivot.global_transform.interpolate_with(target_transform, 0.5)


func _physics_process(_delta: float) -> void:
	if current_state == State.KNOCKBACK:
		velocity = lerp(velocity, Vector2.ZERO, 0.15)
		if velocity.length_squared() < 100:
			current_state = State.MOVE

	else:
		if position.distance_squared_to(waypoint) < 500:
			waypoint = select_destination(1, 6, 1, 2, 128)
		else:
			velocity = lerp(velocity, position.direction_to(waypoint) * speed, 0.25)

			move_and_slide()

func shoot():
	var missile : Missile = missile_scene.instantiate() as Missile
	missile.power = power
	missile.rotation = missile_muzzle.global_rotation
	missile_fired.emit(missile, missile_muzzle.global_position)
	
	missile = missile_scene.instantiate() as Missile
	missile.power = power
	missile.rotation = missile_muzzle_2.global_rotation
	missile_fired.emit(missile, missile_muzzle_2.global_position)
	
	shoot_timer.start(fire_interval)


func laser_attack():
		laser.charge_beam()
		current_state = State.CHARGE
		last_attacks.append(AttackMode.LASER)
		if last_attacks.size() > 3:
			last_attacks.pop_front()	
				
func apply_color_palette():
	primary_color = Globals.color_palettes[Globals.current_palette][5]
	secondary_color = Globals.color_palettes[Globals.current_palette][4]
	tertiary_color = Globals.color_palettes[Globals.current_palette][3]
	
	body.self_modulate = primary_color
	chasis.self_modulate = secondary_color
	top.self_modulate = tertiary_color
	
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
	tw.parallel().tween_property(top, "self_modulate", tertiary_color, 0.1)

	if current_state != State.CHARGE and current_state != State.FIRE_LASER:
		velocity = dir * speed * 1.25
		current_state = State.KNOCKBACK
	
func _on_shoot_timer_timeout() -> void:
	if randf() < 0.75:
		if last_attacks == [AttackMode.MISSILE, AttackMode.MISSILE, AttackMode.MISSILE]:
			laser_attack()
		else:
			last_attacks.append(AttackMode.MISSILE)
			if last_attacks.size() > 3:
				last_attacks.pop_front()		
			shoot()
	else:
		laser_attack()

func _on_laser_charged() -> void:
	laser.fire()
	current_state = State.FIRE_LASER


func _on_laser_fired() -> void:
	current_state = State.MOVE
	shoot_timer.start(fire_interval)
