extends Node

@export var palette_images : Array[Texture2D] = []

var missile_material : ParticleProcessMaterial = preload("res://missile.tres")

var rng : RandomNumberGenerator

const PLAYFIELD_WIDTH : int = 512
const PLAYFIELD_HEIGHT : int = 256
const WALL_THICKNESS : int = 8
const DOOR_HALF_WIDTH : int = 56
const EXIT_HALF_WIDTH : int = 60
const CELL_SIZE : int = 16

var room_grid : Dictionary = {}

var current_palette : int = 0

var color_palettes : Array[PackedColorArray] = [
]

var maze_data : PackedByteArray = []
var maze_size : int

var player : Player
var leveled_up : bool = false

var gate_key_coords : Dictionary = {}
var keys_collected : Array[int] = []
var keys_returned : Array[int] = []

var map_pickup_coords : Array[Vector2i] = []

var game_completed : bool = false

var max_layer : int

signal keys_placed

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	
	create_color_palettes()
	current_palette = Settings.color_palette
	print(current_palette)
	if current_palette > color_palettes.size() - 1:
		current_palette = color_palettes.size() - 1
		Settings.color_palette = current_palette
	
func new_game():
	
	reset()
	
func create_color_palettes():
	var files : PackedStringArray = DirAccess.get_files_at("res://graphics/color_palettes")
	for file_name : String in files:
		if file_name.get_extension() == "import":
			file_name = file_name.replace(".import", "")
			palette_images.append(ResourceLoader.load("res://graphics/color_palettes/" + file_name))
		
	for image : Texture2D in palette_images:
		var img : Image = image.get_image()
		var palette : PackedColorArray = []
		for i in img.get_width():
			palette.append(img.get_pixel(i, 0))
		color_palettes.append(palette)

func adjust_missile_palette():
	var gradient : Gradient = Gradient.new()
	for i in 8:
		gradient.add_point(i / 7.0, color_palettes[current_palette][i])
		
	missile_material.color_initial_ramp.gradient = gradient

func get_coords_in_distance_range(min_dist : int, max_dist : int, quart : int = 1) -> Vector2i:
	var coords : Vector2i
	if randf() < 0.5:
		var side : int = 1
		if quart >= 3:
			side = -1
		coords.x = randi_range(min_dist, max_dist) * side
		if quart == 1 or quart == 4:
			coords.y = -randi_range(0, max_dist)
		else:
			coords.y = randi_range(1, max_dist)
	else:
		var side : int = 1
		if quart == 1 or quart == 4:
			side = -1	
		coords.y = randi_range(min_dist, max_dist) * side
		if quart < 3:
			coords.x = randi_range(0, max_dist)
		else:
			coords.x = -randi_range(1, max_dist)	
	
	return coords
		
func _on_player_ready(_player : Player):
	player = _player

func reset():
	leveled_up = false
	game_completed = false
	room_grid = {}
	gate_key_coords = {}
	keys_collected = []
	keys_returned = []
	place_keys()
	place_maps()

func place_maps():
	var quart : int = 1
	for i in 4:
		var coords : Vector2i
		var min_dist : int = max(4, Settings.zone_size)
		var max_dist : int = min(Settings.zone_size * (max_layer + 1) - 1, 10)
		var accepted : bool = false
		while !accepted:
			coords = get_coords_in_distance_range(min_dist, max_dist, quart)
			if !gate_key_coords.has(coords):
				accepted = true
		
		quart += 1
	
func place_keys():
	max_layer = 0
	var max_keys_in_layer : int = 2
	var quart : int = 1
	for i in 9:
		if i > 0 and i % max_keys_in_layer == 0:
			max_layer += 1
		var coords : Vector2i
		var accepted : bool = false
		while !accepted:
			var is_ok : bool = true
			coords = get_coords_in_distance_range(2 + Settings.zone_size * max_layer, 2 + Settings.zone_size * (max_layer + 1) - 1, quart)
			#for placed_coords : Vector2i in gate_key_coords.keys():
				#if Utils.get_manhattan_distance(placed_coords, coords) < 2:
					#is_ok = false
					#break
					
			if is_ok:
				accepted = true
				
		gate_key_coords[coords] = i
		quart = wrapi(quart + 1, 1, 5)

	keys_placed.emit()
