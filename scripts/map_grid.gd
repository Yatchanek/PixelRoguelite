extends GridContainer

var player_map_coords : Vector2i = Vector2i(-INF, -INF)
var cell_size : Vector2 = Vector2(32, 32)
var map_scale : Vector2 = Vector2.ONE

func _draw() -> void:
	if player_map_coords.x > -999999:
		draw_circle(Vector2(
			cell_size.x * 0.5 + player_map_coords.x * cell_size.x, 
			cell_size.y * 0.5 + player_map_coords.y * cell_size.y), 
			4 * map_scale.x, Color.RED)
