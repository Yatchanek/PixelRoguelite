extends Enemy
class_name Boss

const explosion_scene = preload("res://scenes/explosion.tscn")

var waypoint : Vector2i
var wander_interval : float = 1.5
var elapsed_time : float = 0

func explode(dir : Vector2):
	for i in randi_range(5, 7):
		var explosion : Explosion = explosion_scene.instantiate()
		var colors : Array[Color] = [primary_color, secondary_color, tertiary_color]
			
		explosion.initialize(dir, colors, i * 0.15)
		exploded.emit(explosion, global_position + Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(-16, 16))
	SoundManager.play_effect(SoundManager.Effects.EXPLOSION)

func wander(delta : float):
	elapsed_time += delta
	if elapsed_time > wander_interval:
		waypoint = select_destination(1, 6, 1, 2, 128)
		elapsed_time -= wander_interval
		wander_interval = randf_range(1.25, 2.0)
		

func select_destination(min_x : int = 0, max_x : int = 7, min_y : int = 0, max_y : int = 3, min_dist = 128) -> Vector2i:
	var destination : Vector2i
	destination = Vector2(32, 32) + Utils.get_random_coords(min_x, max_x, min_y, max_y) * 64
	while destination.distance_squared_to(position) < min_dist * min_dist:
		destination = Vector2(32, 32) + Utils.get_random_coords() * 64
	return destination
