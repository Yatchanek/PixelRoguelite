extends StaticBody2D
class_name Obstacle

var power : int = 999


@onready var body: Line2D = $Body


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	apply_color_palette()


func apply_color_palette():
	body.default_color = Globals.color_palettes[Globals.current_palette][5]
