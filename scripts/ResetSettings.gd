extends SceneTree

func _init():
	var settings_path = "user://settings.json"
	
	if FileAccess.file_exists(settings_path):
		print("Found existing settings file.")
		var err = DirAccess.remove_absolute(settings_path)
		if err == OK:
			print("✅ Successfully deleted user://settings.json")
		else:
			print("❌ Failed to delete settings file. Error: ", err)
	else:
		print("No settings file found to delete.")
		
	# Verify Music File Access
	var music_path = "res://assets/sounds/background.wav"
	if FileAccess.file_exists(music_path):
		print("✅ Music file found at: ", music_path)
	else:
		print("❌ Music file MISSING at: ", music_path)
		
	quit()
