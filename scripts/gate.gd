extends Node2D

@onready var key_symbols: Node2D = $KeySymbols
@onready var color_bars: Node2D = $ColorBars

var elapsed_time : float = 0

var anim_phase : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	apply_color_palette()
	for i in key_symbols.get_child_count():
		key_symbols.get_child(i).region_rect.position.x = 16 * i
		key_symbols.get_child(i).self_modulate = Globals.color_palettes[Globals.current_palette][1]
	
	show_symbol()
	
func _process(delta: float) -> void:
	elapsed_time += delta
	if elapsed_time > 0.05:
		elapsed_time -= 0.05
		anim_phase += 1
		advance_anim()
		
		
func advance_anim():
	for i in $ColorBars.get_child_count():
		var polygon : Polygon2D = $ColorBars.get_child(i)
		polygon.color = Globals.color_palettes[Globals.current_palette][(i - anim_phase) % 8]



func apply_color_palette():
	for i in $ColorBars.get_child_count():
		var polygon : Polygon2D = $ColorBars.get_child(i)
		polygon.color = Globals.color_palettes[Globals.current_palette][i]

func show_symbol(idx : int = 0):
	if idx > key_symbols.get_child_count() - 1:
		show_bar()
		return

	var tw : Tween = create_tween()
	tw.tween_property(key_symbols.get_child(idx), "modulate:a", 1.0, 0.15)
	await tw.finished
	
	show_symbol(idx + 1)

func show_bar(idx : int = 0):
	if idx > $ColorBars.get_child_count() - 1:
		set_process(true)
		$Area2D/CollisionShape2D.set_deferred("disabled", false)
		return
		
	var tw : Tween = create_tween()
	tw.tween_property($ColorBars.get_child(idx), "modulate:a", 1.0, 0.15)
	await tw.finished
	
	show_bar(idx + 1)
	
func _on_area_2d_body_entered(_body: Node2D) -> void:
	EventBus.game_completed.emit()
