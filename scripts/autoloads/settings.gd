extends Node

var zone_size : int = 1
var difficulty : int = 1

var master_volume : float = 0
var effects_volume : float = 0
var music_volume : float = 0

var color_palette : int = 0

func _ready() -> void:
	load_settings()

func save_settings():
	var config_file : ConfigFile = ConfigFile.new()
	
	config_file.set_value("Gameplay Settings", "zone_size", zone_size)
	config_file.set_value("Gameplay Settings", "difficulty", difficulty)
	
	config_file.set_value("Graphics Settings", "color_palette", color_palette)
	
	config_file.set_value("Sound Settings", "master_volume", master_volume)
	config_file.set_value("Sound Settings", "effects_volume", effects_volume)
	config_file.set_value("Sound Settings", "music_volume", music_volume)
	
	config_file.save_encrypted_pass("user://settings.ini", "HigH$C0r3$")

func load_settings():
	var config_file : ConfigFile = ConfigFile.new()

	var err : Error = config_file.load_encrypted_pass("user://settings.ini", "HigH$C0r3$")
	
	if !err == OK:
		await get_tree().process_frame
		return
	
	#if !config_file.has_section("Version") or config_file.get_value("Version", "version") != version:
		#save_settings()
		#settings_loaded.emit()
		#return
	
	var config_sections : PackedStringArray = config_file.get_sections()
	
	for section in config_sections:
		var config_keys : PackedStringArray = config_file.get_section_keys(section)
		for config_key in config_keys:
			set(config_key, config_file.get_value(section, config_key))
