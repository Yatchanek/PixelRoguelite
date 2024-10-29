extends StaticBody2D
class_name OuterWall

@onready var lines: Node2D = $Lines

const door_scene : PackedScene = preload("res://scenes/door.tscn")

var orientation : int = 1
var has_door : bool = true
var length : int
var power : int = 999

var door : Door


var door_closed_upon_creation : bool

signal door_entered

func _ready() -> void:
	var line : Line2D = Line2D.new()
	line.width = Globals.WALL_THICKNESS
	line.default_color =  Globals.color_palettes[Globals.current_palette][5]
	line.add_point(Vector2(-Globals.WALL_THICKNESS * 0.5, 0))
	

	
	
	if orientation % 2 == 0:
		length = Globals.PLAYFIELD_WIDTH
	else:
		length = Globals.PLAYFIELD_HEIGHT
	
	rotation = PI / 2 * orientation
	#print(length)	
	if !has_door:
		line.add_point(Vector2(length + Globals.WALL_THICKNESS * 0.5, 0))
		lines.call_deferred("add_child", line)	
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = RectangleShape2D.new()
		collision_shape.shape.size = Vector2(length, Globals.WALL_THICKNESS)
		collision_shape.position = Vector2(length * 0.5, 0)
		
		call_deferred("add_child", collision_shape)
		
	else:
		line.add_point(Vector2(length * 0.5 - Globals.EXIT_HALF_WIDTH, 0))
		lines.call_deferred("add_child", line)
		
		line = Line2D.new()
		line.width = Globals.WALL_THICKNESS
		line.default_color =  Globals.color_palettes[Globals.current_palette][5]

		line.add_point(Vector2(length * 0.5 + Globals.EXIT_HALF_WIDTH, 0))
		line.add_point(Vector2(length + Globals.WALL_THICKNESS * 0.5, 0))
		lines.call_deferred("add_child", line)
	
		var collision_shape : CollisionShape2D = CollisionShape2D.new()
		collision_shape.shape = RectangleShape2D.new()
		collision_shape.shape.size = Vector2(length * 0.5 - Globals.EXIT_HALF_WIDTH, Globals.WALL_THICKNESS)
		collision_shape.position.x = (length * 0.5 - Globals.EXIT_HALF_WIDTH) * 0.5
		call_deferred("add_child", collision_shape)						
		
		collision_shape = CollisionShape2D.new()
		collision_shape.shape = RectangleShape2D.new()
		collision_shape.shape.size = Vector2(length * 0.5 - Globals.EXIT_HALF_WIDTH, Globals.WALL_THICKNESS)
		collision_shape.position.x = length * 0.5 + Globals.EXIT_HALF_WIDTH + (length * 0.5 - Globals.EXIT_HALF_WIDTH) * 0.5
		call_deferred("add_child", collision_shape)
		
		door = door_scene.instantiate() as Door
		door.position = Vector2(length * 0.5, 0)
		door.entered.connect(_on_door_entered)
		call_deferred("add_child", door)
		
	var vertices : PackedVector2Array = [
		Vector2(0, -Globals.WALL_THICKNESS),
		Vector2(length, -Globals.WALL_THICKNESS),
		Vector2(length, Globals.WALL_THICKNESS),
		Vector2(0, Globals.WALL_THICKNESS),
	]

	var occluder : LightOccluder2D = LightOccluder2D.new()
	occluder.occluder = OccluderPolygon2D.new()
	occluder.occluder.set_polygon(vertices)
	occluder.position.y = -Globals.WALL_THICKNESS * 0.5
	
	add_child(occluder)

func apply_color_palette():
	for line : Line2D in lines.get_children():
		line.default_color =  Globals.color_palettes[Globals.current_palette][5]
	if is_instance_valid(door):
		door.apply_color_palette()
	
func activate_door():
	if has_door:
		door.activate()
		
func deactivate_door():
	if has_door:
		door.deactivate()

func _on_door_entered():
	door_entered.emit(orientation)
