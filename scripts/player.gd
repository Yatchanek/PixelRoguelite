extends CharacterBody2D
class_name Player

@onready var turret: Sprite2D = $Turret
@onready var shoot_timer: Timer = $ShootTimer
@onready var muzzle: Marker2D = $Turret/Muzzle
@onready var body: Sprite2D = $Body

const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")

var speed : int = 112

var hp : int = 5

var can_shoot : bool = true

var dead : bool = false

signal bullet_fired(bullet : Node2D, pos : Vector2)
signal exploded(pos : Vector2)
signal died

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()
		
	if event is InputEventMouseButton:
		if dead:
			return
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			shoot()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var dir_to_mouse : Vector2 = turret.global_position.direction_to(get_global_mouse_position())
	var target_transform : Transform2D = turret.global_transform.looking_at(turret.global_position + dir_to_mouse)
		
	turret.global_transform = turret.global_transform.interpolate_with(target_transform, 0.15)
	

func get_input() -> Vector2:
	var move_dir : Vector2 = Vector2(Input.get_axis("left", "right"), Input.get_axis("forward", "back")).normalized()
	
	return move_dir

func _physics_process(_delta: float) -> void:
	if dead:
		return
	var move_dir : Vector2 = get_input()
	
	velocity = lerp(velocity, move_dir * speed, 0.2)
	
	if Input.is_action_just_pressed("ui_accept"):
		velocity *= 3.0
	
	move_and_slide()

func take_damage(_amount : int):
	hp -= 1
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
		tw.tween_property(body, "modulate", Color(0.435, 0.408, 0.478), 0.1)

func shoot():
	if !can_shoot:
		return
		
	var bullet : Node2D = bullet_scene.instantiate()
	bullet.rotation = muzzle.global_rotation
	
	bullet_fired.emit(bullet, muzzle.global_position)
	can_shoot = false
	shoot_timer.start()

func _on_shoot_timer_timeout() -> void:
	can_shoot = true
