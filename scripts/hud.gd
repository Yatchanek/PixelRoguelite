extends CanvasLayer
class_name HUD

@onready var top_bar: PanelContainer = %TopBar
@onready var danger_label: Label = %DangerLabel
@onready var danger_amount_label: Label = %DangerAmountLabel
@onready var hp_bar: TextureProgressBar = %HPBar
@onready var coords_label: Label = %CoordsLabel
@onready var upgrade_card_container: HBoxContainer = $Control/UpgradeCardContainer
@onready var minimap: MiniMapContainer = $Control/Minimap
@onready var keys_container: HBoxContainer = %KeysContainer
@onready var shield_bar: TextureProgressBar = $Control/TopBar/MarginContainer/VBoxContainer/UpperBar/HBoxContainer2/HBoxContainer2/ShieldBar
@onready var energy_bar: TextureProgressBar = %EnergyBar
@onready var message_label: Label = $Control/MessageLabel
@onready var cursor: Sprite2D = $Cursor
@onready var ui_veil: ColorRect = $Control/UIVeil
@onready var game_over_panel: PanelContainer = $Control/GameOverPanel
@onready var restart_label: Label = %RestartLabel
@onready var back_to_menu_label: Label = %BackToMenuLabel
@onready var game_over_label: Label = $Control/GameOverPanel/VBoxContainer/GameOverLabel
@onready var restart_button: Button = %RestartButton
@onready var back_to_menu_button: Button = %BackToMenuButton
@onready var hand_cursor: Sprite2D = $HandCursor
@onready var cursor_inner: Sprite2D = $HandCursor/CursorInner

var game_over : bool = false

func _unhandled_input(event: InputEvent) -> void:
	if Globals.game_completed:
		return
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_M:
			toggle_minimap()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	apply_color_palette()
	EventBus.gate_key_collected.connect(show_gate_key)
	EventBus.gate_approached.connect(show_message.bind("retrieve all nine keys\nto open the gate!", -1.0))
	EventBus.gate_left.connect(hide_message)
	EventBus.map_found.connect(show_message.bind("You've found the map of the maze!", 2.0))
	EventBus.game_completed.connect(_on_game_completed)
	EventBus.room_changed.connect(update_room)
	EventBus.upgrade_time.connect(_on_player_leveled_up)

	for button : Button in get_tree().get_nodes_in_group("GameOverButtons"):
		button.mouse_entered.connect(_on_button_hovered.bind(button))
		button.mouse_exited.connect(_on_button_unhovered.bind(button))
		
func _process(delta: float) -> void:
	if !game_over:
		cursor.position = cursor.get_global_mouse_position()
	else:
		hand_cursor.position = hand_cursor.get_global_mouse_position()
	
func update_health(value : int):
	if value < hp_bar.value:
		var tw : Tween = create_tween()
		tw.tween_property(hp_bar, "tint_progress", Globals.color_palettes[Globals.current_palette][0], 0.15)
		tw.tween_property(hp_bar, "tint_progress", Globals.color_palettes[Globals.current_palette][3], 0.1)
		
	hp_bar.value = value

func update_max_health(value : int):
	hp_bar.max_value = value

func update_danger(amount : int):
	danger_amount_label.text = str(amount)

func update_shield(value : int):
	if value < shield_bar.value:
		var tw : Tween = create_tween()
		tw.tween_property(shield_bar, "tint_progress", Globals.color_palettes[Globals.current_palette][0], 0.15)
		tw.tween_property(shield_bar, "tint_progress", Globals.color_palettes[Globals.current_palette][3], 0.1)
	
	shield_bar.value = value
	
func update_max_shield(value : int):
	shield_bar.max_value = value

func update_energy(value : float):
	energy_bar.value = value
	
func update_max_energy(value : int):
	energy_bar.max_value = value

func update_room(room_data : RoomData):
	coords_label.text = str(room_data.coords)
	danger_amount_label.text = str(floor(Utils.get_depth(room_data.coords) / (6 - Settings.difficulty)))

