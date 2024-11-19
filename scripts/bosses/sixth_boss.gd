extends Boss
class_name SixthGuardian

@onready var timer: Timer = $Timer
@onready var shoot_timer: Timer = $ShootTimer
@onready var body_upper: Sprite2D = $BodyUpper
@onready var body_lower: Sprite2D = $BodyUpper/BodyLower
@onready var moving_parts: AnimatedSprite2D = $MovingParts
@onready var muzzle_pivot: Marker2D = $MuzzlePivot
@onready var muzzle: Marker2D = $MuzzlePivot/Cannon/Muzzle
@onready var cannon: Sprite2D = $MuzzlePivot/Cannon

const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")
const missile_scene : PackedScene = preload("res://scenes/missile.tscn")

var tick : int = 0

var current_state : State
var previous_state : State

var charge_speed : int
var charge_dir : Vector2
var initial_power : int

var shots_to_fire : int
var shots_fired : int

enum State {
	MOVE,
	PREPARE,
	CHARGE,
	REACTIVATE,
	KNOCKBACK
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
	tw.tween_property(body_upper, "modulate:a", 1.0, 1.0)
	tw.parallel().tween_property(moving_parts, "modulate:a", 1.0, 1.0)
	tw.parallel().tween_property(cannon, "modulate:a", 1.0, 1.0)
	await tw.finished
	set_physics_process(true)
	set_process(true)
	await get_tree().create_timer(0.75).timeout
	moving_parts.play("walk")
	target = Globals.player
	charge_speed = speed * 3
	current_state = State.MOVE
	shots_to_fire = randi_range(10, 20)
	shots_fired = 0
	can_shoot = false
	shoot_timer.start(fire_interval)
	

func _process(delta: float) -> void:
	health_bar_pivot.global_rotation = 0
	
	if current_state == State.MOVE:
		wander(delta)
		
		if is_instance_valid(target):
			var target_transform : Transform2D = muzzle_pivot.global_transform.looking_at(target.global_position)
			muzzle_pivot.global_transform = muzzle_pivot.global_transform.interpolate_with(target_transform, 0.7)

func _physics_process(delta: float) -> void:
	if current_state == State.KNOCKBACK:
		velocity = lerp(velocity, Vector2.ZERO, 0.15)
		if velocity.length_squared() < 100:
			current_state = previous_state
		if can_shoot:
			shoot()	
			
		move_and_slide()
		
	elif current_state == State.MOVE:	
		if position.distance_squared_to(waypoint) < 100:
			select_destination(1, 6, 1, 2, 128)
		
		velocity = lerp(velocity, position.direction_to(waypoint) * speed, 0.25)

		if can_shoot and !Globals.player.dead:
			shoot()	
		
		move_and_slide()
	
	elif current_state == State.PREPARE:
		if is_instance_valid(target) and !target.dead:
			charge_dir = global_position.direction_to(target.global_position)
			
	elif current_state == State.CHARGE:
		velocity = lerp(velocity, charge_dir * charge_speed, 0.5)
		
		var collision : KinematicCollision2D = move_and_collide(velocity * delta)
		if collision:
			power = initial_power
			moving_parts.play("idle")
			current_state = State.REACTIVATE
			timer.start(0.5)
		
	

func shoot():
	var bullet : Node2D = bullet_scene.instantiate()
	bullet.scale = Vector2(1.5, 1.5)
	bullet.rotation = muzzle.global_rotation
	bullet.speed = 384
	bullet.color = Globals.color_palettes[Globals.current_palette][3]
	bullet.damage = power
			
	bullet_fired.emit(bullet, muzzle.global_position)
	SoundManager.play_effect(SoundManager.Effects.ENEMY_SHOOT)
	
	can_shoot = false
	shots_fired += 1
	if shots_fired == shots_to_fire:
		current_state = State.PREPARE
		timer.start(0.5)
	else:
		shoot_timer.start(fire_interval)
	

func apply_color_palette():
	primary_color = Globals.color_palettes[Globals.current_palette][5]
	secondary_color = Globals.color_palettes[Globals.current_palette][4]
	tertiary_color = Globals.color_palettes[Globals.current_palette][3]
	
	body_upper.self_modulate = primary_color
	body_lower.self_modulate = secondary_color
	moving_parts.self_modulate = tertiary_color
	
	cannon.self_modulate = Globals.color_palettes[Globals.current_palette][2]

func knockback(dir : Vector2):
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(body_upper, "self_modulate", Color.WHITE, 0.1)
	tw.parallel().tween_property(body_lower, "self_modulate", Color.WHITE, 0.1)
	tw.parallel().tween_property(moving_parts, "self_modulate", Color.WHITE, 0.1)
	tw.tween_interval(0.1)
	tw.tween_property(body_upper, "self_modulate",primary_color, 0.1)
	tw.parallel().tween_property(body_lower, "self_modulate", secondary_color, 0.1)
	tw.parallel().tween_property(moving_parts, "self_modulate", tertiary_color, 0.1)
	
	if ![State.PREPARE, State.CHARGE, State.REACTIVATE].has(current_state):
		velocity = dir * speed * 1.25
		previous_state = current_state
		current_state = State.KNOCKBACK
	


func _on_shoot_timer_timeout() -> void:
	can_shoot = true


func _on_timer_timeout() -> void:
	if current_state == State.PREPARE:
		power *= 3
		moving_parts.sprite_frames.set_animation_speed("walk", 15)
		current_state = State.CHARGE
	else:
		moving_parts.play("walk")
		moving_parts.sprite_frames.set_animation_speed("walk", 5)
		current_state = State.MOVE
		shots_to_fire = randi_range(10, 20)
		shots_fired = 0
		shoot_timer.start(fire_interval)
