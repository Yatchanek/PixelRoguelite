extends Area2D
class_name HurtBox

@export var damage : int

func deactivate():
	$CollisionShape2D.set_deferred("disabled", true)
	
func activate():
	$CollisionShape2D.set_deferred("disabled", false)
