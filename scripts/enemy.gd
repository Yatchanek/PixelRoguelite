extends CharacterBody2D
class_name Enemy

@export var hp : int = 1
@export var speed : float = 64
@export var target : CharacterBody2D

signal exploded(pos : Vector2)

func take_damage(amount : int):
	hp -= amount
	if hp <= 0:
		exploded.emit(global_position)
		queue_free()
		
