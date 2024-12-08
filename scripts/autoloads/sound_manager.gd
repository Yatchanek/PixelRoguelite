extends Node

@onready var effect_channels: Node = $EffectChannels

@export var sound_effects : Array[AudioStream] = []

enum Effects {
	PLAYER_SHOOT,
	ENEMY_SHOOT,
	LASER,
	MISSILE,
	HIT,
	EXPLOSION,
	PICKUP_HEALTH,
	PICKUP_SHIELD,
	PLAYER_DEATH,
	MENU_NAVIGATE,
	MENU_SELECT,
	MENU_START_GAME,
	GAME_WON
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func play_effect(effect : Effects):
	for player : AudioStreamPlayer in effect_channels.get_children():
		if !player.playing:
			player.stream = sound_effects[effect]
			player.play()
			break
			
func stop_effect(effect : Effects):
	for player : AudioStreamPlayer in effect_channels.get_children():
		if player.stream == sound_effects[effect]:
			player.stop()
