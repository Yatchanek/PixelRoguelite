extends Area2D
class_name GateKey

@onready var body: Sprite2D = $Body

var coords : Vector2i
var number : int

signal collected

func _ready() -> void:
	body.region_rect.position.x = number * 16

func _on_body_entered(_body: Node2D) -> void:
	EventBus.gate_key_collected.emit(number, coords)
	Globals.keys_collected.append(number)
	collected.emit()
	#Globals.gate_key_coords.erase(coords)
	queue_free()
