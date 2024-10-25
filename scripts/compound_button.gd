extends PanelContainer
class_name CompoundButton

@onready var button_image: TextureRect = $ButtonImage

signal pressed


func _ready() -> void:
	apply_color_palette()


func apply_color_palette():
	button_image.self_modulate = Globals.color_palettes[Globals.current_palette][4]
	
	var stylebox : StyleBoxFlat = StyleBoxFlat.new()
	stylebox.set_border_width_all(1)
	stylebox.border_color = Globals.color_palettes[Globals.current_palette][5]
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][6]
	
	add_theme_stylebox_override("panel", stylebox)
	
	


func _on_button_pressed() -> void:
	pressed.emit()



func _on_button_image_mouse_entered() -> void:
	button_image.self_modulate = Globals.color_palettes[Globals.current_palette][3]
	
	var stylebox : StyleBoxFlat = StyleBoxFlat.new()
	stylebox.set_border_width_all(1)
	stylebox.border_color = Globals.color_palettes[Globals.current_palette][4]
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][6]
	
	add_theme_stylebox_override("panel", stylebox)	


func _on_button_image_mouse_exited() -> void:
	apply_color_palette()
