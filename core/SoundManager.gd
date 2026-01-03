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
	# Load Music Asset
	if FileAccess.file_exists(MUSIC_FILE):
		var s = load(MUSIC_FILE)
		if s and s is AudioStreamWAV:
			# Force parameters on the resource
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			_start_music_player(s)
		else:
			print("SoundManager: invalid music file")
	else:
		print("SoundManager: music file missing")

	# Connect to Settings
	Settings.connect("volume_changed", _on_volume_changed)
	
func _start_music_player(stream: AudioStream) -> void:
	if music_player:
		music_player.queue_free()
		
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	music_player.stream = stream
	add_child(music_player)
	
	# Loop handling
	music_player.finished.connect(func(): 
		if not Settings.get_setting("music_muted", false):
			music_player.play()
	)
	
	_update_music_volume()
	music_player.play()
	print("SoundManager: Music player initialized")

func _update_music_volume() -> void:
	if not music_player: return
	
	var m_muted = Settings.get_setting("music_muted", false)
	var m_vol = Settings.get_setting("music_volume", 1.0)
	
	if m_muted:
		music_player.volume_db = -80.0
	else:
		music_player.volume_db = linear_to_db(m_vol)

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
	_update_music_volume()
	
	if music_player and not music_player.playing and not Settings.get_setting("music_muted", false):
		music_player.play()
