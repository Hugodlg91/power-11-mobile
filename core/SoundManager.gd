extends Node

## Global Sound Manager
## Port of ui/sound_manager.py

var sfx_players: Dictionary = {} # cache for loaded streams? No, players.

# Assets
const SOUND_FILES = {
	"move": "res://assets/sounds/move.wav",
	"merge": "res://assets/sounds/merge.wav",
	"gameover": "res://assets/sounds/gameover.wav"
}
const MUSIC_FILE = "res://assets/sounds/background.wav"

func _ready() -> void:
	# Connect to Settings
	Settings.connect("volume_changed", _on_volume_changed)

func play(sfx_name: String) -> void:
	if Settings.get_setting("sfx_muted", false):
		return
		
	if not SOUND_FILES.has(sfx_name):
		print("SoundManager: Unknown sound effect: " + sfx_name)
		return
		
	var path = SOUND_FILES[sfx_name]
	if not FileAccess.file_exists(path):
		print("SoundManager: Sound file not found: " + path)
		return
		
	var stream = load(path)
	if not stream:
		print("SoundManager: Failed to load sound: " + path)
		return
		
	var p = AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = linear_to_db(Settings.get_setting("sfx_volume", 1.0))
	p.finished.connect(p.queue_free)
	add_child(p)
	p.play()

func _on_volume_changed() -> void:
	pass
