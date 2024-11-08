extends Node2D
class_name Laser

@onready var beam: Line2D = $Beam
@onready var charge: Sprite2D = $Charge
@onready var inner_beam: Line2D = $Beam/InnerBeam

var shoot_duration : float = 0.5
var elapsed_time : float = 0.0
var damage_counter : float = 0.0

var hit_target : bool = false

var power : int = 0

signal charged
signal fired

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	apply_color_palette()
	beam.add_point(Vector2.ZERO)
	beam.add_point(Vector2.ZERO)
	inner_beam.add_point(Vector2.ZERO)
	inner_beam.add_point(Vector2.ZERO)
	set_process(false)

func apply_color_palette():
	beam.default_color = Globals.color_palettes[Globals.current_palette][5]
	inner_beam.default_color = Globals.color_palettes[Globals.current_palette][2]
	charge.self_modulate = Globals.color_palettes[Globals.current_palette][5]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var query : PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, global_position + global_transform.x  * 640, 52)
	query.collide_with_areas = true
	query.hit_from_inside = true
	var state : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	var result : Dictionary = state.intersect_ray(query)
	if result:
		beam.points[1] = to_local(result.position)
		inner_beam.points[1] = to_local(result.position)
		if result.collider is HitBox and !hit_target:
			result.collider.receive_damage(power, global_transform.x)
			hit_target = true
			
	
	damage_counter += delta
	if damage_counter > 0.15:
		damage_counter = 0.0
		hit_target = false
	
	elapsed_time += delta
	if elapsed_time > shoot_duration:
		set_process(false)
		elapsed_time = 0.0
		beam.points[1] = Vector2.ZERO
		inner_beam.points[1] = Vector2.ZERO
		var tw : Tween = create_tween()
		tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(charge, "scale", Vector2.ZERO, 0.25)
		await tw.finished
		fired.emit()

func charge_beam():
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(charge, "scale", Vector2(1, 1), 1.0)
	await tw.finished
	charged.emit()
	
func fire():
	set_process(true)
