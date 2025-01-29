extends Node

var jsonSounds: Dictionary = load_json("res://config/sounds.json"); 
var sounds: Dictionary = map_dictionary(jsonSounds)
var players: Dictionary = {}

func map_dictionary(original: Dictionary) -> Dictionary:
	print("Mapping dictionary")
	var result: Dictionary = {}
	for key: String in original.keys():
		result[key] = {
			"audio_stream": load(original[key]["file"]),
		}

		if original[key].has("group"):
			result[key]["group"] = original[key]["group"]

		if original[key].has("volume_db"):
			result[key]["volume_db"] = original[key]["volume_db"]

		if original[key].has("pitch_scale"):
			result[key]["pitch_scale"] = original[key]["pitch_scale"]

		if original[key].has("loop"):
			result[key]["loop"] = original[key]["loop"]

		if original[key].has("delay"):
			result[key]["delay"] = original[key]["delay"]


		if original[key].has("bus"):
			result[key]["bus"] = original[key]["bus"] 

	return result
	
func load_json(file_path: String) -> Dictionary:
	# Open the file
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Error: Unable to open JSON file.")
		return {}
	# Read the file's content
	var content: String = file.get_as_text()
	file.close()
	
	# Parse the JSON content
	var json_parser: JSON = JSON.new()
	var result: int = json_parser.parse(content)
	
	if result != OK:
		print("Error parsing JSON:", json_parser.get_error_message())
		return {}
		
	# Return the parsed dictionary or array
	return json_parser.get_data()

func is_playing(sound_name: String) -> bool:
	return players.has(sound_name)

func play_sound(sound_name: String) -> void:
	if sounds.has(sound_name):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		var timer: Timer
		var config: Dictionary = sounds[sound_name]

		player.stream = config.audio_stream

		if config.has("group"):
			stop_sound_group(config.group)
		
		if config.has("bus"):
			player.bus = config.bus

		if config.has("volume_db"):
			player.volume_db = config.volume_db

		if config.has("pitch_scale"):
			player.pitch_scale = config.pitch_scale

		if config.has("loop") and config.loop and !config.has("delay"):
			player.stream.loop = true
		
		if config.has("delay"):
			timer = Timer.new()
			timer.timeout.connect(func() -> void: player.play())
			timer.wait_time = config.delay
			add_child(timer)
			timer.start()

		var playerItem: Dictionary = {"player": player}

		if timer:
			playerItem["timer"] = timer

		if players.has(sound_name):
			players[sound_name].append(playerItem)
		else:
			players[sound_name] = [playerItem]
		
		add_child(player)
		player.play()

		# Automatically queue the player for deletion when the sound ends
		if !timer:
			player.finished.connect(func() -> void: if player: player.queue_free()) # Connect the finished signal
	else:
		print("Sound not found:", sound_name)

func stop_sound(sound_name: String) -> void:
	if players.has(sound_name):
		for playerItem: Dictionary in players[sound_name]:
			if playerItem.has("timer"):
				playerItem["timer"].stop()
				playerItem["timer"].queue_free()
			if playerItem.has("player") and is_instance_valid(playerItem["player"]):
				playerItem["player"].stop()
				playerItem["player"].queue_free()
		players.erase(sound_name)

func stop_sound_group(group_name: String) -> void:
	for sound_name: String in players.keys():
		if sounds[sound_name].has("group") and sounds[sound_name].group == group_name:
			stop_sound(sound_name)

func stop_all_sounds() -> void:
	for sound_name: String in players.keys():
		stop_sound(sound_name)