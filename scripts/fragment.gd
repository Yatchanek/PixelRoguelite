extends Node2D


@export var lifetime : float = 2.0
@export var damage : int = 1
@export var speed : int = 384

var color : Color = Color.WHITE

@onready var body: Polygon2D = $Body


func _ready() -> void:
	body.self_modulate = color

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	body.rotation += 3 * TAU * delta
	

func _physics_process(delta: float) -> void:
	var query : PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, global_position + transform.x * speed * delta, 52)
	
	query.collide_with_areas = true
	query.hit_from_inside = true
	
	var state : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	
	var result : Dictionary = state.intersect_ray(query)
	
	if !check_hit(result):
		position += transform.x * speed * delta
		speed = lerp(speed, 0, 0.03)


	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	
func check_hit(result : Dictionary) -> bool:
	if result:
		var hit_body : Node2D = result.collider
		if hit_body is HitBox:
			hit_body.receive_damage(damage, global_transform.x)
	
		position = get_parent().to_local(result.position) - global_transform.x * 3
		queue_free()
		return true
	else:
		return false
