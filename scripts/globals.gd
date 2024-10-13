extends Node

var rng : RandomNumberGenerator

const PLAYFIELD_WIDTH : int = 280
const PLAYFIELD_HEIGHT : int = 140
const WALL_THICKNESS : int = 4

func _ready() -> void:
	rng = RandomNumberGenerator.new()
