extends Enemy
class_name TurretEnemy

@onready var shoot_timer: Timer = $ShootTimer
@onready var body: Sprite2D = $Body
@onready var chasis: Sprite2D = $Body/Chasis
@onready var top: Sprite2D = $Body/Chasis/Top

const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")

var elapsed_time : float = 0.0
var can_shoot : bool = false

signal bullet_fired(bullet : Node2D, pos : Vector2)

var tick : int = 0

var current_muzzle : int


func _ready() -> void:
	apply_color_palette()
	set_process(false)
	$Hitbox.deactivate()
	var tw : Tween = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(body, "modulate:a", 1.0, 0.5)
	await tw.finished
	$Hitbox.activate()
	tw = create_tween()
	tw.tween_interval(0.15)
	await tw.finished
	set_process(true)
	hp = min(4 + level, 8)
	fire_interval = max(1.3 - 0.1 * level, 0.8)
	shoot_timer.start(fire_interval)
	current_muzzle = 1
	health_bar.max_value = hp
	health_bar.value = hp		


func _process(_delta: float) -> void:
	var target_transform : Transform2D = chasis.global_transform.looking_at(target.global_position)
	
	chasis.global_transform = chasis.global_transform.interpolate_with(target_transform, 0.75)
	
	if can_shoot and chasis.global_transform.x.dot(chasis.global_position.direction_to(target.global_position)) > 0.98:
		shoot()	

func shoot():
	var query : PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(chasis.global_position, chasis.global_position + chasis.global_transform.x * 640, 7)
	var state : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	
	var result : Dictionary = state.intersect_ray(query)	
	if result and result.collider.collision_layer != 1:
		return
		
	var bullet : Node2D = bullet_scene.instantiate()
	bullet.rotation = chasis.global_rotation
	
	bullet_fired.emit(bullet, chasis.global_position + chasis.global_transform.x * 14 + chasis.global_transform.y * 6 * current_muzzle)
	can_shoot = false
	current_muzzle = -current_muzzle
	shoot_timer.start(fire_interval)


func apply_color_palette():
	body.self_modulate = Globals.color_palettes[Globals.current_palette][2]
	chasis.self_modulate = Globals.color_palettes[Globals.current_palette][3]
	top.self_modulate = Globals.color_palettes[Globals.current_palette][4]



func knockback(_dir : Vector2):
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(body, "self_modulate", Color.WHITE, 0.1)
	tw.parallel().tween_property(chasis, "self_modulate", Color.WHITE, 0.1)
	tw.parallel().tween_property(top, "self_modulate", Color.WHITE, 0.1)
	tw.tween_interval(0.1)
	tw.tween_property(body, "self_modulate", Globals.color_palettes[Globals.current_palette][2], 0.1)
	tw.parallel().tween_property(chasis, "self_modulate", Globals.color_palettes[Globals.current_palette][3], 0.1)
	tw.parallel().tween_property(top, "self_modulate", Globals.color_palettes[Globals.current_palette][4], 0.1)




func _on_shoot_timer_timeout() -> void:
	can_shoot = true
