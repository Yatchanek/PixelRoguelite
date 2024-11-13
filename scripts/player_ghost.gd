extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tw : Tween = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.finished.connect(queue_free)