func apply_color_palette():
	var stylebox : StyleBoxFlat = StyleBoxFlat.new()
	stylebox.border_color = Globals.color_palettes[Globals.current_palette][5]
	stylebox.set_border_width_all(1)
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][6]
	
	top_bar.add_theme_stylebox_override("panel", stylebox)
	
	stylebox = stylebox.duplicate()
	stylebox.set_border_width_all(2)
	game_over_panel.add_theme_stylebox_override("panel", stylebox)
	
	coords_label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3] 
	message_label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][4]
	message_label.label_settings.outline_color = Globals.color_palettes[Globals.current_palette][2] 
	restart_label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3] 
	restart_label.label_settings.outline_color = Globals.color_palettes[Globals.current_palette][5] 
	back_to_menu_label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3] 
	back_to_menu_label.label_settings.outline_color = Globals.color_palettes[Globals.current_palette][5] 
	game_over_label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3] 
	game_over_label.label_settings.outline_color = Globals.color_palettes[Globals.current_palette][5] 
		
	
	hp_bar.tint_progress = Globals.color_palettes[Globals.current_palette][3]
	hp_bar.tint_over = Globals.color_palettes[Globals.current_palette][4]
	shield_bar.tint_progress = Globals.color_palettes[Globals.current_palette][3]
	shield_bar.tint_over = Globals.color_palettes[Globals.current_palette][4]
	energy_bar.tint_progress = Globals.color_palettes[Globals.current_palette][3]
	energy_bar.tint_over = Globals.color_palettes[Globals.current_palette][4]
	
	for key in keys_container.get_children():
		key.self_modulate = Globals.color_palettes[Globals.current_palette][7]
	
	for i in keys_container.get_child_count():
		if Globals.keys_collected.has(i):
			keys_container.get_child(i).self_modulate = Globals.color_palettes[Globals.current_palette][0]
		else:
			keys_container.get_child(i).self_modulate = Globals.color_palettes[Globals.current_palette][7]

	cursor.self_modulate = Globals.color_palettes[Globals.current_palette][1]
	hand_cursor.self_modulate = Globals.color_palettes[Globals.current_palette][6]
	cursor_inner.self_modulate = Globals.color_palettes[Globals.current_palette][3]

	minimap.apply_color_palette()

func show_gate_key(idx : int, _coords : Vector2i):
	keys_container.get_child(idx).self_modulate = Globals.color_palettes[Globals.current_palette][0]
	
func show_upgrades():
	ui_veil.modulate.a = 0.75
	upgrade_card_container.add_cards()

func show_message(msg : String, duration : float):
	message_label.text = msg
	message_label.show()
	if duration > 0:
		await get_tree().create_timer(duration)
		hide_message()
	
func hide_message():
	message_label.hide()

func _on_player_leveled_up():
	get_tree().paused = true
	await get_tree().create_timer(0.25).timeout
	show_upgrades()

func _on_game_completed():
	game_over_label.text = "You won!"
	await get_tree().create_timer(2.0).timeout
	ui_veil.modulate.a = 0.75
	game_over_panel.show()
	cursor.hide()
	hand_cursor.show()
	game_over = true
	hand_cursor.position = hand_cursor.get_global_mouse_position()	


func toggle_minimap():
	if minimap.visible:
		ui_veil.modulate.a = 0.0
	else:
		ui_veil.modulate.a = 0.75
	minimap.toggle()


func _on_cards_hidden() -> void:
	ui_veil.modulate.a = 0.0

func _on_button_hovered(button : Button):
	var label : Label = button.get_child(0) as Label
	label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][6]
	label.label_settings.outline_color = Globals.color_palettes[Globals.current_palette][2]

func _on_button_unhovered(button : Button):
	var label : Label = button.get_child(0) as Label
	label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3]
	label.label_settings.outline_color = Globals.color_palettes[Globals.current_palette][5]


func _on_player_died() -> void:
	await get_tree().create_timer(2.0).timeout
	ui_veil.modulate.a = 0.75
	game_over_panel.show()
	cursor.hide()
	hand_cursor.show()
	game_over = true
	hand_cursor.position = hand_cursor.get_global_mouse_position()


func _on_restart_button_pressed() -> void:
	restart_button.disabled = true
	back_to_menu_button.disabled = true
	get_tree().reload_current_scene()


func _on_back_to_menu_button_pressed() -> void:
	restart_button.disabled = true
	back_to_menu_button.disabled = true
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
