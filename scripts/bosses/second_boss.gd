extends Boss
class_name SecondGuardian

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer
@onready var shoot_timer: Timer = $ShootTimer
@onready var body: Node2D = $Body


const grenade_scene : PackedScene = preload("res://scenes/rectangle_grenade.tscn")

var elapsed_time : float = 0.0

var tick : int = 0

var current_state : State

var shots_fired : int = 0
var attack_mode : AttackMode
var rotation_dir : int
var rotation_speed : float

enum AttackMode {
	ROTATE,
	PULSE,
	MISSILE
}

enum State {
	MOVE,
	KNOCKBACK
}

signal bullet_fired(bullet : Node2D, pos : Vector2)
signal missile_fired(missile : Node2D, pos : Vector2)


func _ready() -> void:
	setup()
	apply_color_palette()
	create_body()
	set_physics_process(false)
	set_process(false)
		
	var tw : Tween = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(body, "modulate:a", 1.0, 1.0)
	await tw.finished
	set_physics_process(true)
	set_process(true)

	current_state = State.MOVE

	
	rotation_dir = pow(-1, randi() % 2)
	rotation_speed = randf_range(PI * 1.5, TAU)	
	timer.start(1.0)
	shoot_timer.start(fire_interval)

func _process(delta: float) -> void:
	if current_state == State.MOVE:
		elapsed_time += delta
		if elapsed_time > 1.5:
			nav_agent.target_position = Vector2i(32, 32) + Utils.get_random_coords(1, 6, 1, 2) * 64
			elapsed_time = 0
			
	health_bar_pivot.global_rotation = 0

	

func _physics_process(_delta: float) -> void:
	if current_state == State.KNOCKBACK:
		velocity = lerp(velocity, Vector2.ZERO, 0.15)
		if velocity.length_squared() < 100:
			current_state = State.MOVE

	else:	
		if nav_agent.is_navigation_finished():
			velocity = lerp(velocity, Vector2.ZERO, 0.1)
			move_and_slide()
			if can_shoot:
				shoot()	
			return
		
		velocity = lerp(velocity, global_position.direction_to(nav_agent.get_next_path_position()) * speed, 0.25)

	if can_shoot:
		shoot()	
		
	move_and_slide()

func shoot():
	var grenade : RectangleGrenade = grenade_scene.instantiate()
	grenade.position = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(-16, 16)
	grenade.colors = [primary_color, secondary_color, tertiary_color]
	grenade.armed.connect(_on_grenade_ready)
	call_deferred("add_child", grenade)
	can_shoot = false
	shoot_timer.start(fire_interval)

func _on_grenade_ready(grenade : RectangleGrenade):
	if Globals.player.dead:
		return
	var pos : Vector2 = grenade.global_position
	remove_child(grenade)
	bullet_fired.emit(grenade, pos)
	grenade.velocity = pos.direction_to(Globals.player.global_position) * randi_range(384, 640)
	grenade.set_physics_process(true)

func create_body():
	for polygon : Polygon2D in body.get_children():
		polygon.set_polygon(create_random_rect())
		polygon.position = Vector2(randi_range(-16, 16 - polygon.polygon[1].x), randi_range(-16, 16 - polygon.polygon[2].y))
		polygon.color = Globals.color_palettes[Globals.current_palette][randi() % 6]

func flip_parts():
	var parts_array : Array = range(0, body.get_child_count())
	parts_array.shuffle()
	
	while parts_array.size() > 1:	
		var x : int = parts_array.pop_back()
		
		var y : int = parts_array.pop_back()
			
		var rect_1 : Polygon2D = body.get_child(x)
		var rect_2 : Polygon2D = body.get_child(y)
		
		var time : float = randf_range(0.2, 0.5)
		
		var tw: Tween = create_tween()
		tw.set_trans([Tween.TRANS_EXPO, Tween.TRANS_CUBIC, Tween.TRANS_QUAD, Tween.TRANS_SINE].pick_random())
		tw.set_ease([Tween.EASE_IN_OUT, Tween.EASE_IN, Tween.EASE_OUT, Tween.EASE_OUT_IN].pick_random())
		tw.tween_property(rect_1, "position", rect_2.position, time)
		tw.parallel().tween_property(rect_2, "position", rect_1.position, time)
	
	timer.start(0.5 + randf_range(0.1, 0.3))

func create_random_rect() -> PackedVector2Array:
	var points : PackedVector2Array = []
	var size : Vector2 = Vector2(randi_range(12, 28), randi_range(6, 16))
	points.append(Vector2.ZERO)
	points.append(Vector2(size.x, 0))
	points.append(size)
	points.append(Vector2(0, size.y))
	return points


func apply_color_palette():
	primary_color = Globals.color_palettes[Globals.current_palette][5]
	secondary_color = Globals.color_palettes[Globals.current_palette][4]
	tertiary_color = Globals.color_palettes[Globals.current_palette][3]
	
	#body.self_modulate = primary_color
	#chasis.self_modulate = secondary_color
	#sides.self_modulate = tertiary_color


func knockback(dir : Vector2):
	for rect : Polygon2D in body.get_children():
		var prev_color : Color = rect.color
		
		var tw : Tween = create_tween()
		tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
		tw.tween_property(rect, "color", Color.WHITE, 0.1)
		tw.tween_interval(0.1)
		tw.tween_property(rect, "color", prev_color, 0.1)


	velocity = dir * speed * 1.25
	current_state = State.KNOCKBACK


func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func _on_timer_timeout() -> void:
	flip_parts()
