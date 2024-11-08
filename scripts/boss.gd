extends Enemy
class_name Boss

const explosion_scene = preload("res://scenes/explosion.tscn")

func explode(dir : Vector2):
	for i in randi_range(5, 7):
		var explosion : Explosion = explosion_scene.instantiate()
		var colors : Array[Color] = [primary_color, secondary_color, tertiary_color]
			
		explosion.initialize(dir, colors, i * 0.15)
		exploded.emit(explosion, global_position + Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(-16, 16))
	SoundManager.play_effect(SoundManager.Effects.EXPLOSION)
