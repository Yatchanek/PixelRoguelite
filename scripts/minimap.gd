extends HBoxContainer
class_name MiniMap

@onready var grid: GridContainer = $VBoxContainer2/MinimapPanel/Grid
@onready var minimap_panel: PanelContainer = $VBoxContainer2/MinimapPanel
@onready var v_box_container_2: VBoxContainer = $VBoxContainer2

@export var map_scale : Vector2 = Vector2.ONE

var center_coords : Vector2i = Vector2i.ZERO
var player_coords : Vector2i = Vector2i.ZERO

var cell_size : Vector2 = Vector2(32, 32)

var pos_offset : Vector2

const room_scene = preload("res://scenes/map_room.tscn")

var gate_keys_discovered : Array[Vector2i] = []

var num_cols : int
var num_rows : int
var start_x : int
var start_y : int

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left"):
		move_right()
	elif event.is_action_pressed("right"):
		move_left()
	elif event.is_action_pressed("forward"):
		move_down()
	elif event.is_action_pressed("back"):
		move_up()
		
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_on_scale_down()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_on_scale_up()

func _draw() -> void:
	var player_map_coords = world_to_map(player_coords)
	if coords_on_screen(player_map_coords):
		draw_rect(Rect2(v_box_container_2.position + grid.position + Vector2(
			cell_size.x * 0.5 + player_map_coords.x * cell_size.x, 
			cell_size.y * 0.5 + player_map_coords.y * cell_size.y) - 4 * map_scale, 8 * map_scale), Globals.color_palettes[Globals.current_palette][3])
		
	for coords : Vector2i in gate_keys_discovered:
		if !Globals.gate_key_coords.has(coords):
			continue
		var map_coords = world_to_map(coords)
		if coords_on_screen(map_coords):
			draw_circle(v_box_container_2.position + grid.position + Vector2(
			cell_size.x * 0.5 + map_coords.x * cell_size.x, 
			cell_size.y * 0.5 + map_coords.y * cell_size.y), 
			4 * map_scale.x, Globals.color_palettes[Globals.current_palette][2])
			
func _ready() -> void:
	grid.size = Vector2(160, 160)
	cell_size = Vector2(ceil(32 * map_scale.x), ceil(32 * map_scale.y))
	
	num_cols = 160 / cell_size.x
	num_rows = 160 / cell_size.y

	grid.columns = num_cols

	var stylebox : StyleBoxFlat = StyleBoxFlat.new()
	stylebox.border_color = Globals.color_palettes[Globals.current_palette][4]
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][7]
	stylebox.set_border_width_all(2)
	
	minimap_panel.add_theme_stylebox_override("panel", stylebox)
	
	EventBus.room_changed.connect(_on_room_changed)
	set_process_unhandled_input(false)
	fill_grid()
	await get_tree().process_frame
	pos_offset = v_box_container_2.position + grid.position

func fill_grid():
	for i in num_rows * num_cols:
		var room : MapRoom = room_scene.instantiate()
		room.self_modulate = Globals.color_palettes[Globals.current_palette][5]
		room.cell_size = cell_size
		grid.add_child(room)

func apply_color_palette():
	var stylebox : StyleBoxFlat = StyleBoxFlat.new()
	stylebox.border_color = Globals.color_palettes[Globals.current_palette][4]
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][7]
	stylebox.set_border_width_all(2)
	
	minimap_panel.add_theme_stylebox_override("panel", stylebox)
	
	for button in get_tree().get_nodes_in_group("Buttons"):
		button.apply_color_palette()
		
	for room in grid.get_children():
		room.self_modulate = Globals.color_palettes[Globals.current_palette][5]
	
	if visible:
		queue_redraw()

func reset():
	num_rows = 5
	num_cols = 5
	
	update_map_size()
	

func _on_scale_up():
	num_rows = clamp(num_rows - 2, 3, 9)
	num_cols = clamp(num_cols - 2, 3, 9)
	
	update_map_size()
	
	
func _on_scale_down():
	num_rows = clamp(num_rows + 2, 3, 9)
	num_cols = clamp(num_cols + 2, 3, 9)
	
	update_map_size()

func update_map_size():
	map_scale = Vector2(float(5.0 / num_cols), float(5.0 / num_rows))
	#grid.map_scale = map_scale
	cell_size = Vector2(ceil(32 * map_scale.x), ceil(32 * map_scale.y))
	
	for child in grid.get_children():
		child.queue_free()
	await get_tree().process_frame
	grid.columns = num_cols
	
	fill_grid()
	
	if visible:		
		redraw_map()

func move_left():
	center_coords += Vector2i.LEFT
	redraw_map()
	
func move_right():
	center_coords += Vector2i.RIGHT
	redraw_map()
	
func move_up():
	center_coords += Vector2i.UP
	redraw_map()
	
func move_down():
	center_coords += Vector2i.DOWN
	redraw_map()
			
func redraw_map():
	start_x = center_coords.x - floori(num_cols / 2)
	start_y = center_coords.y - floori(num_rows / 2)	
	for y in num_rows:
		for x in num_cols:
			var coords : Vector2i = Vector2i(start_x + x, start_y + y)
			var room : MapRoom = grid.get_child(y * num_cols + x)
			if Globals.room_grid.has(coords):
				room.room_idx = Globals.room_grid[coords].layout_type
			else:
				room.room_idx = 0
				
			room.update_texture()
	
	queue_redraw()			

func world_to_map(coords) -> Vector2i:
	var map_coords : Vector2i
	map_coords = coords - Vector2i(start_x, start_y)
	return map_coords
	

func coords_on_screen(coords : Vector2i) -> bool:
	if coords.x < 0 or coords.x > num_cols - 1 \
	or coords.y < 0 or coords.y > num_rows - 1:
		return false
	return true

func _on_room_changed(room_data : RoomData):
	player_coords = room_data.coords
	if visible:
		redraw_map()
	else:
		center_coords = room_data.coords

func toggle():
	center_coords = player_coords
	if !visible:
		check_for_gate_keys()
		redraw_map()
		get_tree().paused = true
		set_process_unhandled_input(true)
	else:
		
		get_tree().paused = false
		set_process_unhandled_input(false)
	reset()
	visible = !visible

func check_for_gate_keys():
	for gate_key_coords : Vector2i in Globals.gate_key_coords.keys():
		if Utils.is_within_range(gate_key_coords, player_coords, 3):
			if !gate_keys_discovered.has(gate_key_coords):
				gate_keys_discovered.append(gate_key_coords)
