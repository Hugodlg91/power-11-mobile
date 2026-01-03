extends Control

@onready var theme_btn: Button = $Content/ThemeButton
@onready var key_up_btn: Button = $Content/Keys/RowUp/Button
@onready var key_down_btn: Button = $Content/Keys/RowDown/Button
@onready var key_left_btn: Button = $Content/Keys/RowLeft/Button
@onready var key_right_btn: Button = $Content/Keys/RowRight/Button

@onready var sfx_slider: HSlider = $Content/Audio/SFXRow/SliderWrapper/Slider
@onready var sfx_check: CheckBox = $Content/Audio/SFXRow/MuteWrapper/Mute

@onready var back_btn: Button = $BackButton
@onready var bg: ColorRect = $BG

var listening_action: String = ""

func _ready() -> void:
	# Update background to match current theme
	_update_background()
	
	# Debug prints for layout verification
	var win_size = DisplayServer.window_get_size()
	print("SettingsScreen Debug: Window Size: ", win_size)
	print("SettingsScreen Debug: Safe Area: ", DisplayServer.get_display_safe_area())
	if win_size.x < 600:
		push_warning("SettingsScreen: Screen width < 600px, Slider might be clipped!")
	
	# Connect to theme changes
	Settings.connect("theme_changed", _on_theme_changed)
	
	# Hide controls on mobile
	if DisplayServer.is_touchscreen_available():
		$Content/Keys.visible = false
	
	update_ui()
	
	theme_btn.pressed.connect(_cycle_theme)
	back_btn.pressed.connect(_on_back)
	
	key_up_btn.pressed.connect(func(): _start_listening("up", key_up_btn))
	key_down_btn.pressed.connect(func(): _start_listening("down", key_down_btn))
	key_left_btn.pressed.connect(func(): _start_listening("left", key_left_btn))
	key_right_btn.pressed.connect(func(): _start_listening("right", key_right_btn))
	
	sfx_slider.value_changed.connect(_on_sfx_vol_changed)
	sfx_check.toggled.connect(_on_sfx_mute_toggled)

func _on_theme_changed(_new_theme: String) -> void:
	_update_background()

func _update_background() -> void:
	var theme_colors = UIAssets.get_theme_colors(Settings.get_theme_name())
	bg.color = theme_colors["bg"]

func update_ui() -> void:
	# Theme
	var current_theme = Settings.get_theme_name()
	theme_btn.text = "THEME: " + current_theme.to_upper()
	
	# Keys
	var keys = Settings.get_setting("keys", {})
	key_up_btn.text = keys.get("up", "W").to_upper()
	key_down_btn.text = keys.get("down", "S").to_upper()
	key_left_btn.text = keys.get("left", "A").to_upper()
	key_right_btn.text = keys.get("right", "D").to_upper()
	
	# Audio
	sfx_slider.value = Settings.get_setting("sfx_volume", 1.0)
	sfx_check.button_pressed = Settings.get_setting("sfx_muted", false)

func _cycle_theme() -> void:
	var themes = UIAssets.THEMES.keys()
	var current = Settings.get_setting("theme", "Classic")
	var idx = themes.find(current)
	if idx == -1: idx = 0
	
	var next_idx = (idx + 1) % themes.size()
	var new_theme = themes[next_idx]
	
	Settings.set_setting("theme", new_theme) 
	theme_btn.text = "THEME: " + new_theme.to_upper()
	
func _start_listening(action: String, btn: Button) -> void:
	listening_action = action
	btn.text = "..."
	set_process_input(true)

func _is_valid_key(keycode: int) -> bool:
	# Reject modifier-only keys
	if keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
		return false
	# Reject system/special keys that shouldn't be rebound
	if keycode in [KEY_ESCAPE, KEY_ENTER, KEY_TAB, KEY_BACKSPACE]:
		return false
	return true

func _is_duplicate_key(key_str: String, current_action: String) -> bool:
	var keys = Settings.get_setting("keys", {})
	for action in keys:
		if action != current_action and keys[action] == key_str:
			return true
	return false

func _input(event: InputEvent) -> void:
	if listening_action == "": return
	
	if event is InputEventKey and event.pressed:
		var keycode = event.keycode
		
		# Allow ESC to cancel
		if keycode == KEY_ESCAPE:
			listening_action = ""
			update_ui()
			return
		
		# Validate key
		if not _is_valid_key(keycode):
			# Visual feedback for invalid key
			var btn = _get_button_for_action(listening_action)
			if btn:
				btn.text = "INVALID"
				await get_tree().create_timer(0.5).timeout
				if is_inside_tree():
					update_ui()
			listening_action = ""
			return
		
		var key_str = OS.get_keycode_string(keycode)
		
		# Check for duplicates
		if _is_duplicate_key(key_str, listening_action):
			# Visual feedback for duplicate
			var btn = _get_button_for_action(listening_action)
			if btn:
				btn.text = "DUPLICATE"
				await get_tree().create_timer(0.5).timeout
				if is_inside_tree():
					update_ui()
			listening_action = ""
			return
		
		var keys = Settings.get_setting("keys", {})
		keys[listening_action] = key_str
		Settings.set_setting("keys", keys)
		
		Settings.apply_settings() # Update InputMap
		update_ui()
		listening_action = ""

func _get_button_for_action(action: String) -> Button:
	match action:
		"up": return key_up_btn
		"down": return key_down_btn
		"left": return key_left_btn
		"right": return key_right_btn
	return null

func _on_sfx_vol_changed(val: float) -> void:
	Settings.set_setting("sfx_volume", val)

func _on_sfx_mute_toggled(toggled: bool) -> void:
	Settings.set_setting("sfx_muted", toggled)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
