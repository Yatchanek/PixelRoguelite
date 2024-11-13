extends TextureRect
class_name UpgradeCard

@onready var label: Label = $Label
@onready var border: TextureRect = $Border

var upgrade_equipped : UpgradeData

var disabled : bool = false

signal card_added
signal card_pressed

func _ready() -> void:
	apply_color_palette()
	if upgrade_equipped.type == UpgradeManager.Upgrades.FIRERATE:
		label.text = "%s\n+%.2f" % [upgrade_equipped.upgrade_name, upgrade_equipped.amount]
		
	elif upgrade_equipped.amount != 0:
		label.text = "%s\n+%d" % [upgrade_equipped.upgrade_name, upgrade_equipped.amount]
	else:
		label.text = "%s"
	card_added.emit()

func apply_color_palette():
	self_modulate = Globals.color_palettes[Globals.current_palette][6]
	border.self_modulate = Globals.color_palettes[Globals.current_palette][4]
	label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3] 

func disable():
	disabled = true

func _on_button_pressed() -> void:
	card_pressed.emit()
	EventBus.upgrade_card_pressed.emit(upgrade_equipped)


func _on_mouse_entered() -> void:
	var stylebox : StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][7]
	stylebox.border_color =  Globals.color_palettes[Globals.current_palette][1]
	stylebox.set_border_width_all(2)
	add_theme_stylebox_override("panel", stylebox)
	
	label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][2] 


func _on_mouse_exited() -> void:
	apply_color_palette()


func _on_gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			card_pressed.emit()
			EventBus.upgrade_card_pressed.emit(upgrade_equipped)
