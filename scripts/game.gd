extends Node

@onready var hud: HUD = $Hud
@onready var world: Node2D = $World


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Globals.new_game()
