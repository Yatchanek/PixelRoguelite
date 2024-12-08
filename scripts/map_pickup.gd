extends Area2D

@onready var sprite: Sprite2D = $Sprite

signal collected

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	EventBus.map_found.emit()
	Globals.map_pickup_coords = []
	queue_free()
