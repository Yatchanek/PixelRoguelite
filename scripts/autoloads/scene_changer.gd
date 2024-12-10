extends Node

@export var title_screen_scene : PackedScene
@export var game_scene : PackedScene

@onready var veil: ColorRect = $CanvasLayer/Veil

signal scene_changed

func _ready() -> void:
	change_scene(title_screen_scene)

func change_scene(target_scene : PackedScene):
	if veil.modulate.a < 1.0:
		var tw : Tween = create_tween()
		tw.tween_property(veil, "modulate:a", 1.0, 1.0)	
		await tw.finished
		get_tree().call_deferred("change_scene_to_packed", target_scene)
		tw = create_tween()
		tw.tween_property(veil, "modulate:a", 0.0, 1.0)
		await tw.finished
		scene_changed.emit()
	else:
		get_tree().call_deferred("change_scene_to_packed", target_scene)
		var tw : Tween = create_tween()
		tw.tween_property(veil, "modulate:a", 0.0, 1.0)
		await tw.finished
		scene_changed.emit()
