extends Area2D
class_name HitBox

@export var target : Node2D

func _on_area_entered(area: Area2D) -> void:
	if is_instance_valid(target):
		target.take_damage(area.damage, Vector2.ZERO)

func _on_body_entered(body: Node2D) -> void:
	if is_instance_valid(target) and body != target:
		if body is StaticBody2D and target is Missile:
			target.take_damage(999, Vector2.ZERO)
		else:
			target.take_damage(body.power, Vector2.ZERO)

func receive_damage(amount : int, dir : Vector2):
	if is_instance_valid(target):
		target.take_damage(amount, dir)	

func deactivate():
	$CollisionShape2D.set_deferred("disabled", true)
	
func activate():
	$CollisionShape2D.set_deferred("disabled", false)
