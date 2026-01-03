extends SceneTree

func _init():
	print("Testing Audio System...")
	
	# Load SoundManager script (not the singleton, manually instancing for test)
	var sm_script = load("res://core/SoundManager.gd")
	var sm = sm_script.new()
	root.add_child(sm)
	
	# Force _ready (simulating AutoLoad)
	# sm._ready() # _ready is called automatically when added to tree
	
	# Wait a bit for loading
	await create_timer(0.5).timeout
	
	var mp = sm.music_player
	print("Music Player Valid: ", mp != null)
	if mp:
		print("Stream: ", mp.stream)
		if mp.stream:
			print("Stream Length: ", mp.stream.get_length())
		print("Is Playing: ", mp.playing)
		print("Volume dB: ", mp.volume_db)
		print("Playback Position: ", mp.get_playback_position())
		print("Bus: ", mp.bus)
		
		if mp.playing and mp.get_playback_position() > 0:
			print("SUCCESS: Music is playing and advancing.")
		else:
			print("FAILURE: Music not playing or stuck.")
			# Try force play
			print("Forcing Play...")
			mp.play()
			print("Is Playing Now: ", mp.playing)
	
	quit()
