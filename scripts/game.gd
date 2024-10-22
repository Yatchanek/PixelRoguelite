extends Node

@onready var hud: HUD = $Hud
@onready var world: Node2D = $World



func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_C:
			Globals.current_palette = wrapi(Globals.current_palette + 1, 0, Globals.color_palettes.size())
			world.apply_color_palette()
			world.player.apply_color_palette()
			world.current_room.change_color_palette()
			Globals.adjust_explosion_colors()
			hud.apply_color_palette()

func _ready() -> void:
	EventBus.upgrade_time.connect(_on_player_leveled_up)
	EventBus.player_max_health_changed.connect(_on_max_health_changed)
	EventBus.upgrade_card_pressed.connect(_on_upgrade_selected)

func _on_player_leveled_up():
	get_tree().paused = true
	await get_tree().create_timer(0.25).timeout
	hud.show_upgrades()

func _on_world_exp_value_changed(value: int) -> void:
	hud.update_exp(value)


func _on_world_player_health_changed(value: int) -> void:
	hud.update_health(value)

func _on_max_health_changed(value : int) -> void:
	hud.update_max_health(value)


func _on_world_room_changed(coords: Vector2) -> void:
	hud.update_room(coords)

func _on_upgrade_selected(_data : UpgradeData) -> void:
	Globals.leveled_up = false
	hud.hide_upgrades()
	await get_tree().create_timer(1.0).timeout
	get_tree().paused = false
