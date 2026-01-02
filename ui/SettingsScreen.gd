extends Control

@onready var theme_btn: Button = $Content/ThemeButton
@onready var key_up_btn: Button = $Content/Keys/RowUp/Button
@onready var key_down_btn: Button = $Content/Keys/RowDown/Button
@onready var key_left_btn: Button = $Content/Keys/RowLeft/Button
@onready var key_right_btn: Button = $Content/Keys/RowRight/Button

@onready var music_slider: HSlider = $Content/Audio/MusicRow/Slider
@onready var music_check: CheckBox = $Content/Audio/MusicRow/Mute
@onready var sfx_slider: HSlider = $Content/Audio/SFXRow/Slider
@onready var sfx_check: CheckBox = $Content/Audio/SFXRow/Mute

@onready var back_btn: Button = $BackButton

var listening_action: String = ""

func _ready() -> void:
	update_ui()
	
	theme_btn.pressed.connect(_cycle_theme)
	back_btn.pressed.connect(_on_back)
	
	key_up_btn.pressed.connect(func(): _start_listening("up", key_up_btn))
	key_down_btn.pressed.connect(func(): _start_listening("down", key_down_btn))
	key_left_btn.pressed.connect(func(): _start_listening("left", key_left_btn))
	key_right_btn.pressed.connect(func(): _start_listening("right", key_right_btn))
	
	music_slider.value_changed.connect(_on_music_vol_changed)
	sfx_slider.value_changed.connect(_on_sfx_vol_changed)
	music_check.toggled.connect(_on_music_mute_toggled)
	sfx_check.toggled.connect(_on_sfx_mute_toggled)

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
	music_slider.value = Settings.get_setting("music_volume", 0.1)
	sfx_slider.value = Settings.get_setting("sfx_volume", 1.0)
	music_check.button_pressed = Settings.get_setting("music_muted", false)
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
	# Apply visually immediately? PlayScreen handles it on ready/process. 
	# Settings logic emits signal, UIAssets updates? 
	# Actually UIAssets is static helper.
	# We might need to reload specific nodes if we want immediate feedback here, 
	# but this screen is just settings. The signal is enough for other screens.
	
func _start_listening(action: String, btn: Button) -> void:
	listening_action = action
	btn.text = "..."
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if listening_action == "": return
	
	if event is InputEventKey and event.pressed:
		var keycode = event.keycode
		var key_str = OS.get_keycode_string(keycode)
		
		var keys = Settings.get_setting("keys", {})
		keys[listening_action] = key_str
		Settings.set_setting("keys", keys)
		
		Settings.apply_settings() # Update InputMap
		update_ui()
		listening_action = ""

func _on_music_vol_changed(val: float) -> void:
	Settings.set_setting("music_volume", val)

func _on_sfx_vol_changed(val: float) -> void:
	Settings.set_setting("sfx_volume", val)

func _on_music_mute_toggled(toggled: bool) -> void:
	Settings.set_setting("music_muted", toggled)

func _on_sfx_mute_toggled(toggled: bool) -> void:
	Settings.set_setting("sfx_muted", toggled)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
