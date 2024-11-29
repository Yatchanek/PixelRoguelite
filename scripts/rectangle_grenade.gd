extends CharacterBody2D
class_name RectangleGrenade

@onready var body: Polygon2D = $Body
@onready var body_2: Polygon2D = $Body/Body2
@onready var body_3: Polygon2D = $Body/Body2/Body3

const explosion_scene = preload("res://scenes/explosion.tscn")
const fragment_scene = preload("res://scenes/fragment.tscn")

var colors : PackedColorArray = []

var has_exploded : bool = false

signal armed
signal exploded
signal fragment_fired(fragment : Node2D, pos : Vector2)


func _ready() -> void:
	body.color = colors[0]
	body_2.color = colors[1]
	body_3.color = colors[2]
	set_physics_process(false)
	
	var tw : Tween = create_tween()
	tw.tween_property(body, "modulate:a", 1.0, 0.75)
	await tw.finished
	armed.emit(self)
	
	tw = create_tween()
	tw.set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(body, "scale", Vector2(0.5, 0.5), 0.25)
	tw.parallel().tween_property(body_2, "scale", Vector2(0.5, 0.5), 0.25)
	tw.parallel().tween_property(body_3, "scale", Vector2(0.5, 0.5), 0.25)
	tw.tween_property(body, "scale", Vector2.ONE, 0.25)
	tw.parallel().tween_property(body_2, "scale", Vector2.ONE, 0.25)
	tw.parallel().tween_property(body_3, "scale", Vector2.ONE, 0.25)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	velocity = lerp(velocity, Vector2.ZERO, 0.025)
	var collision : KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		move_and_collide(collision.get_remainder().bounce(collision.get_normal()) * delta)
	
	if velocity.length_squared() < 100:
		set_physics_process(false)
		await get_tree().create_timer(0.25).timeout
		explode()

func explode(spawn_fragments : bool = true):
	if has_exploded: 
		return
	
	var explosion : Explosion = explosion_scene.instantiate()
	explosion.initialize(Vector2.ZERO, colors)
	exploded.emit(explosion, global_position)
	if spawn_fragments:
		for i in randi_range(12, 16):
			var fragment = fragment_scene.instantiate()
			fragment.rotation = randf_range(0, TAU)
			fragment_fired.emit(fragment, global_position)
			fragment.color = [body.color, body_2.color, body_3.color].pick_random()
	has_exploded = true
	queue_free()	
		
func take_damage(_amount: int, dir : Vector2):
	explode(dir != Vector2.ZERO)
