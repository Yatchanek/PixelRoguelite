extends Area2D
class_name Mine

@onready var body: Sprite2D = $Body
@onready var top: Sprite2D = $Body/Top
@onready var timer: Timer = $Timer

const explosion_scene = preload("res://scenes/explosion.tscn")
const fragment_scene = preload("res://scenes/fragment.tscn")

var color_flip_interval : float = 0.5

var primary_color : Color
var secondary_color : Color

var elapsed_time : float = 0

var beep : bool = false

signal exploded(explosion : GPUParticles2D, pos : Vector2)
signal fragment_fired(fragment : Node2D, pos : Vector2)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	apply_color_palette()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	elapsed_time += delta
	if elapsed_time > color_flip_interval:
		color_flip()
		elapsed_time = 0.0
		if beep:
			SoundManager.play_effect(SoundManager.Effects.BEEP)

func apply_color_palette():
	primary_color = Globals.color_palettes[Globals.current_palette][2]
	secondary_color = Globals.color_palettes[Globals.current_palette][3]
	
	body.self_modulate = primary_color
	top.self_modulate = secondary_color
	
func color_flip():
	var tw : Tween = create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if body.self_modulate == primary_color:
		tw.tween_property(body, "self_modulate", secondary_color, color_flip_interval)
		tw.parallel().tween_property(top, "self_modulate", primary_color, color_flip_interval)
	else:
		tw.tween_property(top, "self_modulate", secondary_color, color_flip_interval)
		tw.parallel().tween_property(body, "self_modulate", primary_color, color_flip_interval)

func explode(spawn_fragments : bool = true):
	var explosion : Explosion = explosion_scene.instantiate()
	explosion.initialize(Vector2.ZERO, [primary_color, secondary_color])
	exploded.emit(explosion, global_position)
	if spawn_fragments:
		for i in randi_range(16, 20):
			var fragment = fragment_scene.instantiate()
			fragment.rotation = randf_range(0, TAU)
			fragment.damage = 1
			fragment_fired.emit(fragment, global_position)
			fragment.color = [primary_color, secondary_color].pick_random()
	queue_free()	
	
func take_damage(_amount : int, _dir : Vector2):
	explode()

func _on_timer_timeout() -> void:
	explode()


func _on_body_entered(body: Node2D) -> void:
	color_flip_interval = 0.075
	beep = true
	timer.start(0.75)
