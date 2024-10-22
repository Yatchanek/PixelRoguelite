extends CharacterBody2D
class_name Enemy

@onready var health_bar: TextureProgressBar = $HealthBarPivot/HealthBar
@onready var health_bar_pivot: Marker2D = $HealthBarPivot

@export var hp : int = 1
@export var speed : float = 64
@export var target : CharacterBody2D
@export var exp_value : int = 10
@export var power : int = 1
@export var fire_interval : float = 1.0

var level : int

signal exploded(pos : Vector2)

func take_damage(amount : int, dir : Vector2):
	hp -= amount
	if hp <= 0:
		exploded.emit(global_position)
		queue_free()
	else:
		health_bar.show()
		health_bar.value = hp
		health_bar.tint_progress = Globals.color_palettes[Globals.current_palette][3]
		knockback(dir)	

func knockback(_dir : Vector2):
	pass
