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

var player : Player
var leveled_up : bool = false

var gate_key_coords : Dictionary = {}
var keys_collected : Array[int] = []

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	create_color_palettes()

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

func get_coords_in_distance_range(min_dist : int, max_dist : int) -> Vector2i:
	return Vector2i(
		randi_range(min_dist, max_dist) * pow(-1, randi() % 2),
		randi_range(min_dist, max_dist) * pow(-1, randi() % 2),
	)
		
func _on_player_ready(_player : Player):
	player = _player

func reset():
	leveled_up = false
	room_grid = {}
	gate_key_coords = {}
	keys_collected = []
	
	for i in 9:
		var coords : Vector2i = get_coords_in_distance_range(Settings.zone_size + Settings.zone_size * i, Settings.zone_size + Settings.zone_size * (i + 1) - 1)
		gate_key_coords[coords] = i
