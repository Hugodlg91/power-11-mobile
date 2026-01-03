extends Control

const PlayScene = preload("res://ui/PlayScreen.tscn")
# const VersusScene = preload("res://ui/VersusScreen.tscn")
# const SettingsScene = preload("res://ui/SettingsScreen.tscn")
# const LeaderboardScene = preload("res://ui/LeaderboardScreen.tscn")

@onready var btn_play: Button = $VBoxContainer/BtnPlay
@onready var btn_versus: Button = $VBoxContainer/BtnVersus
@onready var btn_settings: Button = $VBoxContainer/BtnSettings
@onready var btn_leaderboard: Button = $VBoxContainer/BtnLeaderboard
@onready var btn_quit: Button = $VBoxContainer/BtnQuit
@onready var bg: ColorRect = $BG

func _ready() -> void:
	# Update background to match current theme
	_update_background()
	
	# Connect to theme changes
	Settings.connect("theme_changed", _on_theme_changed)
	
	btn_play.pressed.connect(_on_play_pressed)
	btn_versus.pressed.connect(_on_versus_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_leaderboard.pressed.connect(_on_leaderboard_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

func _on_theme_changed(_new_theme: String) -> void:
	_update_background()

func _update_background() -> void:
	var theme_colors = UIAssets.get_theme_colors(Settings.get_theme_name())
	bg.color = theme_colors["bg"]

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/PlayScreen.tscn")

func _on_versus_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/VersusScreen.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/SettingsScreen.tscn")

func _on_leaderboard_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/LeaderboardScreen.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
