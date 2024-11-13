extends Sprite2D

var basic_rotation : float
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	basic_rotation = rotation
	random_rotate()


func random_rotate():
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "rotation", randf_range(basic_rotation - PI / 12, basic_rotation + PI / 12), randf_range(0.2, 0.3))
	tw.finished.connect(random_rotate)
