extends Node

## Global Settings Manager
## Port of core/settings.py

signal settings_changed
signal theme_changed(new_theme)
signal volume_changed

const SETTINGS_FILE = "user://settings.json"

var default_settings = {
	"keys": {
		"up": "Up",     # Godot Input Map action names or Key names? Python used "w".
		"down": "Down", # We will stick to InputMap actions "ui_up" etc for now, 
						# but for custom keys we might need to update InputMap at runtime.
						# For exact port, we'll store key codes or string representations.
						# Let's use physical key codes or InputMap action remapping.
		"left": "Left",
		"right": "Right"
	},
	"highscore": 0,
	"theme": "Classic",
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"music_muted": false,
	"sfx_muted": false
}

var current_settings: Dictionary = {}

func _ready() -> void:
	load_settings()
	apply_settings()

func load_settings() -> void:
	current_settings = default_settings.duplicate(true)
	
	if FileAccess.file_exists(SETTINGS_FILE):
		var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
		if file:
			var json = JSON.new()
			var text = file.get_as_text()
			var err = json.parse(text)
			
			if err == OK:
				var data = json.data
				if data is Dictionary:
					# Merge loaded data with defaults, validating types
					for k in data:
						if current_settings.has(k):
							# Type checking
							var expected_type = typeof(current_settings[k])
							var actual_type = typeof(data[k])
							
							if expected_type == actual_type:
								current_settings[k] = data[k]
							else:
								print("Settings: Type mismatch for key '%s', using default" % k)
				else:
					print("Settings: Loaded data is not a Dictionary, using defaults")
			else:
				print("Settings: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
				print("Settings: Using default settings")
		else:
			print("Settings: Failed to open file, using defaults")
	
	save_settings() # Ensure file exists/is updated with partial new defaults

func save_settings() -> void:
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(current_settings, "\t")
		file.store_string(json_string)

func apply_settings() -> void:
	_apply_input_map()
	emit_signal("theme_changed", current_settings["theme"])
	emit_signal("volume_changed")

func _apply_input_map() -> void:
	var keys = current_settings.get("keys", {})
	var actions = {
		"up": "ui_up",
		"down": "ui_down",
		"left": "ui_left",
		"right": "ui_right"
	}
	
	for key_action in keys:
		if actions.has(key_action):
			var godot_action = actions[key_action]
			var key_str = keys[key_action]
			
			if not key_str or key_str == "":
				continue  # Skip empty key bindings
			
			var keycode = OS.find_keycode_from_string(key_str)
			if keycode != KEY_NONE:
				# Check if already bound
				if not InputMap.has_action(godot_action):
					print("Settings: Action '%s' does not exist in InputMap" % godot_action)
					continue
					
				var events = InputMap.action_get_events(godot_action)
				var found = false
				for e in events:
					if e is InputEventKey and e.keycode == keycode:
						found = true
						break
				
				if not found:
					var new_event = InputEventKey.new()
					new_event.keycode = keycode
					InputMap.action_add_event(godot_action, new_event)
					print("Settings: Bound '%s' to action '%s'" % [key_str, godot_action])
			else:
				print("Settings: Invalid keycode for '%s': %s" % [key_action, key_str])


# --- Getters / Setters ---
func get_setting(key: String, default_val = null):
	return current_settings.get(key, default_val)

func set_setting(key: String, value) -> void:
	current_settings[key] = value
	save_settings()
	emit_signal("settings_changed")
	
	if key == "theme":
		emit_signal("theme_changed", value)
	elif "volume" in key or "muted" in key:
		emit_signal("volume_changed")

func get_highscore() -> int:
	return int(current_settings.get("highscore", 0))

func set_highscore(val: int) -> void:
	if val > get_highscore():
		set_setting("highscore", val)

func get_theme_name() -> String:
	return str(current_settings.get("theme", "Classic"))
