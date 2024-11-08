extends Node2D


@onready var player: Player = $Player
@onready var veil: ColorRect = $"../Veil/Veil"
@onready var background: ColorRect = $"../Background/Background"

const explosion_scene = preload("res://scenes/explosion.tscn")
const room_scene = preload("res://scenes/room.tscn")


var enemy_count : int = 0
var current_room : Room

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

var room_pos : Vector2

signal player_health_changed(value : int)
signal exp_value_changed(value : int)

		
## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	room_pos = (get_viewport_rect().size - Vector2(Globals.PLAYFIELD_WIDTH, Globals.PLAYFIELD_HEIGHT)) * 0.5 + Vector2.DOWN * 20
	change_room(Vector2i.ZERO, 0)
	apply_color_palette()
	EventBus.upgrade_card_pressed.connect(_on_upgrade_selected)
	player.position = get_viewport_rect().size * 0.5
	
func apply_color_palette():
	veil.color = Globals.color_palettes[Globals.current_palette][7]
	background.color = Globals.color_palettes[Globals.current_palette][7]

func change_room(previous_room_coords : Vector2i, exit_index : int):
	player.dead = true
	player.deactivate_collision()
	var tw : Tween = create_tween()
	tw.tween_property(veil, "modulate:a", 1.0, 0.25)
	await tw.finished

	if current_room:
		current_room.queue_free()
		
	var new_room : Room
	
	await get_tree().process_frame
	
	if Globals.room_grid.size() > 0:
		match exit_index:
			0:
				player.position.y = get_viewport_rect().size.y * 0.5 + Globals.PLAYFIELD_HEIGHT * 0.5 - Globals.CELL_SIZE + 20
			1:
				player.position.x = get_viewport_rect().size.x * 0.5 - Globals.PLAYFIELD_WIDTH * 0.5 + Globals.CELL_SIZE
			2:
				player.position.y = get_viewport_rect().size.y * 0.5 - Globals.PLAYFIELD_HEIGHT * 0.5 + Globals.CELL_SIZE + 20
			3:
				player.position.x = get_viewport_rect().size.x * 0.5 + Globals.PLAYFIELD_WIDTH * 0.5 - Globals.CELL_SIZE
	
		player.velocity = Vector2.ZERO
		
	if Globals.room_grid.size() == 0:
		new_room = create_new_room(Vector2i.ZERO)
		Globals.room_grid[new_room.room_data.coords] = new_room.room_data
	elif !Globals.room_grid.has(previous_room_coords + directions[exit_index]):
		var coords : Vector2i = previous_room_coords + directions[exit_index]
		new_room = create_new_room(coords)
		Globals.room_grid[new_room.room_data.coords] = new_room.room_data
	else:
		new_room = room_scene.instantiate()
		new_room.room_data = Globals.room_grid[previous_room_coords + directions[exit_index]]

	new_room.room_exited.connect(_on_room_exited)
	new_room.enemy_destroyed.connect(_on_enemy_destroyed)
	

	new_room.position = room_pos

	new_room.player = player

	
	current_room = new_room
	
	await get_tree().process_frame
	call_deferred("add_child", new_room)
	
	tw = create_tween()
	tw.tween_interval(0.25)
	tw.tween_property(veil, "modulate:a", 0.0, 0.25)
	
	await tw.finished
	player.dead = false
	player.activate_collision()
	EventBus.room_changed.emit(current_room.room_data)

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
		if !Globals.room_grid.has(coords + directions[dir]):
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
	
	return new_room
	

	
func choose_exit_layout(coords : Vector2i) -> int:
	var layout : int
	
	var possible_layouts : Array[int] = []
	var empty_neighbours_count = count_empty_neighbours(coords)

	var layout_candidates : Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
	
	if coords.x >= -Settings.zone_size * 10 and \
	coords.x <= Settings.zone_size * 10 and \
	coords.y >= - Settings.zone_size * 10 and \
	coords.y <= Settings.zone_size * 10:
	
		if empty_neighbours_count == 3 or empty_neighbours_count == 1:
			layout_candidates = [3, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15]

		elif empty_neighbours_count == 2:
			layout_candidates = [7, 11, 13, 14, 15]
	else:
		if coords.x < -Settings.zone_size * 10:
			layout_candidates = layout_candidates.filter(func (x) : return x & 8 == 0)
		elif coords.x > Settings.zone_size * 10:
			layout_candidates = layout_candidates.filter(func (x) : return x & 2 == 0)		
		if coords.y < -Settings.zone_size * 10:
			layout_candidates = layout_candidates.filter(func (x) : return x & 1 == 0)
		elif coords.y > Settings.zone_size * 10:
			layout_candidates = layout_candidates.filter(func (x) : return x & 4 == 0)
	
	
	for i in layout_candidates.size():
		var accepted : bool = false
		
		for dir in exit_mappings.keys():
			var neighbour_coords : Vector2i = coords + dir
			if !Globals.room_grid.has(neighbour_coords):
				continue
			if (layout_candidates[i] & exit_mappings[dir]) /  exit_mappings[dir] == (Globals.room_grid[neighbour_coords].layout_type & exit_mappings[-dir]) / exit_mappings[-dir]: 
				accepted = true
			else:
				accepted = false
				break
			
		if accepted:
			possible_layouts.append(layout_candidates[i])
		
	layout = possible_layouts.pick_random()	
	return layout
	
func _on_room_exited(room_coords: Vector2i, exit_index : int):
	Globals.room_grid[room_coords].last_visited = Time.get_ticks_msec()
	change_room(room_coords, exit_index)

func _on_enemy_destroyed(exp_value : int):
	player.gain_exp(exp_value)
	#exp_value_changed.emit(player.experience)


func _on_player_health_changed(value : int):
	player_health_changed.emit(value)


func _on_explosion(pos : Vector2):
	var explosion : GPUParticles2D = explosion_scene.instantiate()
	explosion.initialize(Vector2.ZERO, [player.primary_color, player.secondary_color, player.tertiary_color])
	explosion.position = current_room.to_local(pos)
	explosion.emitting = true
	
	current_room.call_deferred("add_child", explosion)


func _on_bullet_fired(bullet: Node2D, pos: Vector2) -> void:
	bullet.position = current_room.to_local(pos)
	current_room.bullets.call_deferred("add_child", bullet)
	
func _on_upgrade_selected(data: UpgradeData):
	if data.current_type == UpgradeData.Upgrades.SPEED:
		player.speed += data.amount
		player.rotation_threshold = ceil(11 / (player.speed / 160))
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
