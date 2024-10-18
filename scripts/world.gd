extends Node2D


@onready var player: Player = $Player
@onready var enemies: Node2D = $Enemies
@onready var veil: ColorRect = $"../Veil/Veil"
@onready var background: ColorRect = $"../Background/Background"

const explosion_scene = preload("res://scenes/explosion.tscn")
const room_scene = preload("res://scenes/room.tscn")


var enemy_count : int = 0
var current_room : Room
var rooms_spawned : int = 0

var leveled_up : bool

var room_grid : Dictionary = {}

var directions : Dictionary = {
	0 : Vector2i(0, -1),
	1 : Vector2i(1, 0),
	2 : Vector2i(0, 1),
	3 : Vector2i(-1, 0)
}

var exit_mappings : Dictionary = {
	Vector2i(0, -1) : 0b0001,
	Vector2i(1, 0) : 0b0010,
	Vector2i(0, 1) : 0b0100,
	Vector2i(-1, 0) : 0b1000
}

signal room_changed(coords : Vector2)
signal player_health_changed(value : int)
signal exp_value_changed(value : int)

		
## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	change_room(Vector2i.ZERO, 0)
	apply_color_palette()
	EventBus.upgrade_card_pressed.connect(_on_upgrade_selected)
	EventBus.player_leveled_up.connect(_on_player_leveled_up)
	
func apply_color_palette():
	veil.color = Globals.color_palettes[Globals.current_palette][7]
	background.color = Globals.color_palettes[Globals.current_palette][7]

func change_room(previous_room_coords : Vector2i, exit_index : int):
	player.dead = true
	player.deactivate_collision()
	var tw : Tween = create_tween()
	tw.tween_property(veil, "modulate:a", 1.0, 0.25)
	await tw.finished
	if leveled_up:
		leveled_up = false
		EventBus.upgrade_time.emit()
	if current_room:
		current_room.queue_free()
		
	var new_room : Room
	
	await get_tree().process_frame
	
	if room_grid.size() > 0:
		match exit_index:
			0:
				player.position.y = get_viewport_rect().size.y * 0.5 + Globals.PLAYFIELD_HEIGHT * 0.5 - Globals.CELL_SIZE * 2
			1:
				player.position.x = get_viewport_rect().size.x * 0.5 - Globals.PLAYFIELD_WIDTH * 0.5 + Globals.CELL_SIZE * 2
			2:
				player.position.y = get_viewport_rect().size.y * 0.5 - Globals.PLAYFIELD_HEIGHT * 0.5 + Globals.CELL_SIZE * 2
			3:
				player.position.x = get_viewport_rect().size.x * 0.5 + Globals.PLAYFIELD_WIDTH * 0.5 - Globals.CELL_SIZE * 2
	

	if room_grid.size() == 0:
		rooms_spawned += 1
		new_room = create_new_room(Vector2i.ZERO)
	elif !room_grid.has(previous_room_coords + directions[exit_index]):
		rooms_spawned += 1
		var coords : Vector2i = previous_room_coords + directions[exit_index]
		new_room = create_new_room(coords)
	else:
		new_room = room_scene.instantiate()
		new_room.room_data = room_grid[previous_room_coords + directions[exit_index]]

	new_room.room_exited.connect(_on_room_exited)
	new_room.enemy_destroyed.connect(_on_enemy_destroyed)
	

	new_room.position = get_viewport_rect().size * 0.5
	new_room.total_rooms = rooms_spawned

	room_grid[new_room.room_data.coords] = new_room.room_data
	current_room = new_room
	
	call_deferred("add_child", new_room)
	
	tw = create_tween()
	tw.tween_interval(0.25)
	tw.tween_property(veil, "modulate:a", 0.0, 0.25)
	
	await tw.finished
	player.dead = false
	player.activate_collision()
	room_changed.emit(current_room.room_data.coords)

func create_room_data(coords : Vector2i, layout : int, first_visited : int, last_visited : int) -> RoomData:
	var data : RoomData = RoomData.new()
	
	data.coords = coords
	data.layout_type = layout
	data.first_visited = first_visited
	data.last_visited = last_visited
	
	return data


func count_empty_neighbours(coords : Vector2i):
	var empty_neighbour_count : int = 0
	for dir in 4:
		if !room_grid.has(coords + directions[dir]):
			empty_neighbour_count += 1
		
	return empty_neighbour_count

func create_new_room(coords : Vector2i) -> Room:
	var new_room : Room = room_scene.instantiate()
	var exit_layout : int
	var current_time = Time.get_ticks_msec()
	
	if coords == Vector2i.ZERO:
		exit_layout = [3, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15].pick_random()
		
		
	else:
		exit_layout = choose_exit_layout(coords)
		
	var room_data : RoomData = create_room_data(coords, exit_layout, current_time, current_time)
	new_room.room_data = room_data
	new_room.player = player
	

	
	return new_room
	

	
func choose_exit_layout(coords : Vector2i) -> int:
	var layout : int
	
	var possible_layouts : Array[int] = []
	var empty_neighbours_count = count_empty_neighbours(coords)

	var layout_candidates : Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
	if empty_neighbours_count == 3:
		layout_candidates = [3, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15]

	elif empty_neighbours_count == 2:
		layout_candidates = [7, 11, 13, 14, 15]


	for i in layout_candidates:
		var accepted : bool = false
		
		for j in range(0, 4):
			var neighbour_coords : Vector2i = coords + directions[j]
			if !room_grid.has(neighbour_coords):
				continue	
			else:
				if i & exit_mappings[directions[j]] != 0 and room_grid[neighbour_coords].layout_type & exit_mappings[-directions[j]] != 0:
					accepted = true						
		if accepted:
			possible_layouts.append(i)
				
	layout = possible_layouts.pick_random()	
	return layout
	
func _on_room_exited(room_coords: Vector2i, exit_index : int):
	room_grid[room_coords].last_visited = Time.get_ticks_msec()
	change_room(room_coords, exit_index)

func _on_enemy_destroyed(exp_value : int):
	player.gain_exp(exp_value)
	exp_value_changed.emit(player.experience)


func _on_player_health_changed(value : int):
	player_health_changed.emit(value)

func _on_player_died():
	for enemy in enemies.get_children():
		enemy.target = null

func _on_explosion(pos : Vector2):
	var explosion : GPUParticles2D = explosion_scene.instantiate()
	explosion.position = current_room.to_local(pos)
	explosion.emitting = true
	
	current_room.call_deferred("add_child", explosion)


func _on_bullet_fired(bullet: Node2D, pos: Vector2) -> void:
	bullet.position = current_room.to_local(pos)
	current_room.bullets.call_deferred("add_child", bullet)
	
func _on_upgrade_selected(data: UpgradeData):
	if data.current_type == UpgradeData.Upgrades.SPEED:
		player.speed += data.amount
	if data.current_type == UpgradeData.Upgrades.FIRERATE:
		player.fire_rate -= data.amount
	if data.current_type == UpgradeData.Upgrades.HITPOINTS:
		player.max_hp += data.amount
		player.hp += data.amount
		EventBus.player_max_health_changed.emit(player.max_hp)
		player.health_changed.emit(player.hp)
	if data.current_type == UpgradeData.Upgrades.BULLET_SPEED:
		player.bullet_speed += data.amount
	if data.current_type == UpgradeData.Upgrades.BULLET_DAMAGE:
		player.power += data.amount

func _on_player_leveled_up():
	leveled_up = true
