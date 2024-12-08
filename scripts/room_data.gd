extends Resource
class_name RoomData

var coords : Vector2i
var layout_type : int
var first_visited : int
var last_cleared : int
var obstacle_count : int
var max_enemies : int
var rng_seed : int
var gate_key_collected : bool = false
var boss_defeated : bool = false
var cleared : bool = false
var depth : int

var pickup_spawned : bool = false
var pickup_collect_time : int = 0
var pickup_coords : Vector2i
var pickup_type : int = -1
var map_spawned : bool = false
var map_coords : Vector2i

func print_data():
	prints(
		"Coords:", coords, "\n",
		"Layout:", layout_type, "\n",
		"First visit:", first_visited, "\n",
		"Last clear:", last_cleared, "\n",
		"Max enemies:", max_enemies, "\n",
		"Obstacles:", obstacle_count, "\n",
		"RNG seed:", rng_seed
	)
