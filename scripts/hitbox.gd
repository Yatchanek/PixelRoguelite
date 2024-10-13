extends Area2D
class_name HitBox

@export var target : CharacterBody2D

func _on_area_entered(area: Area2D) -> void:
	if is_instance_valid(target):
		target.take_damage(area.damage)

func _on_body_entered(body: Node2D) -> void:
	if is_instance_valid(target):
		target.take_damage(body.damage)

func receive_damage(amount : int):
	if is_instance_valid(target):
		target.take_damage(amount)	

func deactivate():
	$CollisionShape2D.set_deferred("disabled", true)
	
func activate():
	$CollisionShape2D.set_deferred("disabled", false)
