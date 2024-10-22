extends Node

@export var palette_images : Array[Texture2D] = []

var explosion_material : ParticleProcessMaterial = preload("res://explosion.tres")
var missile_material : ParticleProcessMaterial = preload("res://missile.tres")

var rng : RandomNumberGenerator

const PLAYFIELD_WIDTH : int = 512
const PLAYFIELD_HEIGHT : int = 256
const WALL_THICKNESS : int = 8
const DOOR_HALF_WIDTH : int = 56
const EXIT_HALF_WIDTH : int = 60
const CELL_SIZE : int = 16

var current_palette : int = 0

var color_palettes : Array[PackedColorArray] = [
]

var player : Player
var leveled_up : bool = false

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	create_color_palettes()

func create_color_palettes():
	for image : Texture2D in palette_images:
		var img : Image = image.get_image()
		var palette : PackedColorArray = []
		for i in img.get_width():
			palette.append(img.get_pixel(i, 0))
		color_palettes.append(palette)
	adjust_explosion_colors()	

func adjust_explosion_colors():
	var gradient : Gradient = Gradient.new()
	for i in 8:
		gradient.add_point(i * 0.143, color_palettes[current_palette][i])
		
	explosion_material.color_initial_ramp.gradient = gradient
	missile_material.color_initial_ramp.gradient = gradient
		
func _on_player_ready(_player : Player):
	player = _player
