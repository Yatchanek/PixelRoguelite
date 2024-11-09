extends CharacterBody2D
class_name Player

@onready var lower_body: Sprite2D = $LowerBody
@onready var upper_body: Sprite2D = $LowerBody/UpperBody
@onready var legs: AnimatedSprite2D = $Legs

@onready var turret_pivot: Marker2D = $TurretPivot

@onready var turret: Sprite2D = $TurretPivot/Turret
@onready var shoot_timer: Timer = $ShootTimer
@onready var muzzle: Marker2D = $TurretPivot/Turret/Muzzle
@onready var turret_collision: CollisionShape2D = $TurretCollision


const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")
const explosion_scene : PackedScene = preload("res://scenes/explosion.tscn")

var speed : int = 160
var power : int = 1
var fire_rate : float = 0.5
var max_hp : int = 5
var hp : int = 50
var bullet_speed : int = 512
var autofire : bool = false

var experience : int = 0
var level : int = 0
var exp_to_next_level : int = 300

var can_shoot : bool = true

var dead : bool = false

var elapsed_time : float = 0

var primary_color : Color
var secondary_color : Color
var tertiary_color : Color

var damaging_area : HurtBox

signal bullet_fired(bullet : Node2D, pos : Vector2)
signal health_changed(value : int)
signal exploded(explosion : Explosion, pos : Vector2)
signal player_ready(player : Player)
signal died

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()
		
	if event is InputEventMouseButton:
		if dead:
			return


func _ready() -> void:
	apply_color_palette()
	player_ready.connect(Globals._on_player_ready)
	await get_tree().process_frame
	health_changed.emit(hp)
	player_ready.emit(self)

func _process(delta: float) -> void:
	var dir_to_mouse : Vector2 = turret_pivot.global_position.direction_to(get_global_mouse_position())
	var target_transform : Transform2D = turret_pivot.global_transform.looking_at(turret_pivot.global_position + dir_to_mouse)
		
	turret_pivot.global_transform = turret_pivot.global_transform.interpolate_with(target_transform, 0.75)
	turret_collision.position = to_local(turret.global_position)

	if damaging_area:
		elapsed_time += delta
		if elapsed_time > 0.5:
			take_damage(damaging_area.damage, Vector2.ZERO)
			elapsed_time = 0.0
	

func get_input() -> Vector2:
	var move_dir : Vector2 = Vector2(Input.get_axis("left", "right"), Input.get_axis("forward", "back")).normalized()
	
	return move_dir

func _physics_process(delta: float) -> void:
	if dead:
		return
	
	var move_dir : Vector2 = get_input()
	if move_dir.x != 0.0 or move_dir.y != 0.0:
		legs.play("walk")
		
	else:
		legs.play("idle")
	
	velocity = lerp(velocity, move_dir * speed, 0.2)
	
	if Input.is_action_just_pressed("ui_accept"):
		velocity *= 5.0
		
	if Input.is_action_pressed("shoot") and autofire:
		shoot()
	elif Input.is_action_just_pressed("shoot"):
		shoot()
	
	move_and_slide()

func apply_color_palette():
	primary_color = Globals.color_palettes[Globals.current_palette][3]
	secondary_color = Globals.color_palettes[Globals.current_palette][4]
	tertiary_color = Globals.color_palettes[Globals.current_palette][1]
	lower_body.self_modulate = primary_color
	upper_body.self_modulate = secondary_color
	legs.self_modulate = tertiary_color
	turret.self_modulate = Globals.color_palettes[Globals.current_palette][2]
	

func take_damage(amount : int, _dir : Vector2):
	if dead: 
		return
	hp -= amount
	health_changed.emit(hp)
	
	if hp <= 0:
		explode()
		died.emit()
		hide()
		dead = true
		$Hitbox/CollisionShape2D.set_deferred("disabled", true)
		$CollisionShape2D.set_deferred("disabled", true)
		
		await get_tree().create_timer(2.0).timeout
		Globals.reset()
		get_tree().reload_current_scene()
		
	else:
		SoundManager.play_effect(SoundManager.Effects.HIT)
		var tw : Tween = create_tween()
		tw.tween_property(lower_body, "self_modulate", Color.WHITE, 0.1)
		tw.parallel().tween_property(upper_body, "self_modulate", Color.WHITE, 0.1)
		tw.parallel().tween_property(legs, "self_modulate", Color.WHITE, 0.1)
		tw.tween_interval(0.1)
		tw.tween_property(lower_body, "self_modulate", primary_color, 0.1)
		tw.parallel().tween_property(upper_body, "self_modulate", secondary_color, 0.1)
		tw.parallel().tween_property(legs, "self_modulate", tertiary_color, 0.1)

func explode():
	var explosion : Explosion = explosion_scene.instantiate()
	var colors : Array[Color] = [primary_color, secondary_color, tertiary_color]
	explosion.initialize(Vector2.ZERO, colors)
	
	exploded.emit(explosion, global_position)

func gain_exp(value):
	experience += value
	if experience >= exp_to_next_level:
		Globals.leveled_up = true
		level += 1
		exp_to_next_level += level * 300

func deactivate_collision():
	$CollisionShape2D.set_deferred("disabled", true)
	
func activate_collision():
	$CollisionShape2D.set_deferred("disabled", false)

func shoot():
	if !can_shoot:
		return
		
	var bullet : Node2D = bullet_scene.instantiate()
	bullet.rotation = muzzle.global_rotation
	bullet.damage = power
	bullet.speed = bullet_speed
	
	bullet_fired.emit(bullet, muzzle.global_position)
	can_shoot = false
	shoot_timer.start(fire_rate)
	SoundManager.play_effect(SoundManager.Effects.PLAYER_SHOOT)


func increase_power(amount : int):
	power += amount
	
func increase_speed(amount : int):
	speed += amount
	legs.sprite_frames.set_animation_speed("walk", 5 * speed / 160.0)
	
func change_firerate(amount : float):
	fire_rate += amount
	
func toggle_autofire(status : bool):
	autofire = status
	
func increase_bullet_speed(amount : int):
	bullet_speed += amount

func increase_max_hp(amount : int):
	max_hp += amount
	EventBus.player_max_health_changed.emit(max_hp)
	hp += amount
	health_changed.emit(hp)
	
func heal(amount: int):
	hp = min(hp + amount, max_hp)
	health_changed.emit(hp)
	
func _on_shoot_timer_timeout() -> void:
	can_shoot = true


func _on_hitbox_area_entered(area: Area2D) -> void:
	damaging_area = area


func _on_hitbox_area_exited(area: Area2D) -> void:
	damaging_area = null
	elapsed_time = 0.0
