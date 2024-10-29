extends CharacterBody2D
class_name Enemy

const directional_explosion_scene : PackedScene = preload("res://scenes/directional_explosion.tscn")

@onready var health_bar: TextureProgressBar = $HealthBarPivot/HealthBar
@onready var health_bar_pivot: Marker2D = $HealthBarPivot

@export var hp : int = 1
@export var speed : float = 64
@export var target : CharacterBody2D
@export var exp_value : int = 10
@export var power : int = 1
@export var fire_interval : float = 1.0

var level : int

var primary_color : Color
var secondary_color : Color
var tertiary_color : Color

signal exploded(explosion : Explosion, pos : Vector2)
signal destroyed(enemy : Enemy)

func take_damage(amount : int, dir : Vector2):
	hp -= amount
	if hp <= 0:
		explode(dir)
		destroyed.emit(self)
		queue_free()
		SoundManager.play_effect(SoundManager.Effects.EXPLOSION)
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
		
	explosion.initialize(dir, colors)
	exploded.emit(explosion, global_position)
