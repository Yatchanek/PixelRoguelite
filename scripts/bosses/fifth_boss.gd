extends Boss
class_name FifthGuardian

@onready var timer: Timer = $Timer
@onready var shoot_timer: Timer = $ShootTimer
@onready var base: Sprite2D = $Base
@onready var middle: Sprite2D = $Middle
@onready var turret_pivot: Marker2D = $TurretPivot

const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")

var current_state : State
var previous_state : State

var shots_fired : int = 0
var shoots_to_fire : int = 0


enum State {
	MOVE,
	TELEPORT,
	KNOCKBACK
}

signal bullet_fired(bullet : Node2D, pos : Vector2)


func _ready() -> void:
	setup()
	target = Globals.player
		
	apply_color_palette()
	
	set_physics_process(false)
	set_process(false)
		
	var tw : Tween = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(base, "modulate:a", 1.0, 1.0)
	tw.parallel().tween_property(middle, "modulate:a", 1.0, 1.0)
	tw.parallel().tween_property(turret_pivot, "modulate:a", 1.0, 1.0)
	await tw.finished
	set_physics_process(true)
	set_process(true)

	current_state = State.MOVE
	shoots_to_fire = randi_range(5, 10)
	wander_interval = randf_range(1.25, 1.75)
	shoot_timer.start(fire_interval)


func _process(delta: float) -> void:
	health_bar_pivot.global_rotation = 0
	if !is_instance_valid(target):
		return
	if current_state == State.MOVE:
		wander(delta)
	
	var target_transform = turret_pivot.global_transform.looking_at(target.global_position)
	turret_pivot.global_transform = turret_pivot.global_transform.interpolate_with(target_transform, 0.25)		
	
	
	
	

func _physics_process(_delta: float) -> void:
	if current_state == State.KNOCKBACK:
		velocity = lerp(velocity, Vector2.ZERO, 0.15)
		if velocity.length_squared() < 100:
			current_state = previous_state

	elif current_state == State.MOVE:	
		if position.distance_squared_to(waypoint) < 100:
			waypoint = select_destination()

		velocity = lerp(velocity, position.direction_to(waypoint) * speed, 0.25)
		base.rotation = lerp_angle(base.rotation, velocity.angle(), 0.25)

		if can_shoot:
			shoot()	
	else:
		velocity = lerp(velocity, Vector2.ZERO, 0.5)
		
	move_and_slide()

func place_turrets():
	var angle_increment : float = PI / 12
	var start_angle : float = - PI / 6
	for turret : Sprite2D in turret_pivot.get_children():
		var radius : float = (20 - abs(turret.get_index() - 2) * 4)
		turret.position = Vector2(radius * cos(start_angle), radius * sin(start_angle))
		turret.rotation = turret.position.angle()
		start_angle += angle_increment

		

func shoot():
	can_shoot = false
	for muzzle : Marker2D in get_tree().get_nodes_in_group("Muzzles"):
		if dead:
			return
		var bullet : Bullet = bullet_scene.instantiate()
		bullet.rotation = muzzle.global_rotation# + randf_range(-PI / 12, PI / 12)
		bullet.color = tertiary_color
		bullet.damage = power
		bullet.speed = clamp(randi_range(392, 472) + 16 * level, 384, 640)
		await get_tree().create_timer(0.1).timeout
		bullet_fired.emit(bullet, muzzle.global_position)
		SoundManager.play_effect(SoundManager.Effects.ENEMY_SHOOT)
	

	
	
	shots_fired += 1
	if shots_fired >= shoots_to_fire:
		teleport()
	else:
		shoot()
		

func teleport():
	current_state = State.TELEPORT
	var tw : Tween = create_tween()
	$Hitbox.deactivate()
	$HurtBox.deactivate()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(base, "modulate:a", 0.0, 1.0)
	tw.parallel().tween_property(middle, "modulate:a", 0.0, 1.0)
	tw.parallel().tween_property(turret_pivot, "modulate:a", 0.0, 1.0)
	await tw.finished
	health_bar.hide()
	
	await get_tree().create_timer(randf_range(1, 2)).timeout
	
	find_new_destination()
	
func find_new_destination():
	var pos : Vector2i
	var accepted : bool = false
	while !accepted:
		pos = Vector2(32, 32) + Utils.get_random_coords(2, 5, 2, 3) * 64
		if pos.distance_squared_to(to_local(target.global_position)) > 4096:
			accepted = true
			
	position = pos
	var tw : Tween = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(base, "modulate:a", 1.0, 1.0)
	tw.parallel().tween_property(middle, "modulate:a", 1.0, 0.5)
	tw.parallel().tween_property(turret_pivot, "modulate:a", 1.0, 0.5)
	$Hitbox.activate()
	$HurtBox.activate()
	await tw.finished
	if hp < base_hp + hp_per_level * level:
		health_bar.show()
	shots_fired = 0
	shoots_to_fire = randi_range(5, 10)
	shoot_timer.start(fire_interval)
	current_state = State.MOVE
		

func apply_color_palette():
	primary_color = Globals.color_palettes[Globals.current_palette][5]
	secondary_color = Globals.color_palettes[Globals.current_palette][4]
	tertiary_color = Globals.color_palettes[Globals.current_palette][2]
	
	base.self_modulate = primary_color
	middle.self_modulate = secondary_color
	
	for turret : Sprite2D in turret_pivot.get_children():
		turret.self_modulate = tertiary_color


func knockback(dir : Vector2):
	
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(base, "self_modulate", Color.WHITE, 0.1)
	tw.parallel().tween_property(middle, "self_modulate", Color.WHITE, 0.1)
	tw.tween_interval(0.15)
	tw.tween_property(base, "self_modulate",primary_color, 0.1)
	tw.parallel().tween_property(middle, "self_modulate", secondary_color, 0.1)
	
	if current_state != State.TELEPORT:
		velocity = dir * speed * 1.25
		previous_state = current_state
		current_state = State.KNOCKBACK

func _on_shoot_timer_timeout() -> void:
	can_shoot = true
