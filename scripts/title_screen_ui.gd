extends Node2D

var bordered_button_scene = preload("res://scenes/bordered_button.tscn")

@onready var background: ColorRect = $Background/Background
@onready var options: TabContainer = $UI/Control/MarginContainer/Options
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_palette: TextureRect = %ColorPalette
@onready var cursor: Sprite2D = $UI/Cursor
@onready var cursor_inner: Sprite2D = $UI/Cursor/CursorInner
@onready var color_palettes: PanelContainer = %ColorPalettes
@onready var palette_buttons_container: VBoxContainer = %PaletteButtonsContainer
@onready var wrapping_scroll_container: ScrollContainer = %WrappingScrollContainer
@onready var close_options: TextureButton = %CloseOptions
@onready var crt_options: VBoxContainer = %CRTOptions

@onready var crt_curve_slider: HSlider = %crt_curve
@onready var crt_scanline_slider: HSlider = %crt_scan_line_color
@onready var crt_aperture_slider: HSlider = %crt_aperture_grille_rate
@onready var crt_blur_slider: HSlider = %crt_blur
@onready var crt_noise_shader: HSlider = %crt_white_noise_rate
@onready var crt_brightnes_slider: HSlider = %crt_brightness

@onready var maze_size_slider: HSlider = %maze_size
@onready var difficulty_slider: HSlider = %difficulty
@onready var master_volume_slider: HSlider = %master_volume
@onready var effects_colume_slider: HSlider = %effects_volume
@onready var music_volume_slider: HSlider = %music_volume

var candidate_color_palette : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_palette_buttons()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	#Input.set_custom_mouse_cursor(load("res://graphics/arrow_cursor_small.png"), Input.CURSOR_ARROW, Vector2.ZERO)
	#Input.set_custom_mouse_cursor(load("res://graphics/pointing_hand_small.png"), Input.CURSOR_POINTING_HAND, Vector2(24, 4))
	for button : Button in get_tree().get_nodes_in_group("MainButtons"):
		button.mouse_entered.connect(_on_button_hovered.bind(button))
		button.mouse_exited.connect(_on_button_unhovered.bind(button))
	
	for ui_element : Control in get_tree().get_nodes_in_group("InteractableUI"):
		ui_element.mouse_entered.connect(_on_interactable_ui_hovered)
		ui_element.mouse_exited.connect(_on_interactable_ui_unhovered)
	
	for label : Label in get_tree().get_nodes_in_group("MenuLabels"):
		label.mouse_entered.connect(_on_menu_label_hovered.bind(label))
		label.mouse_exited.connect(_on_menu_label_unhovered.bind(label))
	
	for slider : HSlider in get_tree().get_nodes_in_group("CRTSliders"):
		slider.value_changed.connect(_on_crt_slider_value_changed.bind(slider.name))
	
	for slider : HSlider in get_tree().get_nodes_in_group("SoundSliders"):
		slider.value_changed.connect(_on_sound_slider_value_changed.bind(slider.name))
	
	crt_options.visible = CrtOverlay.visible
	

	AudioServer.set_bus_volume_db(0, Settings.master_volume)
	AudioServer.set_bus_volume_db(1, Settings.effects_volume)
	AudioServer.set_bus_volume_db(2, Settings.music_volume)
	
	set_sliders()
	apply_color_palette()
	set_arrow_cursor()

func set_sliders():
	var crt_material : ShaderMaterial = CrtOverlay.get_node("CRTOverlay").material
	crt_aperture_slider.value = crt_material.get_shader_parameter("crt_aperture_grille_rate")
	crt_curve_slider.value = crt_material.get_shader_parameter("crt_curve")
	crt_scanline_slider.value = crt_material.get_shader_parameter("crt_scan_line_color")
	crt_blur_slider.value = crt_material.get_shader_parameter("crt_blur")
	crt_noise_shader.value = crt_material.get_shader_parameter("crt_white_noise_rate")
	crt_brightnes_slider.value = crt_material.get_shader_parameter("crt_brightness")
	
	for slider : HSlider in get_tree().get_nodes_in_group("SoundSliders"):
		slider.value = db_to_linear(Settings.get(slider.name))
	
	maze_size_slider.value = Settings.zone_size
	difficulty_slider.value = Settings.difficulty

