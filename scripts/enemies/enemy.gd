extends CharacterBody2D
class_name Enemy

const directional_explosion_scene : PackedScene = preload("res://scenes/directional_explosion.tscn")

@onready var health_bar: TextureProgressBar = $HealthBarPivot/HealthBar
@onready var health_bar_pivot: Marker2D = $HealthBarPivot

var hp : int = 1
var speed : float = 64
var fire_interval : float = 1.0
@export var target : CharacterBody2D
@export var score_value : int = 1
@export var exp_value : int = 10
@export var power : int = 1
@export var base_fire_interval : float = 1.0
@export var fire_interval_per_level : float = 0.1
@export var min_fire_interval : float = 0.1
@export var base_hp : int = 1
@export var max_hp : int = 1
@export var hp_per_level : int = 1
@export var base_speed : int = 64
@export var max_speed : int = 128
@export var speed_per_level : int = 1
@export var base_power : int = 1
@export var power_per_level : float = 1
@export var max_power : int = 1

var level : int
var dead : bool = false

var can_shoot : bool = false

var primary_color : Color
var secondary_color : Color
var tertiary_color : Color = Color(0, 0, 0, 0)

signal exploded(explosion : Explosion, pos : Vector2)
signal destroyed(enemy : Enemy)

func setup():
	hp = min(base_hp + hp_per_level * level, max_hp)
	health_bar.max_value = hp
	health_bar.value = hp
	speed = min(base_speed + speed_per_level * level, max_speed)
	power = min(power + int(power_per_level * level), max_power)
	fire_interval = max(base_fire_interval - fire_interval_per_level * level, min_fire_interval)

func take_damage(amount : int, dir : Vector2):
	if dead:
		return
	hp -= amount
	if hp <= 0:
		dead = true
		explode(dir)
		destroyed.emit(self)
		queue_free()
	else:
		SoundManager.play_effect(SoundManager.Effects.HIT)
		health_bar.show()
		health_bar.value = hp
		health_bar.tint_progress = Globals.color_palettes[Globals.current_palette][3]
		knockback(dir)	

func knockback(_dir : Vector2):
	pass

func explode(dir : Vector2):
	var explosion : DirectionalExplosion = directional_explosion_scene.instantiate()
	var colors : Array[Color] = [primary_color, secondary_color]
	if tertiary_color != Color(0, 0, 0, 0):
		colors = [primary_color, secondary_color, tertiary_color]
		
	explosion.initialize(dir, colors)
	exploded.emit(explosion, global_position)
	SoundManager.play_effect(SoundManager.Effects.EXPLOSION)

func disable():
	target = null
	dead = true
	set_physics_process(false)
	set_process(false)
	if has_node("Timer"):
		$Timer.stop()
	if has_node("ShootTimer"):
		$ShootTimer.stop()
