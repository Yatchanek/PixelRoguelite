extends ScrollContainer

var items : Array[BorderedButton] = []
@onready var palette_buttons_container: VBoxContainer = %PaletteButtonsContainer

var max_scroll : int

# Called when the node enters the scene tree for the first time.

func configure():
	for item : BorderedButton in palette_buttons_container.get_children():
		items.append(item)
		
	max_scroll = palette_buttons_container.size.y - size.y
	
	
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
				if event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_UP:
					if scroll_vertical >= max_scroll:
						palette_buttons_container.move_child(palette_buttons_container.get_child(0), palette_buttons_container.get_child_count() - 1)
					elif scroll_vertical <= 0:
						palette_buttons_container.move_child(palette_buttons_container.get_child(palette_buttons_container.get_child_count() - 1), 0)
