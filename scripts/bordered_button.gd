extends PanelContainer
class_name BorderedButton

@onready var texture_button: TextureButton = $TextureButton

var texture : Texture2D
var idx : int

var active : bool = false

signal pressed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	texture_button.texture_normal = texture
	texture_button.texture_hover = texture
	texture_button.texture_pressed = texture
	texture_button.add_to_group("InteractableUI")

func activate():
	var stylebox : StyleBoxFlat = StyleBoxFlat.new()
	stylebox.draw_center = false
	stylebox.border_color = Globals.color_palettes[Globals.current_palette][1]
	stylebox.set_border_width_all(2)
	
	add_theme_stylebox_override("panel", stylebox)
	
	active = true
	
func deactivate():
	var stylebox : StyleBoxEmpty = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", stylebox)
	active = false


func _on_texture_button_pressed() -> void:
	activate()
	pressed.emit(self)
