extends PanelContainer
class_name UpgradeCard

@onready var label: Label = $Button/Label

var upgrade_equipped : UpgradeData
var other_upgrades : Array[UpgradeData.Upgrades] = []

var cards_in_row : int

signal card_added(data : UpgradeData)
signal last_card_added

func _ready() -> void:
	apply_color_palette()
	upgrade_equipped = UpgradeData.new()
	upgrade_equipped.configure(Globals.player, other_upgrades)
	label.text = "%s\n+%s" % [upgrade_equipped.upgrade_name, upgrade_equipped.amount]
	
	if get_index() < cards_in_row - 1:
		card_added.emit(upgrade_equipped)
	else:
		last_card_added.emit()


func apply_color_palette():
	var stylebox : StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][6]
	stylebox.border_color =  Globals.color_palettes[Globals.current_palette][2]
	stylebox.set_border_width_all(2)
	add_theme_stylebox_override("panel", stylebox)
	
	label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3] 


func _on_button_pressed() -> void:
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
