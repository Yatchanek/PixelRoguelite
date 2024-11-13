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
	SoundManager.play_effect(SoundManager.Effects.MISSILE)

func apply_color_palette():
	body.self_modulate = Globals.color_palettes[Globals.current_palette][2]
	
func _physics_process(delta: float) -> void:
	if !target or target.dead:
		explode(Vector2.ZERO)
		queue_free()
		
	else:
		var desired_velocity = global_position.direction_to(target.global_position) * speed
		
		velocity = lerp(velocity, desired_velocity, 0.2)

	var query : PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position + global_transform.x * 6, global_position + global_transform.x * 6 + global_transform.x * speed * delta, 54)
	
	query.collide_with_areas = true
	query.hit_from_inside = true
	
	var state : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	
	var result : Dictionary = state.intersect_ray(query)
	
	if !check_hit(result):
		position += velocity * delta
		rotation = velocity.angle()
		
		lifetime -= delta
		if lifetime < 0:
			explode(Vector2.ZERO)
			queue_free()

func check_hit(result : Dictionary) -> bool:
	if result:
		var hit_body : Node2D = result.collider
		if hit_body is HitBox:
			hit_body.receive_damage(power, global_transform.x)
	
		position = result.position - global_transform.x * 6
		explode(Vector2.ZERO)
		return true
	else:
		return false

func explode(dir : Vector2):
	var explosion : Explosion = explosion_scene.instantiate()
	explosion.initialize(dir, [Globals.color_palettes[Globals.current_palette][1], Globals.color_palettes[Globals.current_palette][2], Globals.color_palettes[Globals.current_palette][3]])
	exploded.emit(explosion, global_position)
	queue_free()
		
func take_damage(_amount: int, _dir : Vector2):
	explode(_dir)
