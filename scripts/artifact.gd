extends Area2D
class_name Artifact

var coords : Vector2i
var number : int

signal collected

func _on_body_entered(body: Node2D) -> void:
	EventBus.artifact_collected.emit(number)
	Globals.artifacts_collected.append(number)
	collected.emit()
	Globals.artifact_coords.erase(coords)
	queue_free()
