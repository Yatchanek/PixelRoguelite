extends Explosion
class_name DirectionalExplosion


func initialize(dir : Vector2, colors : Array[Color], _delay : float = 0.0):
	process_material.direction = Vector3(dir.x, dir.y, 0)
	var gradient : Gradient = Gradient.new()
	gradient.colors = []
	gradient.offsets = []
	var step : float = 1.0 / (colors.size() - 1)
	for i in colors.size():
		gradient.add_point(step * i, colors[i])
		
	process_material.color_initial_ramp.gradient = gradient
	delay = _delay
