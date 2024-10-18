extends Enemy
class_name KamikazeEnemy

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer
@onready var body: Sprite2D = $Body
@onready var chasis: Sprite2D = $Body/Chasis

var elapsed_time : float = 0.0

var tick : int = 0

var current_state : State

enum State {
	MOVE,
	KNOCKBACK
}


func _ready() -> void:
	apply_color_palette()
	set_physics_process(false)
	set_process(false)
	$Hitbox.deactivate()
	var tw : Tween = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(body, "modulate:a", 1.0, 0.5)
	await tw.finished
	$Hitbox.activate()
	set_physics_process(true)
	set_process(true)
	timer.start()
	
	current_state = State.MOVE

func _process(_delta: float) -> void:
	if current_state == State.MOVE:
		tick += 1
		if tick % 2 == 0 and target:
			nav_agent.target_position = target.global_position
		

func _physics_process(delta: float) -> void:
	if current_state == State.KNOCKBACK:
		elapsed_time += delta
		if elapsed_time > 0.25:
			elapsed_time = 0.0
			current_state = State.MOVE
		else:
			move_and_slide()
	else:	
		if nav_agent.is_navigation_finished() or !target:
			velocity = lerp(velocity, Vector2.ZERO, 0.1)
			move_and_slide()
			return
		

		var intended_velocity : Vector2 = global_position.direction_to(nav_agent.get_next_path_position()) * speed
		nav_agent.set_velocity(intended_velocity)
	#


func apply_color_palette():
	body.self_modulate = Globals.color_palettes[Globals.current_palette][3]
	chasis.self_modulate = Globals.color_palettes[Globals.current_palette][4]

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if current_state != State.MOVE:
		return
	velocity = safe_velocity
	if safe_velocity != Vector2.ZERO:
		rotation = velocity.angle()
	elif is_instance_valid(target):
		var target_transform = global_transform.looking_at(target.global_position)
		global_transform = global_transform.interpolate_with(target_transform, 0.75)
		
	move_and_slide()

func knockback(dir : Vector2):
	velocity = dir * speed * 1.25
	current_state = State.KNOCKBACK
	if target:
		nav_agent.target_position = target.global_position

func _on_timer_timeout() -> void:
	if target:
		nav_agent.target_position = target.global_position
