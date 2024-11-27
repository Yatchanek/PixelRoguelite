extends PanelContainer
class_name MiniMapContainer

@onready var minimap: MiniMap = %Minimap
@onready var current_position: TextureRect = %CurrentPosition
@onready var gate_location: TextureRect = %GateLocation
@onready var gate_key: TextureRect = %GateKey
@onready var current_pos_label: Label = $MarginContainer/HBoxContainer/HBoxContainer/CurrentPosLabel
@onready var gate_key_label: Label = $MarginContainer/HBoxContainer/HBoxContainer2/GateKeyLabel
@onready var gate_location_label: Label = $MarginContainer/HBoxContainer/HBoxContainer3/GateLocationLabel

func apply_color_palette():
	var stylebox : StyleBoxFlat = StyleBoxFlat.new()
	stylebox.border_color = Globals.color_palettes[Globals.current_palette][3]
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][7]
	stylebox.set_border_width_all(2)
	add_theme_stylebox_override("panel", stylebox)
	
	current_position.modulate = Globals.color_palettes[Globals.current_palette][3]
	gate_key.modulate = Globals.color_palettes[Globals.current_palette][2]
	gate_location.modulate = Globals.color_palettes[Globals.current_palette][0]
		
	current_pos_label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3]
	#gate_key_label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3]
	#gate_location_label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3]	
	
	minimap.apply_color_palette()

func toggle():
	minimap.toggle()
	visible = !visible
	
