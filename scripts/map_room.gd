extends TextureRect
class_name MapRoom

@onready var exits: Control = $Exits
@onready var floor: ColorRect = $Floor

var cell_size = Vector2(32, 32)
var room_idx : int = 0

func _ready() -> void:
	custom_minimum_size = cell_size
	size = cell_size
	texture.region.position.x = room_idx * 32
	apply_color_palette()

func apply_color_palette():
	self_modulate = Globals.color_palettes[Globals.current_palette][5]
	floor.color = Globals.color_palettes[Globals.current_palette][7]

		
	for exit : ColorRect in exits.get_children():
		exit.color = Globals.color_palettes[Globals.current_palette][7]

func update_texture():
	texture.region.position.x = room_idx * 32
	floor.visible = room_idx > 0
	for i in 4:
		exits.get_child(i).visible = room_idx & 1 << i != 0
	

func update_size():
	custom_minimum_size = cell_size
	size = cell_size
