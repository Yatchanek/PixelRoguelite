extends Node2D
class_name Missile

const explosion_scene : PackedScene = preload("res://scenes/explosion.tscn")

@onready var body: Sprite2D = $Body
@onready var engine: GPUParticles2D = $Engine


var power : int = 2
var target : Player
var speed : int = 256
var level : int

var velocity : Vector2

var lifetime : float = 2.5

signal exploded

func _ready() -> void:
	apply_color_palette()
	speed = min(176 + 16 * level, 256)
	$HurtBox.damage = power

func apply_color_palette():
	body.self_modulate = Globals.color_palettes[Globals.current_palette][2]
	
func _physics_process(delta: float) -> void:
	if !target or target.dead:
		exploded.emit(global_position)
		queue_free()
		
	else:
		var desired_velocity = global_position.direction_to(target.global_position) * speed
		
		velocity = lerp(velocity, desired_velocity, 0.2)
		
	position += velocity * delta
	rotation = velocity.angle()
	
	lifetime -= delta
	if lifetime < 0:
		explode(Vector2.ZERO)
		queue_free()

func explode(dir : Vector2):
	var explosion : Explosion = explosion_scene.instantiate()
	explosion.initialize(dir, [Globals.color_palettes[Globals.current_palette][1], Globals.color_palettes[Globals.current_palette][2], Globals.color_palettes[Globals.current_palette][3]])
	exploded.emit(explosion, global_position)
	queue_free()	
		
func take_damage(_amount: int, _dir : Vector2):
	explode(_dir)
