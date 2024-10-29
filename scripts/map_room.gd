extends TextureRect
class_name MapRoom


var cell_size = Vector2(32, 32)
var room_idx : int = 0

func _ready() -> void:
	custom_minimum_size = cell_size
	size = cell_size
	texture.region.position.x = room_idx * 32

func update_texture():
	texture.region.position.x = room_idx * 32	

func update_size():
	custom_minimum_size = cell_size
	size = cell_size