func apply_color_palette():
	cursor.self_modulate = Globals.color_palettes[Globals.current_palette][6]
	cursor_inner.self_modulate = Globals.color_palettes[Globals.current_palette][3]
	color_palette.texture = Globals.palette_images[Globals.current_palette]
	background.color = Globals.color_palettes[Globals.current_palette][7]
	for label : Label in get_tree().get_nodes_in_group("MainButtonLabels"):
		label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3]
		label.label_settings.outline_color = Globals.color_palettes[Globals.current_palette][5]
	
	for label : Label in get_tree().get_nodes_in_group("MenuLabels"):
		label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3]

	
	for checkbox : CheckBox in get_tree().get_nodes_in_group("MenuCheckBoxes"):
		checkbox.self_modulate = Globals.color_palettes[Globals.current_palette][3]
	
	for slider : HSlider in get_tree().get_nodes_in_group("MenuSliders"):
		slider.self_modulate = Globals.color_palettes[Globals.current_palette][3]
		
	close_options.self_modulate = Globals.color_palettes[Globals.current_palette][3]
	
	options.add_theme_color_override("font_selected_color", Globals.color_palettes[Globals.current_palette][0])
	options.add_theme_color_override("font_unselected_color", Globals.color_palettes[Globals.current_palette][2])
	options.add_theme_color_override("font_hovered_color", Globals.color_palettes[Globals.current_palette][1])


	var stylebox : StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][7]
	stylebox.border_color = Globals.color_palettes[Globals.current_palette][6]
	stylebox.set_border_width_all(8)
	options.add_theme_stylebox_override("panel", stylebox)
	color_palettes.add_theme_stylebox_override("panel", stylebox)
	
	stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][4]
	stylebox.expand_margin_right = 8
	stylebox.border_width_right = 16
	stylebox.expand_margin_left = 8
	stylebox.border_width_left = 8
	stylebox.border_color = Color(0, 0, 0, 0)
	options.add_theme_stylebox_override("tab_selected", stylebox)
	
	stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][6]
	stylebox.expand_margin_right = 8
	stylebox.border_width_right = 16
	stylebox.expand_margin_left = 8
	stylebox.border_width_left = 8
	stylebox.border_color = Color(0, 0, 0, 0)	
	options.add_theme_stylebox_override("tab_unselected", stylebox)
	
	stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][5]
	stylebox.expand_margin_right = 8
	stylebox.border_width_right = 16
	stylebox.expand_margin_left = 8
	stylebox.border_width_left = 8
	stylebox.border_color = Color(0, 0, 0, 0)	
	options.add_theme_stylebox_override("tab_hovered", stylebox)
	
	$GameDemo.apply_color_palette()

func create_palette_buttons():
	for i in Globals.palette_images.size():
		
		var button : BorderedButton = bordered_button_scene.instantiate()
		button.pressed.connect(_on_palette_selected)
		
		button.texture = Globals.palette_images[i]
		button.idx = i
		button.add_to_group("InteractableUI")
		palette_buttons_container.add_child(button)
	
	await get_tree().process_frame
	wrapping_scroll_container.configure()

func set_arrow_cursor():
	cursor.texture = load("res://graphics/arrow_cursor_small_outer.png")
	cursor_inner.texture = load("res://graphics/arrow_cursor_small_inner.png")
	cursor.offset = Vector2(12, 19)
	cursor_inner.offset = Vector2(12, 19)
	
