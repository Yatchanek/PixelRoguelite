extends HBoxContainer
class_name MiniMap

@onready var grid: GridContainer = $VBoxContainer2/MinimapPanel/Grid
@onready var minimap_panel: PanelContainer = $VBoxContainer2/MinimapPanel

@export var map_scale : Vector2 = Vector2.ONE

var center_coords : Vector2i = Vector2i.ZERO
var player_coords : Vector2i = Vector2i.ZERO

var cell_size : Vector2 = Vector2(32, 32)

var player_map_coords : Vector2i = Vector2i(-INF, -INF)

const room_scene = preload("res://scenes/map_room.tscn")

var num_cols : int
var num_rows : int

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
			
func _ready() -> void:
	cell_size = Vector2(32 * map_scale.x, 32 * map_scale.y)
	grid.cell_size = cell_size
	grid.map_scale = map_scale
	
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

func fill_grid():
	for i in num_rows * num_cols:
		var room : MapRoom = room_scene.instantiate()
		room.self_modulate = Globals.color_palettes[Globals.current_palette][5]
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
	grid.map_scale = map_scale
	grid.cell_size = Vector2(32 * map_scale.x, 32 * map_scale.y)
	
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
	var start_x = center_coords.x - floori(num_cols / 2)
	var start_y = center_coords.y - floori(num_rows / 2)
		
	for y in num_rows:
		for x in num_cols:
			var coords : Vector2i = Vector2i(start_x + x, start_y + y)
			var room : MapRoom = grid.get_child(y * num_cols + x)
			if Globals.room_grid.has(coords):
				room.room_idx = Globals.room_grid[coords].layout_type
			else:
				room.room_idx = 0
				
			room.map_scale = map_scale
			room.update()

			if coords == player_coords:
				grid.player_map_coords = Vector2i(x, y)
				
	if player_coords.x < start_x or player_coords.x > start_x + num_cols - 1 \
	or player_coords.y < start_y or player_coords.y > start_y + num_cols - 1:
		grid.player_map_coords = Vector2i(-1000000, -1000000)
				
	grid.queue_redraw()

func _on_room_changed(room_coords : Vector2i):
	player_coords = room_coords
	if visible:
		redraw_map()
	else:
		center_coords = room_coords

func toggle():
	center_coords = player_coords
	if !visible:
		reset()
		redraw_map()
		get_tree().paused = true
		set_process_unhandled_input(true)
	else:
		get_tree().paused = false
		set_process_unhandled_input(false)
	visible = !visible
