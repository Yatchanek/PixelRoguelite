extends Area2D
class_name Door

@onready var visuals: Polygon2D = $Visuals
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var static_collision_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D

var orientation : int
var idx : int

var active_on_enter : bool

signal entered

func _ready() -> void:
	var points : PackedVector2Array = [
		Vector2(-Globals.DOOR_HALF_WIDTH, -Globals.WALL_THICKNESS * 0.5),
		Vector2(Globals.DOOR_HALF_WIDTH, -Globals.WALL_THICKNESS * 0.5),
		Vector2(Globals.DOOR_HALF_WIDTH, Globals.WALL_THICKNESS * 0.5),
		Vector2(-Globals.DOOR_HALF_WIDTH, Globals.WALL_THICKNESS * 0.5)		
	]
	
	collision_shape.shape.size = Vector2(Globals.DOOR_HALF_WIDTH * 2 - 20, Globals.WALL_THICKNESS)
	static_collision_shape.shape.size = Vector2(Globals.EXIT_HALF_WIDTH * 2, Globals.WALL_THICKNESS)
	collision_shape.position.y = -Globals.WALL_THICKNESS
	visuals.set_polygon(points)
	
	rotation = idx * PI / 2
	
	apply_color_palette()
	if active_on_enter:
		activate()

func apply_color_palette():
	visuals.color = Globals.color_palettes[Globals.current_palette][3]

func activate():
	collision_shape.set_deferred("disabled", true)
	static_collision_shape.set_deferred("disabled", false)
	var tw : Tween = create_tween()
	tw.tween_property(visuals, "modulate:a", 1.0, 0.5)
	
func deactivate():
	var tw : Tween = create_tween()
	tw.tween_property(visuals, "modulate:a", 0.0, 0.5)
	await tw.finished
	collision_shape.set_deferred("disabled", false)
	static_collision_shape.set_deferred("disabled", true)



func _on_body_entered(body: Node2D) -> void:
	entered.emit()
