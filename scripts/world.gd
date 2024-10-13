extends Node2D


@onready var player: CharacterBody2D = $Player
@onready var enemies: Node2D = $Enemies
@onready var veil: ColorRect = $"../CanvasLayer/Veil"

const explosion_scene = preload("res://scenes/explosion.tscn")
const room_scene = preload("res://scenes/room.tscn")


var enemy_count : int = 0
var current_room : Room

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
#
## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	change_room(Vector2i.ZERO, 0)


func change_room(previous_room_coords : Vector2i, exit_index : int):
	player.dead = true
	var tw : Tween = create_tween()
	tw.tween_property(veil, "modulate:a", 1.0, 0.25)
	await tw.finished
	if current_room:
		current_room.queue_free()
		
	var new_room : Room = room_scene.instantiate()
	new_room.position = get_viewport_rect().size * 0.5
	
	new_room.connect("room_exited", _on_room_exited)
	
	if room_grid.size() > 0:
		match exit_index:
			0:
				player.position.y = get_viewport_rect().size.y * 0.5 + Globals.PLAYFIELD_HEIGHT * 0.5 - 10
			1:
				player.position.x = get_viewport_rect().size.x * 0.5 - Globals.PLAYFIELD_WIDTH * 0.5 + 10
			2:
				player.position.y = get_viewport_rect().size.y * 0.5 - Globals.PLAYFIELD_HEIGHT * 0.5 + 10
			3:
				player.position.x = get_viewport_rect().size.x * 0.5 + Globals.PLAYFIELD_WIDTH * 0.5 - 10
	
	var current_time = Time.get_ticks_msec()
			
	if room_grid.size() == 0:
		var coords : Vector2i = Vector2i.ZERO
		var exit_layout : int = [3, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15].pick_random()
		var room_data : RoomData = create_room_data(coords, exit_layout, current_time, current_time)
		new_room.is_first_room = true
		new_room.room_data = room_data
		room_grid[room_data.coords] = room_data
	elif !room_grid.has(previous_room_coords + directions[exit_index]):
		var coords : Vector2i = previous_room_coords + directions[exit_index]
		var exit_layout : int = create_new_room(new_room.coords)
		var room_data : RoomData = create_room_data(coords, exit_layout, current_time, current_time)
		new_room.room_data = room_data
		room_grid[room_data.coords] = room_data
	else:
		new_room.room_data = room_grid[previous_room_coords + directions[exit_index]]

	new_room.player = player
	
	call_deferred("add_child", new_room)
	current_room = new_room
	
	tw = create_tween()
	tw.tween_interval(0.25)
	tw.tween_property(veil, "modulate:a", 0.0, 0.25)
	
	await tw.finished
	player.dead = false

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

func create_new_room(coords : Vector2i):
	var possible_layouts : Array[int] = []
	var empty_neighbours_count = count_empty_neighbours(coords)
	for i in range(1, 16):
		var accepted : bool = true
		for j in range(0, 4):
			var neighbour_coords : Vector2i = coords + directions[j]
			if !room_grid.has(neighbour_coords):
				continue	
			else:
				if i & exit_mappings[directions[j]] != 0 and room_grid[neighbour_coords].layout_type & exit_mappings[-directions[j]] != 0:
					if empty_neighbours_count == 3:
						if [1, 2, 4, 8].has(i):
							accepted = false
					elif empty_neighbours_count == 2:
						if [1, 2, 3, 4, 5, 6, 8, 9, 10, 12].has(i):
							accepted = false
				else:
					accepted = false
					
				
		if accepted:
			possible_layouts.append(i)
	
	return possible_layouts.pick_random()

func _on_room_exited(room_coords: Vector2i, exit_index : int):
	room_grid[room_coords].last_visited = Time.get_ticks_msec()
	change_room(room_coords, exit_index)

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
