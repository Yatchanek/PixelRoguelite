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
@onready var shield: Sprite2D = $Shield
@onready var shield_legs: AnimatedSprite2D = $ShieldLegs
@onready var turret_hitbox: CollisionShape2D = $Hitbox/TurretHitbox
@onready var ghost_timer: Timer = $GhostTimer
@onready var dash_timer: Timer = $DashTimer


const bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")
const explosion_scene : PackedScene = preload("res://scenes/explosion.tscn")
const ghost_scene : PackedScene = preload("res://scenes/player_ghost.tscn")

var speed : int = 160
var power : int = 1
var fire_rate : float = 0.5
var shield_hp : int = 0 :
	set(value):
		shield_hp = value
		shield_hp_changed.emit(shield_hp)
var max_shield_hp : int = 5 :
	set(value):
		max_shield_hp = value
		max_shield_hp_changed.emit(max_shield_hp)
var max_hp : int = 10 :
	set(value):
		max_hp = value
		max_health_changed.emit(max_hp)
var hp : int = 10 :
	set(value):
		hp = value
		health_changed.emit(hp)
var bullet_speed : int = 512
var autofire : bool = false

var experience : int = 0
var level : int = 0
var exp_to_next_level : int = 300

var can_shoot : bool = true

var dead : bool = false

var elapsed_time : float = 0
var is_dashing : bool = false
var dashing_speed : int
var dash_duration : float = 0.1
var dash_energy : float = 15.0 : 
	set(value):
		dash_energy = value
		dash_energy_changed.emit(dash_energy)
var max_dash_energy : int = 15 :
	set(value):
		max_dash_energy = value
		max_energy_changed.emit(max_dash_energy)
var dash_regen : float = 0
var dash_regen_speed : float = 0.5

var primary_color : Color
var secondary_color : Color
var tertiary_color : Color

var damaging_area : HurtBox

signal bullet_fired(bullet : Node2D, pos : Vector2)
signal health_changed(value : int)
signal max_health_changed(value : int)
signal shield_hp_changed(value : int)
signal max_shield_hp_changed(value : int)
signal exploded(explosion : Explosion, pos : Vector2)
signal player_ready(player : Player)
signal ghost_spawned(ghost : Sprite2D, pos : Vector2)
signal dash_energy_changed(value : float)
signal max_energy_changed(value : int)
signal died

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			SceneChanger.change_scene(SceneChanger.title_screen_scene)
		
	if event is InputEventMouseButton:
		if dead:
			return


func _ready() -> void:
	apply_color_palette()
	player_ready.connect(Globals._on_player_ready)
	EventBus.game_completed.connect(_on_game_completed)
	await get_tree().process_frame
	self.max_hp = 20
	self.hp = max_hp
	self.max_shield_hp = 5
	self.shield_hp = 0
	self.max_dash_energy = 15
	self.dash_energy = 15.0
	self.dashing_speed = 3 * speed
	player_ready.emit(self)

func _process(delta: float) -> void:
	var dir_to_mouse : Vector2 = turret_pivot.global_position.direction_to(get_global_mouse_position())
	var target_transform : Transform2D = turret_pivot.global_transform.looking_at(turret_pivot.global_position + dir_to_mouse)
		
	turret_pivot.global_transform = turret_pivot.global_transform.interpolate_with(target_transform, 0.75)
	turret_collision.transform = turret_pivot.transform.translated(turret_pivot.transform.x * 12)

	turret_hitbox.transform = turret_collision.transform

	if damaging_area:
		elapsed_time += delta
		if elapsed_time > 0.25:
			take_damage(damaging_area.damage, Vector2.ZERO)
			elapsed_time -= 0.25
			
	if dash_energy < max_dash_energy:
		dash_regen += delta
		if dash_regen >= dash_regen_speed:
			dash_energy += 0.1
			dash_regen -= dash_regen_speed


func get_input() -> Vector2:
	var move_dir : Vector2 = Input.get_vector("left", "right", "forward", "back").normalized()
	
	return move_dir

func _physics_process(_delta: float) -> void:
	if dead:
		return
	
	var move_dir : Vector2 = get_input()
	if move_dir != Vector2.ZERO:
		legs.play("walk")
		shield_legs.play("walk")
		if is_dashing:
			velocity = lerp(velocity, move_dir * dashing_speed, 0.33)
		else:
			velocity = lerp(velocity, move_dir * speed, 0.2)
		
	else:
		legs.play("idle")
		shield_legs.play("idle")
		if is_dashing:
			velocity = lerp(velocity, Vector2.ZERO, 0.05)
		else:
			velocity = lerp(velocity, Vector2.ZERO, 0.25)
	
	
	if Input.is_action_just_pressed("ui_accept") and !is_dashing:
		if dash_energy < 5.0:
			return
		dash_energy -= 5.0

		is_dashing = true
		dash_timer.start(dash_duration)
		ghost_timer.start()	
		
	if Input.is_action_pressed("shoot"):
		shoot()
	
	move_and_slide()

