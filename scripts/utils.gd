extends Node
class_name Utils

static func get_manhattan_distance(coords_a : Vector2i, coords_b : Vector2i) -> int:
	return abs(coords_a.x - coords_b.x) + abs(coords_a.y - coords_b.y)

static func get_random_coords(min_x : int = 0, max_x : int = 7, min_y : int = 0, max_y : int = 3) -> Vector2i:
	return Vector2i(randi_range(min_x, max_x), randi_range(min_y, max_y))

static func get_random_coordsf(min_x : int = 0, max_x : int = 7, min_y : int = 0, max_y : int = 3) -> Vector2:
	return Vector2(randi_range(min_x, max_x), randi_range(min_y, max_y))

static func get_coords(pos : Vector2i) -> Vector2i:
	return(Vector2(int(pos.x / 64), int(pos.y / 64)))		

static func get_depth(coords : Vector2i) -> int:
	return max(abs(coords.x), abs(coords.y))

static func is_within_range(coords_a : Vector2i, coords_b : Vector2i, dist : int) -> bool:
	if abs(coords_a.x - coords_b.x) <= dist and abs(coords_a.y - coords_b.y) <= dist:
		return true
	return false
