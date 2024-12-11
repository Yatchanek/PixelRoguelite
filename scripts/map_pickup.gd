extends Area2D

@onready var sprite: Sprite2D = $Sprite

signal collected

func _ready() -> void:
	apply_color_palette()

func _on_body_entered(body: Node2D) -> void:
	SoundManager.play_effect(SoundManager.Effects.PICKUP_MAP)
	EventBus.map_found.emit()
	Globals.map_pickup_coords.clear()
	queue_free()

func apply_color_palette():
	sprite.self_modulate = Globals.color_palettes[Globals.current_palette][3]
