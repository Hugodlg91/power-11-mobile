extends Node

func _ready() -> void:
	_try_load_font()

func _try_load_font() -> void:
	var font_dir = "res://assets/fonts/"
	var dir = DirAccess.open(font_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				if file_name.ends_with(".ttf") or file_name.ends_with(".otf"):
					var font_path = font_dir + file_name
					dir.list_dir_end()  # Close directory before returning
					_apply_global_font(font_path)
					return
			file_name = dir.get_next()
		dir.list_dir_end()  # Close directory
	else:
		print("FontLoader: Failed to open directory: ", font_dir)

	print("FontLoader: No font found in ", font_dir)

func _apply_global_font(path: String) -> void:
	if FileAccess.file_exists(path):
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
	else:
		print("FontLoader: Font file does not exist: ", path)
