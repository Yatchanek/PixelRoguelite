extends Node

@onready var hud: HUD = $Hud
@onready var world: Node2D = $World


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Globals.new_game()
	EventBus.upgrade_time.connect(_on_player_leveled_up)
	EventBus.room_changed.connect(_on_room_changed)

func _on_player_leveled_up():
	get_tree().paused = true
	await get_tree().create_timer(0.25).timeout
	hud.show_upgrades()

func _on_room_changed(room_data : RoomData) -> void:
	hud.update_room(room_data)
