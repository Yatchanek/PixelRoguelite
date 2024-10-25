extends TextureRect
class_name MapRoom


var map_scale : Vector2 = Vector2.ONE
var room_idx : int = 0

func _ready() -> void:
	custom_minimum_size = Vector2(32 * map_scale.x, 32 * map_scale.y)
	texture.region.position.x = room_idx * 32

func update():
	custom_minimum_size = Vector2(32 * map_scale.x, 32 * map_scale.y)
	texture.region.position.x = room_idx * 32	
