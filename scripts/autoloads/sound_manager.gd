extends Node

@onready var effect_channels: Node = $EffectChannels
@onready var music_players: Node = $MusicPlayers

@onready var timer: Timer = $Timer

@export var sound_effects : Array[AudioStream] = []
@export var music_tracks : Array[AudioStream] = []

enum Effects {
	PLAYER_SHOOT,
	ENEMY_SHOOT,
	LASER,
	MISSILE,
	HIT,
	EXPLOSION,
	PICKUP_HEALTH,
	PICKUP_SHIELD,
	PICKUP_MAP,
	PICKUP_KEY,
	PLAYER_DEATH,
	UPGRADE,
	MENU_NAVIGATE,
	MENU_SELECT,
	MENU_START_GAME,
	GAME_WON,
	
}

enum Music {
	TITLE_SCREEN_MUSIC,
	MAIN_MUSIC,
	BATTLE_MUSIC,
	GAME_WON_MUSIC
}

var current_music_player : AudioStreamPlayer
var next_music_player : AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_music_player = $MusicPlayers/AudioStreamPlayer
	next_music_player = $MusicPlayers/AudioStreamPlayer2
	current_music_player.volume_db = -80
	next_music_player.volume_db = -80

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

func play_music(music : Music):
	for player : AudioStreamPlayer in music_players.get_children():
		player.stop()
	current_music_player.stream = music_tracks[music]
	current_music_player.play()
	if current_music_player.volume_db < 0:
		var tw : Tween = create_tween()
		tw.tween_property(current_music_player, "volume_db", 0.0, 2.0)
	timer.start(current_music_player.stream.get_length() - 3)
	
func switch_music(music : Music, restart : bool = false):
	if current_music_player.stream == music_tracks[music] and !restart:
		return
	next_music_player.stream = music_tracks[music]
	next_music_player.play()
	var tw : Tween = create_tween()
	tw.set_parallel()
	tw.tween_property(current_music_player, "volume_db", -80.0, 3.0)
	tw.tween_property(next_music_player, "volume_db", 0.0, 2.0)
	await tw.finished
	var temp : AudioStreamPlayer = current_music_player
	current_music_player = next_music_player
	next_music_player = temp

func _on_timer_timeout() -> void:
	
	if current_music_player.stream == music_tracks[Music.MAIN_MUSIC]:
		switch_music(Music.MAIN_MUSIC)
	elif current_music_player.stream == music_tracks[Music.TITLE_SCREEN_MUSIC]:
		switch_music(Music.TITLE_SCREEN_MUSIC)
	elif current_music_player.stream == music_tracks[Music.BATTLE_MUSIC]:
		switch_music(Music.BATTLE_MUSIC)
	else:
		switch_music(Music.GAME_WON_MUSIC)	
