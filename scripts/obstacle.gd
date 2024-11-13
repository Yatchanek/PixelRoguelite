extends StaticBody2D
class_name Obstacle

var power : int = 1

var rotation_offset : int 

var size : int

@onready var body: Polygon2D = $Polygon2D
#@onready var light_occluder: LightOccluder2D = $LightOccluder



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if rotation_offset % 2 == 0:
		size = 128
	else:
		size = 64
	
	var vertices : PackedVector2Array = [
	Vector2(0, -Globals.WALL_THICKNESS * 0.5),
	Vector2(size + 4, -Globals.WALL_THICKNESS * 0.5),
	Vector2(size + 4, Globals.WALL_THICKNESS * 0.5),
	Vector2(0, Globals.WALL_THICKNESS * 0.5),
]

	
	#vertices = Transform2D(rotation_offset * PI / 2, Vector2.ZERO) * vertices
	$Polygon2D.set_polygon(vertices)
	$CollisionPolygon2D.set_polygon(vertices)
	#light_occluder.occluder.set_polygon(vertices)
	apply_color_palette()
	
	rotation = rotation_offset * PI / 2

func apply_color_palette():
	body.self_modulate = Globals.color_palettes[Globals.current_palette][5]
