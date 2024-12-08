extends Node

signal upgrade_card_pressed(upgrade : UpgradeManager.Upgrades)
signal player_leveled_up
signal upgrade_time
signal room_changed(room_coords : Vector2i)
signal gate_key_collected(number : int)
signal gate_approached
signal gate_left
signal game_completed
signal map_found