func set_hand_cursor():
	cursor.texture = load("res://graphics/pointing_hand_small_outer.png")
	cursor_inner.texture = load("res://graphics/pointing_hand_small_inner.png")
	cursor.offset = Vector2(12, 19)
	cursor_inner.offset = Vector2(12, 19)

func _process(delta: float) -> void:
	cursor.position = get_global_mouse_position()


func _on_palette_selected(button : BorderedButton):
	candidate_color_palette = button.idx
	for _button : BorderedButton in palette_buttons_container.get_children():
		if _button != button and _button.active:
			_button.deactivate()

func _on_interactable_ui_hovered():
	set_hand_cursor()

func _on_interactable_ui_unhovered():
	set_arrow_cursor()

func _on_menu_label_hovered(label : Label):
	label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][2]
	
func _on_menu_label_unhovered(label : Label):
	label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3]

func _on_button_hovered(button : Button):
	if button.disabled:
		return
	var label : Label = button.get_child(0)
	label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][6]
	label.label_settings.outline_color = Globals.color_palettes[Globals.current_palette][2]
	label.label_settings.outline_size = 12
	
func _on_button_unhovered(button : Button):
	if button.disabled:
		return
	var label : Label = button.get_child(0)
	label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3]
	label.label_settings.outline_color = Globals.color_palettes[Globals.current_palette][5]
	label.label_settings.outline_size = 12

func disable_button(button : Button):
	button.disabled = true
	var label : Label = button.get_child(0)
	label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][7]
	label.label_settings.outline_color = Globals.color_palettes[Globals.current_palette][6]
	label.label_settings.outline_size = 4
	
func enable_button(button : Button):
	button.disabled = false
	var label : Label = button.get_child(0)
	label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3]
	label.label_settings.outline_color = Globals.color_palettes[Globals.current_palette][5]
	label.label_settings.outline_size = 12
		
func disable_buttons():
	for button : Button in get_tree().get_nodes_in_group("MainButtons"):
		disable_button(button)
	
func enable_buttons():
	for button : Button in get_tree().get_nodes_in_group("MainButtons"):
		enable_button(button)


func _on_options_pressed() -> void:
	set_arrow_cursor()
	disable_buttons()
	animation_player.play("OpenOptions")


func _on_close_options_pressed() -> void:
	set_arrow_cursor()
	enable_buttons()
	animation_player.play_backwards("OpenOptions")


func _on_crt_shader_check_box_toggled(toggled_on: bool) -> void:
	CrtOverlay.visible = toggled_on
	crt_options.visible = toggled_on


func _on_start_game_pressed() -> void:
	Globals.new_game()
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_apply_palette_pressed() -> void:
	Globals.current_palette = candidate_color_palette
	animation_player.play_backwards("OpenPalettes")
	apply_color_palette()


func _on_cancel_pressed() -> void:
	animation_player.play_backwards("OpenPalettes")


func _on_change_palette_buton_pressed() -> void:
	animation_player.play("OpenPalettes")

func _on_crt_slider_value_changed(value : float, _name : String):
	if crt_options.scale.x < 0.5:
		return
	var crt_material : ShaderMaterial = CrtOverlay.get_node("CRTOverlay").material
	crt_material.set_shader_parameter(_name, value)

func _on_sound_slider_value_changed(value : float, _name : String):
	if options.scale.x < 0.5:
		return
	Settings.set(_name, linear_to_db(value))
	match _name:
		"master_volume":
			AudioServer.set_bus_volume_db(0, Settings.master_volume)
		"effects_volume":
			AudioServer.set_bus_volume_db(1, Settings.effects_volume)
		"music_volume":
			AudioServer.set_bus_volume_db(2, Settings.music_volume)
	
	#prints(AudioServer.get_bus_volume_db(0), AudioServer.get_bus_volume_db(1), AudioServer.get_bus_volume_db(2))

func _on_maze_size_value_changed(value: float) -> void:
	Settings.zone_size = int(value)



func _on_difficulty_value_changed(value: float) -> void:
	Settings.difficulty = int(value)
