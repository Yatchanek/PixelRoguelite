extends CanvasLayer
class_name HUD

@onready var top_bar: PanelContainer = %TopBar
@onready var danger_label: Label = %DangerLabel
@onready var danger_amount_label: Label = %DangerAmountLabel
@onready var hp_bar: TextureProgressBar = %HPBar
@onready var coords_label: Label = %CoordsLabel
@onready var upgrade_card_container: HBoxContainer = $Control/UpgradeCardContainer
@onready var minimap: MiniMap = $Control/Minimap
@onready var keys_container: HBoxContainer = %KeysContainer
@onready var shield_bar: TextureProgressBar = $Control/TopBar/MarginContainer/VBoxContainer/UpperBar/HBoxContainer2/HBoxContainer2/ShieldBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	apply_color_palette()
	EventBus.gate_key_collected.connect(show_gate_key)
	

func update_health(value : int):
	hp_bar.value = value

func update_max_health(value : int):
	hp_bar.max_value = value

func update_danger(amount : int):
	danger_amount_label.text = str(amount)

func update_shield(value : int):
	shield_bar.value = value
	
func update_max_shield(value : int):
	shield_bar.max_value = value


func update_room(room_data : RoomData):
	coords_label.text = str(room_data.coords)
	danger_amount_label.text = str(floor(Utils.get_depth(room_data.coords) / (6 - Settings.difficulty)))

func apply_color_palette():
	var stylebox : StyleBoxFlat = StyleBoxFlat.new()
	stylebox.border_color = Globals.color_palettes[Globals.current_palette][5]
	stylebox.set_border_width_all(1)
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][6]
	
	top_bar.add_theme_stylebox_override("panel", stylebox)
	
	coords_label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3] 
	
	hp_bar.tint_progress = Globals.color_palettes[Globals.current_palette][3]
	shield_bar.tint_progress = Globals.color_palettes[Globals.current_palette][3]
	
	for key in keys_container.get_children():
		key.self_modulate = Globals.color_palettes[Globals.current_palette][7]
	
	for i in keys_container.get_child_count():
		if Globals.keys_collected.has(i):
			keys_container.get_child(i).self_modulate = Globals.color_palettes[Globals.current_palette][0]
		else:
			keys_container.get_child(i).self_modulate = Globals.color_palettes[Globals.current_palette][7]

	minimap.apply_color_palette()

func show_gate_key(idx : int):
	keys_container.get_child(idx).self_modulate = Globals.color_palettes[Globals.current_palette][0]
	
func show_upgrades():
	upgrade_card_container.add_cards()


func toggle_minimap():
	minimap.toggle()
