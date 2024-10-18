extends CanvasLayer
class_name HUD

@onready var top_bar: PanelContainer = %TopBar
@onready var bottom_bar: PanelContainer = %BottomBar
@onready var xp_label: Label = %XPLabel
@onready var xp_amount_label: Label = %XPAmountLabel
@onready var hp_bar: TextureProgressBar = %HPBar
@onready var coords_label: Label = %CoordsLabel
@onready var upgrade_row: HBoxContainer = $Control/UpgradeRow

var proposed_upgrades : Array[UpgradeData.Upgrades] = []

var card_scene : PackedScene = preload("res://scenes/upgrade_card.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	apply_color_palette()

func update_health(value : int):
	hp_bar.value = value

func update_max_health(value : int):
	hp_bar.max_value = value

func update_exp(amount : int):
	xp_amount_label.text = str(amount)

func update_room(coords : Vector2):
	coords_label.text = str(coords)

func apply_color_palette():
	var stylebox : StyleBoxFlat = StyleBoxFlat.new()
	#stylebox.border_color = Globals.color_palettes[Globals.current_palette][5]
	#stylebox.set_border_width_all(1)
	stylebox.bg_color = Globals.color_palettes[Globals.current_palette][6]
	
	top_bar.add_theme_stylebox_override("panel", stylebox)
	bottom_bar.add_theme_stylebox_override("panel", stylebox)
	
	xp_label.label_settings.font_color = Globals.color_palettes[Globals.current_palette][3] 
	
	hp_bar.tint_progress = Globals.color_palettes[Globals.current_palette][2] 
	
func show_upgrades():
	upgrade_row.show()
	proposed_upgrades = []
	add_card()
	
func add_card():
	var card : UpgradeCard = card_scene.instantiate()
	card.cards_in_row = 3
	card.other_upgrades = proposed_upgrades
	card.card_added.connect(_on_card_added)
	upgrade_row.call_deferred("add_child", card)
	
func _on_card_added(data : UpgradeData):
	proposed_upgrades.append(data.current_type)
	add_card()

func hide_upgrades():
	proposed_upgrades = []
	for card in upgrade_row.get_children():
		card.queue_free()
	upgrade_row.hide()
