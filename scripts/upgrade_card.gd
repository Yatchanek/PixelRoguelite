extends TextureRect
class_name UpgradeCard

@onready var desc_label: Label = $VBoxContainer/DescLabel
@onready var current_amount_label: Label = $VBoxContainer/VBoxContainer/CurrentAmountLabel
@onready var next_amount_label: Label = $VBoxContainer/VBoxContainer/NextAmountLabel
@onready var arrow: TextureRect = $VBoxContainer/VBoxContainer/Arrow

@onready var border: TextureRect = $Border

var upgrade_equipped : UpgradeManager.Upgrades

var disabled : bool = false

signal card_added
signal card_pressed

func _ready() -> void:
	apply_color_palette()
	desc_label.text = UpgradeManager.upgrade_names[upgrade_equipped]
	var units : String = str(UpgradeManager.units[upgrade_equipped])
	if units.length() > 0:
		units = units.insert(0, " ")
	current_amount_label.text = str(Globals.player.get(UpgradeManager.properties[upgrade_equipped])) + units
	next_amount_label.text = str(Globals.player.get(UpgradeManager.properties[upgrade_equipped]) + UpgradeManager.amounts[upgrade_equipped]) + units
	card_added.emit()



func apply_color_palette():
	self_modulate = Globals.color_palettes[Globals.current_palette][6]
	border.self_modulate = Globals.color_palettes[Globals.current_palette][4]
	desc_label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3] 
	arrow.self_modulate = Globals.color_palettes[Globals.current_palette][2] 


func disable():
	disabled = true

func _on_mouse_entered() -> void:
	var stylebox : StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][7]
	stylebox.border_color =  Globals.color_palettes[Globals.current_palette][1]
	stylebox.set_border_width_all(2)
	add_theme_stylebox_override("panel", stylebox)
	
	desc_label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][2] 


func _on_mouse_exited() -> void:
	apply_color_palette()


func _on_gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			card_pressed.emit()
			EventBus.upgrade_card_pressed.emit(upgrade_equipped)
			disable()
