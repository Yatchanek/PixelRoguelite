extends Resource
class_name RoomData

var coords : Vector2i
var layout_type : int
var first_visited : int
var last_visited : int
var obstacle_count : int
var max_enemies : int
var rng_seed : int
var gate_key_collected : bool = false
var boss_defeated : bool = false
var cleared : bool = false
var depth : int

func print_data():
	prints(
		"Coords:", coords, "\n",
		"Layout:", layout_type, "\n",
		"First visit:", first_visited, "\n",
		"Last visit:", last_visited, "\n",
		"Max enemies:", max_enemies, "\n",
		"Obstacles:", obstacle_count, "\n",
		"RNG seed:", rng_seed
	)
