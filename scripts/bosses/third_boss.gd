extends Boss
class_name ThirdGuardian

@onready var timer: Timer = $Timer
@onready var shoot_timer: Timer = $ShootTimer
@onready var body: AnimatedSprite2D = $Body
@onready var chasis: Sprite2D = $Body/Chasis
@onready var top: Sprite2D = $Body/Top
@onready var turret: Sprite2D = $Turret
@onready var muzzle: Marker2D = $Turret/Muzzle

const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")
const mine_scene : PackedScene = preload("res://scenes/mine.tscn")

var elapsed_time : float = 0.0


var tick : int = 0

var current_state : State
var previous_state : State

var shots_fired : int = 0
var burst_size : int = 0

var destination : Vector2
var target_rotation : float


enum State {
	MOVE,
	BRAKE,
	TURN,
	ATTACK,
	KNOCKBACK,
	IDLE
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
	set_physics_process(true)
	set_process(true)

	current_state = State.IDLE
	shoot_timer.start(fire_interval)
	timer.start(randf_range(0.2, 0.4))

func _process(delta: float) -> void:
	health_bar_pivot.global_rotation = 0
	if Globals.player.dead:
		return	
	
	turret.look_at(Globals.player.global_position)


func _physics_process(_delta: float) -> void:
	if Globals.player.dead:
		velocity = lerp(velocity, Vector2.ZERO, 0.15)
		move_and_slide()
		return
	if current_state == State.KNOCKBACK:
		velocity = lerp(velocity, Vector2.ZERO, 0.15)
		if velocity.length_squared() < 100:
			velocity = Vector2.ZERO
			if previous_state != State.ATTACK and previous_state != State.MOVE:
				velocity = Vector2.ZERO
				select_destination()
			elif previous_state == State.MOVE:
				rotation = target_rotation
				velocity = body.global_transform.x * 192
				current_state = State.MOVE
				current_state = previous_state
			elif previous_state == State.ATTACK:
				velocity = Vector2.ZERO
				current_state = previous_state

	elif current_state == State.TURN:
		rotation = lerp_angle(rotation, target_rotation, 0.25)
		if global_transform.x.dot(position.direction_to(destination)) > 0.99:
			rotation = target_rotation
			velocity = body.global_transform.x * speed
			lay_mine()
			current_state = State.MOVE
			
	elif current_state == State.MOVE:
		if position.distance_squared_to(destination) < 8000:
			current_state = State.BRAKE
			
	elif current_state == State.BRAKE:
		velocity = lerp(velocity, Vector2.ZERO, 0.2)
		if velocity.length_squared() < 50:
			body.stop()
			velocity = Vector2.ZERO
			shots_fired = 0
			current_state = State.ATTACK
			burst_size = randi_range(5, 8)
			shoot_timer.start(fire_interval)
			
	elif current_state == State.ATTACK:
		if can_shoot:
			shoot()
			
	move_and_slide()
		
func apply_color_palette():
	primary_color = Globals.color_palettes[Globals.current_palette][2]
	secondary_color = Globals.color_palettes[Globals.current_palette][4]
	tertiary_color = Globals.color_palettes[Globals.current_palette][6]
	
	body.self_modulate = primary_color
	chasis.self_modulate = secondary_color
	top.self_modulate = tertiary_color
	turret.self_modulate = Globals.color_palettes[Globals.current_palette][3]

func shoot():
	var bullet : Node2D = bullet_scene.instantiate()
	bullet.rotation = muzzle.global_rotation
	bullet.speed = 440
	bullet.color = primary_color
	bullet.damage = power
	
	bullet_fired.emit(bullet, muzzle.global_position)
	
	can_shoot = false
	shots_fired += 1
	if shots_fired == burst_size:
		timer.start(randf_range(0.2, 0.3))
	else:
		shoot_timer.start(fire_interval)
		
func lay_mine():
	var mine : Mine = mine_scene.instantiate()
	bullet_fired.emit(mine, global_position)

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

	velocity = dir * speed * 1.25
	previous_state = current_state
	current_state = State.KNOCKBACK

func select_destination():
	destination = Vector2i(32, 32) + Utils.get_random_coords() * 64
	while destination.distance_squared_to(position) < 16384:
		destination = Vector2i(32, 32) + Utils.get_random_coords() * 64
	target_rotation = position.direction_to(destination).angle()
	current_state = State.TURN

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func _on_timer_timeout() -> void:
	select_destination()
