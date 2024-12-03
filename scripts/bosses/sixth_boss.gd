extends Boss
class_name SixthGuardian

@onready var timer: Timer = $Timer
@onready var shoot_timer: Timer = $ShootTimer
@onready var body_lower: Sprite2D = $BodyLower
@onready var body_upper: Sprite2D = $BodyLower/BodyUpper
@onready var top: Sprite2D = $BodyLower/Top
@onready var main_pivot: Marker2D = $MainPivot
@onready var pivot_1: Marker2D = $MainPivot/Pivot1
@onready var pivot_2: Marker2D = $MainPivot/Pivot2
@onready var pivot_3: Marker2D = $MainPivot/Pivot3
@onready var pivot_4: Marker2D = $MainPivot/Pivot4
@onready var sub_pivot_1: Marker2D = $MainPivot/Pivot1/SubPivot1
@onready var sub_pivot_2: Marker2D = $MainPivot/Pivot2/SubPivot2
@onready var sub_pivot_3: Marker2D = $MainPivot/Pivot3/SubPivot3
@onready var sub_pivot_4: Marker2D = $MainPivot/Pivot4/SubPivot4


const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")

var tick : int = 0

var current_state : State
var previous_state : State

var charge_speed : int
var charge_dir : Vector2
var initial_power : int

var rotation_speed : float
var rotation_dir : int

var attack_mode : AttackMode

enum State {
	MOVE,
	PREPARE,
	KNOCKBACK
}

enum AttackMode {
	ROTATE,
	MASSIVE
}

signal bullet_fired(bullet : Node2D, pos : Vector2)


func _ready() -> void:
	setup()
	apply_color_palette()
	initial_power = power
	set_physics_process(false)
	set_process(false)
		
	var tw : Tween = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(body_lower, "modulate:a", 1.0, 1.0)
	tw.parallel().tween_property(main_pivot, "modulate:a", 1.0, 1.0)

	await tw.finished
	set_physics_process(true)
	set_process(true)
	await get_tree().create_timer(0.75).timeout
	target = Globals.player
	rotation_dir = pow(-1, randi() % 2)
	rotation_speed = randf_range(TAU * 0.75, TAU * 1.25)
	attack_mode = AttackMode.ROTATE
	current_state = State.MOVE
	shoot_timer.start(fire_interval)
	timer.start(randf_range(4, 6))
	
	tw = create_tween()
	tw.set_loops()
	tw.parallel().tween_property(sub_pivot_1, "rotation_degrees", -30, 0.5)
	tw.parallel().tween_property(sub_pivot_2, "rotation_degrees", -30, 0.5)
	tw.parallel().tween_property(sub_pivot_3, "rotation_degrees", -30, 0.5)
	tw.parallel().tween_property(sub_pivot_4, "rotation_degrees", -30, 0.5)
	tw.tween_interval(0.15)
	tw.parallel().tween_property(sub_pivot_1, "rotation_degrees", 30, 0.5)
	tw.parallel().tween_property(sub_pivot_2, "rotation_degrees", 30, 0.5)
	tw.parallel().tween_property(sub_pivot_3, "rotation_degrees", 30, 0.5)
	tw.parallel().tween_property(sub_pivot_4, "rotation_degrees", 30, 0.5)
	tw.tween_interval(0.15)
		
func _process(delta: float) -> void:
	health_bar_pivot.global_rotation = 0
	
	if current_state == State.MOVE or current_state == State.PREPARE:
		wander(delta)
		
	if attack_mode == AttackMode.ROTATE:
		main_pivot.rotation += rotation_dir * rotation_speed * delta
	else:
		var target_transform : Transform2D = main_pivot.global_transform.looking_at(Globals.player.global_position)
		main_pivot.global_transform = main_pivot.global_transform.interpolate_with(target_transform, 0.7)
		

func _physics_process(delta: float) -> void:
	if current_state == State.KNOCKBACK:
		velocity = lerp(velocity, Vector2.ZERO, 0.15)
		if velocity.length_squared() < 100:
			current_state = previous_state
		if can_shoot:
			shoot()	
			
		
	elif current_state == State.MOVE:	
		if position.distance_squared_to(waypoint) < 100:
			select_destination(1, 6, 1, 2, 128)
		
		velocity = lerp(velocity, position.direction_to(waypoint) * speed, 0.25)

		if can_shoot and !Globals.player.dead:
			shoot()	
		
		
	
	elif current_state == State.PREPARE:
		if position.distance_squared_to(waypoint) < 100:
			select_destination(1, 6, 1, 2, 128)
		
		velocity = lerp(velocity, position.direction_to(waypoint) * speed, 0.25)
			

	move_and_slide()

