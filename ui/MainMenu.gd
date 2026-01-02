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

func _ready() -> void:
	btn_play.pressed.connect(_on_play_pressed)
	btn_versus.pressed.connect(_on_versus_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_leaderboard.pressed.connect(_on_leaderboard_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

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
