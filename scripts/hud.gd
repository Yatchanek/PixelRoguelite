extends CanvasLayer
class_name HUD

@onready var top_bar: PanelContainer = %TopBar
@onready var danger_label: Label = %DangerLabel
@onready var danger_amount_label: Label = %DangerAmountLabel
@onready var hp_bar: TextureProgressBar = %HPBar
@onready var coords_label: Label = %CoordsLabel
@onready var upgrade_row: HBoxContainer = $Control/UpgradeRow
@onready var minimap: MiniMap = $Control/Minimap
@onready var keys_container: HBoxContainer = %KeysContainer

var proposed_upgrades : Array[UpgradeData.Upgrades] = []

var card_scene : PackedScene = preload("res://scenes/upgrade_card.tscn")

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

#func update_exp(amount : int):
	#xp_amount_label.text = str(amount)

func update_room(room_data : RoomData):
	coords_label.text = str(room_data.coords)
	danger_amount_label.text = str(floor(Utils.get_depth(room_data.coords) / 3.0))

func apply_color_palette():
	var stylebox : StyleBoxFlat = StyleBoxFlat.new()
	stylebox.border_color = Globals.color_palettes[Globals.current_palette][5]
	stylebox.set_border_width_all(1)
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][6]
	
	top_bar.add_theme_stylebox_override("panel", stylebox)
	
	coords_label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3] 
	
	hp_bar.tint_progress = Globals.color_palettes[Globals.current_palette][3]
	
	for key in keys_container.get_children():
		key.self_modulate = Globals.color_palettes[Globals.current_palette][7]
	
	for i : int in Globals.keys_collected:
		keys_container.get_child(i).self_modulate = Globals.color_palettes[Globals.current_palette][0]
	
	minimap.apply_color_palette()

func show_gate_key(idx : int):
	keys_container.get_child(idx).self_modulate = Globals.color_palettes[Globals.current_palette][0]
	
func show_upgrades():
	upgrade_row.show()
	proposed_upgrades = []
	add_card()
	
func add_card():
	var card : UpgradeCard = card_scene.instantiate()
	card.cards_in_row = 3
	card.other_upgrades = proposed_upgrades
	card.card_added.connect(_on_card_added)
	card.last_card_added.connect(_on_last_card_added)
	upgrade_row.call_deferred("add_child", card)
	
func _on_card_added(data : UpgradeData):
	proposed_upgrades.append(data.current_type)
	add_card()

func _on_last_card_added() -> void:
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tw.set_parallel()
	var idx : int = 0
	for card in upgrade_row.get_children():
		tw.tween_property(card, "position:y", 320, 1.0).set_delay(idx * 0.25)
		idx += 1

func hide_upgrades():
	proposed_upgrades = []
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.set_parallel()
	var idx : int = 0
	for card in upgrade_row.get_children():
		tw.tween_property(card, "position:y", 0, 1.0).set_delay(idx * 0.25)
		idx += 1
	await tw.finished
	for card in upgrade_row.get_children():
		card.queue_free()
	upgrade_row.hide()

func toggle_minimap():
	minimap.toggle()
