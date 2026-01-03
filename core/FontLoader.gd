extends Node

func _ready() -> void:
	_try_load_font()

func _try_load_font() -> void:
	# Scanning directories in exported projects is fragile (FileAccess/DirAccess issues).
	# We hardcode the known font path.
	var font_path = "res://assets/fonts/PressStart2P.ttf"
	_apply_global_font(font_path)

func _apply_global_font(path: String) -> void:
	# Directly attempt load to support exported resources
	var font = load(path)
	if font:
		print("FontLoader: Applying found font: ", path)
		
		var theme = Theme.new()
		theme.default_font = font
		theme.default_font_size = 16 # Base size
		
		get_tree().root.theme = theme
		print("FontLoader: Theme applied to Root.")
	else:
		print("FontLoader: Failed to load font from: ", path)
