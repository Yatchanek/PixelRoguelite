extends Sprite2D


func _ready() -> void:
	self_modulate = Globals.color_palettes[Globals.current_palette][3]
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.finished.connect(queue_free)
	
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	tw.tween_interval(0.1)
	tw.tween_property(self, "modulate:a", 0.0, 0.1)