func shoot():
	for muzzle in get_tree().get_nodes_in_group("Muzzles"):
		var bullet : Node2D = bullet_scene.instantiate()
		if attack_mode == AttackMode.ROTATE:
			bullet.velocity = muzzle.global_transform.y * rotation_dir
		bullet.rotation = muzzle.global_rotation
		bullet.speed = 384
		bullet.color = Globals.color_palettes[Globals.current_palette][3]
		bullet.damage = power
				
		bullet_fired.emit(bullet, muzzle.global_position)
	SoundManager.play_effect(SoundManager.Effects.ENEMY_SHOOT)
	
	can_shoot = false
	shoot_timer.start(fire_interval)
	

func apply_color_palette():
	primary_color = Globals.color_palettes[Globals.current_palette][5]
	secondary_color = Globals.color_palettes[Globals.current_palette][4]
	tertiary_color = Globals.color_palettes[Globals.current_palette][3]
	
	body_upper.self_modulate = primary_color
	body_lower.self_modulate = secondary_color
	top.self_modulate = tertiary_color
	
	for cannon : Sprite2D in get_tree().get_nodes_in_group("Cannons"):
		cannon.self_modulate = Globals.color_palettes[Globals.current_palette][2]

func knockback(dir : Vector2):
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(body_upper, "self_modulate", Color.WHITE, 0.1)
	tw.parallel().tween_property(body_lower, "self_modulate", Color.WHITE, 0.1)
	tw.parallel().tween_property(top, "self_modulate", Color.WHITE, 0.1)
	tw.tween_interval(0.1)
	tw.tween_property(body_upper, "self_modulate",primary_color, 0.1)
	tw.parallel().tween_property(body_lower, "self_modulate", secondary_color, 0.1)
	tw.parallel().tween_property(top, "self_modulate", tertiary_color, 0.1)
	
	if ![State.PREPARE].has(current_state):
		velocity = dir * speed * 1.25
		previous_state = current_state
		current_state = State.KNOCKBACK
	
func switch_muzzles_to_massive_mode():
	var tw : Tween = create_tween()
	tw.set_parallel()
	tw.tween_property(pivot_1, "rotation_degrees", -26.0, 1.5)
	tw.tween_property(pivot_2, "rotation_degrees", 26.0, 1.5)
	tw.tween_property(pivot_3, "rotation_degrees", 80.0, 1.5)
	tw.tween_property(pivot_4, "rotation_degrees", -80.0, 1.5)
	
	await tw.finished
	
	
	current_state = State.MOVE

	timer.start(randf_range(4,6))
	shoot_timer.start(fire_interval)
	
func switch_muzzles_to_rotate_mode():
	var tw : Tween = create_tween()
	tw.set_parallel()
	tw.tween_property(pivot_1, "rotation_degrees", 0.0, 1.5)
	tw.tween_property(pivot_2, "rotation_degrees", 90.0, 1.5)
	tw.tween_property(pivot_3, "rotation_degrees", 180.0, 1.5)
	tw.tween_property(pivot_4, "rotation_degrees", -90.0, 1.5)
	
	await tw.finished
	
	attack_mode = AttackMode.ROTATE
	current_state = State.MOVE
	rotation_dir = pow(-1, randi() % 2)
	rotation_speed = randf_range(TAU * 0.75, TAU * 1.25)
	timer.start(randf_range(4,6))
	shoot_timer.start(fire_interval)
	
func _on_shoot_timer_timeout() -> void:
	can_shoot = true


func _on_timer_timeout() -> void:
	can_shoot = false
	shoot_timer.stop()
	current_state = State.PREPARE
	if attack_mode == AttackMode.ROTATE:
		attack_mode = AttackMode.MASSIVE
		switch_muzzles_to_massive_mode()
	else:
		switch_muzzles_to_rotate_mode()
		
		
