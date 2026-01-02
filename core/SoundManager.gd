extends Node

## Global Sound Manager
## Port of ui/sound_manager.py

var music_player: AudioStreamPlayer
var sfx_players: Dictionary = {} # cache for loaded streams? No, players.

# Assets
const SOUND_FILES = {
	"move": "res://assets/sounds/move.wav",
	"merge": "res://assets/sounds/merge.wav",
	"gameover": "res://assets/sounds/gameover.wav"
}
const MUSIC_FILE = "res://assets/sounds/background.wav"

func _ready() -> void:
	# Create Music Player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master" # Start simpler
	add_child(music_player)
	
	# Load Music
	if FileAccess.file_exists(MUSIC_FILE):
		var s = load(MUSIC_FILE)
		if s and s is AudioStreamWAV:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			music_player.stream = s
			music_player.play()
			print("SoundManager: Music loaded and playing")
		elif s:
			print("SoundManager: Music file loaded but wrong format (expected AudioStreamWAV)")
		else:
			print("SoundManager: Failed to load music file: " + MUSIC_FILE)
	else:
		print("SoundManager: Music file not found: " + MUSIC_FILE)
	
	# Connect to Settings
	Settings.connect("volume_changed", _on_volume_changed)
	
	# Initial Volume Apply
	_on_volume_changed()

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
	# Music
	var m_muted = Settings.get_setting("music_muted", false)
	var m_vol = Settings.get_setting("music_volume", 0.1)
	
	if m_muted:
		music_player.volume_db = -80.0
	else:
		music_player.volume_db = linear_to_db(m_vol)
	
	if not music_player.playing and not m_muted and music_player.stream:
		music_player.play()
