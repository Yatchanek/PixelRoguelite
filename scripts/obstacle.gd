extends StaticBody2D
class_name Obstacle

var shape : PackedVector2Array
var power : int = 1

@onready var body: Polygon2D = $Polygon2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Polygon2D.set_polygon(shape)
	$CollisionPolygon2D.set_polygon(shape)
	apply_color_palette()

func apply_color_palette():
	body.color = Globals.color_palettes[Globals.current_palette][5]
