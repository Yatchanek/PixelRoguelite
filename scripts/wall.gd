extends StaticBody2D
class_name Wall

@onready var lines: Node2D = $Lines

var orientation : int = 1
var has_door : bool = false
var length : int
var power : int = 999

var door : Door

signal door_entered

func _ready() -> void:
	if has_node("Door"):
		door = $Door
		has_door = true
	apply_color_palette()

func apply_color_palette(boss_room : bool = false):
	for line : Line2D in lines.get_children():
		if boss_room:
			line.default_color =  Globals.color_palettes[Globals.current_palette][1]
		else:
			line.default_color =  Globals.color_palettes[Globals.current_palette][5]
	
func activate_door():
	if has_door:
		door.activate()
		
func deactivate_door():
	if has_door:
		door.deactivate()

func _on_door_entered():
	door_entered.emit(orientation)
