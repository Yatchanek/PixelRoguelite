extends Node

signal upgrade_card_pressed(data : UpgradeData)
signal player_leveled_up
signal player_max_health_changed(amount : int)
signal upgrade_time
signal room_changed(room_coords : Vector2i)
signal gate_key_collected(number : int)
