extends Area2D
class_name Pickup

@onready var sprite: Sprite2D = $Sprite

var type : int

signal collected

func _ready() -> void:
	apply_color_palette()
	sprite.region_rect.position.x = type * 16
	if type == 0:
		sprite.offset = Vector2(1, -1)

func apply_color_palette():
	sprite.self_modulate = Globals.color_palettes[Globals.current_palette][3]
	


func _on_body_entered(body: Player) -> void:
	if type == 0:
		SoundManager.play_effect(SoundManager.Effects.PICKUP_HEALTH)
		body.heal(5)
	else:
		SoundManager.play_effect(SoundManager.Effects.PICKUP_SHIELD)
		body.get_shield(5)
	$CollisionShape2D.set_deferred("disabled", true)
	collected.emit()
	queue_free()
