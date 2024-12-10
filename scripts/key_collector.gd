extends Node2D

@onready var key_symbols: Node2D = $KeySymbols

var elapsed_time : float = 0

var anim_phase : int = 0

signal all_keys_collected

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in key_symbols.get_child_count():
		key_symbols.get_child(i).region_rect.position.x = 16 * i
		key_symbols.get_child(i).self_modulate = Globals.color_palettes[Globals.current_palette][6]
	
	
	check_for_keys_at_load()
	
func check_for_keys_at_load():
	for key : int in Globals.keys_returned:
		key_symbols.get_child(key).self_modulate = Globals.color_palettes[Globals.current_palette][1]
	
	if Globals.keys_returned.size() == 9:
		all_keys_collected.emit()
		
func check_for_keys():
	for key : int in Globals.keys_collected:
		if !Globals.keys_returned.has(key):
			key_symbols.get_child(key).self_modulate = Globals.color_palettes[Globals.current_palette][1]
			Globals.keys_returned.append(key)
	
	if Globals.keys_returned.size() == 9:
		SoundManager.switch_music(SoundManager.Music.GAME_WON_MUSIC)
		all_keys_collected.emit()
		$Area2D/CollisionShape2D.set_deferred("disabled", false)
	else:
		EventBus.gate_approached.emit()		

	
func _on_area_2d_body_entered(_body: Node2D) -> void:
	check_for_keys()


func _on_area_2d_body_exited(_body: Node2D) -> void:
	EventBus.gate_left.emit()
