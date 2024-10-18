extends CharacterBody2D
class_name Player

@onready var turret: Sprite2D = $Turret
@onready var shoot_timer: Timer = $ShootTimer
@onready var muzzle: Marker2D = $Turret/Muzzle
@onready var body: Sprite2D = $Body

const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")

var speed : int = 160
var power : int = 1
var fire_rate : float = 0.5
var max_hp : int = 5
var hp : int = 50
var bullet_speed : int = 512
var autofire : bool = false

var experience : int = 0
var level : int = 1
var exp_to_next_level : int = 100

var can_shoot : bool = true

var dead : bool = false

var rotation_speed : float = 0

signal bullet_fired(bullet : Node2D, pos : Vector2)
signal health_changed(value : int)
signal exploded(pos : Vector2)
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

func _process(_delta: float) -> void:
	var dir_to_mouse : Vector2 = turret.global_position.direction_to(get_global_mouse_position())
	var target_transform : Transform2D = turret.global_transform.looking_at(turret.global_position + dir_to_mouse)
		
	turret.global_transform = turret.global_transform.interpolate_with(target_transform, 0.15)
	

func get_input() -> Vector2:
	var move_dir : Vector2 = Vector2(Input.get_axis("left", "right"), Input.get_axis("forward", "back")).normalized()
	
	return move_dir

func _physics_process(delta: float) -> void:
	if dead:
		return
	var move_dir : Vector2 = get_input()
	if move_dir.x > 0 or move_dir.y > 0:
		rotation_speed = lerp(rotation_speed, TAU, 0.25)
 
	elif move_dir.x < 0 or move_dir.y < 0:
		rotation_speed = lerp(rotation_speed, -TAU, 0.25)
	
	elif move_dir.is_equal_approx(Vector2.ZERO):
		rotation_speed = lerp(rotation_speed, 0.0, 0.5)
	
	body.rotation += rotation_speed * delta			
	velocity = lerp(velocity, move_dir * speed, 0.2)

	
	if Input.is_action_just_pressed("ui_accept"):
		velocity *= 5.0
		
	if Input.is_action_pressed("shoot") and autofire:
		shoot()
	elif Input.is_action_just_pressed("shoot"):
		shoot()
	
	move_and_slide()

func apply_color_palette():
	body.self_modulate = Globals.color_palettes[Globals.current_palette][4]
	turret.self_modulate = Globals.color_palettes[Globals.current_palette][2]

func take_damage(amount : int, _dir : Vector2):
	hp -= amount
	health_changed.emit(hp)
	if hp <= 0:
		exploded.emit(global_position)
		died.emit()
		hide()
		dead = true
		$Hitbox/CollisionShape2D.set_deferred("disabled", true)
		$CollisionShape2D.set_deferred("disabled", true)
		
		await get_tree().create_timer(2.0).timeout
		
		get_tree().reload_current_scene()
	else:
		var tw : Tween = create_tween()
		tw.tween_property(body, "modulate", Color.RED, 0.1)
		tw.tween_property(body, "modulate", Color.WHITE, 0.1)
	
	

func gain_exp(value):
	experience += value
	if experience >= exp_to_next_level:
		EventBus.player_leveled_up.emit()
		level += 1
		exp_to_next_level += level * 100

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

func _on_shoot_timer_timeout() -> void:
	can_shoot = true