func apply_color_palette():
	primary_color = Globals.color_palettes[Globals.current_palette][3]
	secondary_color = Globals.color_palettes[Globals.current_palette][4]
	tertiary_color = Globals.color_palettes[Globals.current_palette][2]
	
	lower_body.self_modulate = primary_color
	upper_body.self_modulate = secondary_color
	legs.self_modulate = tertiary_color
	turret.self_modulate = Globals.color_palettes[Globals.current_palette][2]
	shield.self_modulate = Globals.color_palettes[Globals.current_palette][1]
	shield_legs.self_modulate = Globals.color_palettes[Globals.current_palette][1]
	

func take_damage(amount : int, _dir : Vector2):
	if dead: 
		return
	if shield_hp > 0:
		shield_hp -= amount
		shield_hp_changed.emit(shield_hp)
		flash_shield()
		if shield_hp < 0:
			shield_hp = 0
			amount = -shield_hp
		else:
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
		SoundManager.play_effect(SoundManager.Effects.PLAYER_DEATH)
		
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

func flash_shield():
	var tw : Tween = create_tween()
	tw.tween_property(shield, "modulate:a", 1.0, 0.1)
	tw.parallel().tween_property(shield_legs, "modulate:a", 1.0, 0.1)
	tw.tween_interval(0.1)
	tw.tween_property(shield, "modulate:a", 0.0, 0.1)
	tw.parallel().tween_property(shield_legs, "modulate:a", 0.0, 0.1)	

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
		exp_to_next_level += 300 + 150 * level

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
	bullet.color = Globals.color_palettes[Globals.current_palette][0]
	bullet_fired.emit(bullet, muzzle.global_position)
	can_shoot = false
	shoot_timer.start(fire_rate)
	SoundManager.play_effect(SoundManager.Effects.PLAYER_SHOOT)


func increase_power(amount : int):
	power += amount
	
func increase_speed(amount : int):
	speed = clamp(speed + amount, 160, 320)
	dashing_speed = speed * 3
	legs.sprite_frames.set_animation_speed("walk", 5 * speed / 160.0)
	shield_legs.sprite_frames.set_animation_speed("walk", 5 * speed / 160.0)
	
func change_firerate(amount : float):
	fire_rate += amount
	
func toggle_autofire(status : bool):
	autofire = status
	
func increase_bullet_speed(amount : int):
	bullet_speed += amount

func increase_max_hp(amount : int):
	self.max_hp += amount
	self.hp += amount
	
func increase_shield_max_hp(amount : int):
	self.max_shield_hp += amount
	if shield_hp > 0:
		self.shield_hp += amount

func increase_dash_duration(amount : float):
	self.dash_duration += amount
	
func increase_dash_energy(amount : int):
	self.max_dash_energy += amount
	self.dash_energy = clamp(dash_energy + amount, dash_energy, max_dash_energy)

func increase_dash_regen(amount : float):
	self.dash_regen_speed += amount	
	
func heal(amount: int):
	self.hp = min(hp + amount, max_hp)
	#health_changed.emit(hp)
	
func get_shield(amount : int):
	self.shield_hp = min(shield_hp + amount, max_shield_hp)
	#shield_hp_changed.emit(shield_hp)	
	
func _on_shoot_timer_timeout() -> void:
	can_shoot = true


func _on_hitbox_area_entered(area: Area2D) -> void:
	damaging_area = area


func _on_hitbox_area_exited(_area: Area2D) -> void:
	damaging_area = null
	elapsed_time = 0.0


func _on_ghost_timer_timeout() -> void:
	var ghost : Sprite2D = ghost_scene.instantiate()
	ghost.region_rect.position.x = 16 * legs.frame
	ghost.self_modulate = primary_color
	ghost_spawned.emit(ghost, global_position)


func _on_dash_timer_timeout() -> void:
	is_dashing = false
	ghost_timer.stop()
	
func _on_game_completed():
	set_process(false)
	set_physics_process(false)
	set_process_unhandled_input(false)
	legs.play("idle")
