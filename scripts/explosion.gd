extends GPUParticles2D
class_name Explosion

var delay : float

func _ready() -> void:
	finished.connect(queue_free)
	if delay > 0:
		await get_tree().create_timer(delay).timeout
		emitting = true
	else:
		emitting = true
	

func initialize(dir : Vector2, colors : Array[Color], _delay : float = 0.0):
	var gradient : Gradient = Gradient.new()
	gradient.colors = []
	gradient.offsets = []
	var step : float = 1.0 / (colors.size() - 1)
	for i in colors.size():
		gradient.add_point(step * i, colors[i])
		
	process_material.color_initial_ramp.gradient = gradient

	delay = _delay
