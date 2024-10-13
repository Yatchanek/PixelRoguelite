extends Node

@export var palette_images : Array[Texture2D] = []

var explosion_material : ParticleProcessMaterial = preload("res://explosion.tres")

var rng : RandomNumberGenerator

const PLAYFIELD_WIDTH : int = 280
const PLAYFIELD_HEIGHT : int = 144
const WALL_THICKNESS : int = 4

var current_palette : int = 0

var color_palettes : Array[PackedColorArray] = [
]



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
		
