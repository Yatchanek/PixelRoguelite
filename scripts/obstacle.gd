extends StaticBody2D
class_name Obstacle

var shape : PackedVector2Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Polygon2D.set_polygon(shape)
	$CollisionPolygon2D.set_polygon(shape)
