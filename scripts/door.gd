extends StaticBody2D
class_name Door

@onready var visuals: Line2D = $Visuals
@onready var door_collision_shape: CollisionShape2D = $DoorArea/CollisionShape2D
@onready var static_collision_shape: CollisionShape2D = $CollisionShape2D

var idx : int
var power : int = 999

signal entered

func _ready() -> void:
	apply_color_palette()

func apply_color_palette():
	visuals.default_color = Globals.color_palettes[Globals.current_palette][3]

func activate():
	door_collision_shape.set_deferred("disabled", true)
	static_collision_shape.set_deferred("disabled", false)
	var tw : Tween = create_tween()
	tw.tween_property(visuals, "modulate:a", 1.0, 0.5)
	
func deactivate():
	var tw : Tween = create_tween()
	tw.tween_property(visuals, "modulate:a", 0.0, 0.5)
	await tw.finished
	door_collision_shape.set_deferred("disabled", false)
	static_collision_shape.set_deferred("disabled", true)



func _on_body_entered(_body: Node2D) -> void:
	entered.emit()
