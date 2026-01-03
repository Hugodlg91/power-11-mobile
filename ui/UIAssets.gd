class_name UIAssets
extends RefCounted

## Utility class for UI Colors and Styles.
## Ported from ui/ui_utils.py

static var THEMES = {
	"Classic": {
		"bg": Color8(187, 173, 160),
		"empty": Color8(205, 193, 180),
		"header_bg": Color8(143, 122, 102),
		"text_dark": Color8(119, 110, 101),
		"text_light": Color8(249, 246, 242),
		"border": Color8(119, 110, 101),
		"tiles": {
			2: Color8(238, 228, 218),
			4: Color8(237, 224, 200),
			8: Color8(242, 177, 121),
			16: Color8(245, 149, 99),
			32: Color8(246, 124, 95),
			64: Color8(246, 94, 59),
			128: Color8(237, 207, 114),
			256: Color8(237, 204, 97),
			512: Color8(237, 200, 80),
			1024: Color8(237, 197, 63),
			2048: Color8(237, 194, 46),
		},
		"tiles_fallback": Color8(60, 58, 50)
	},

	"Dark": {
		"bg": Color8(30, 30, 30),
		"empty": Color8(60, 60, 60),
		"header_bg": Color8(80, 80, 80),
		"text_dark": Color8(200, 200, 200),
		"text_light": Color8(255, 255, 255),
		"border": Color8(255, 255, 255),
		"tiles": {
			2: Color8(80, 80, 90),
			4: Color8(100, 100, 120),
			8: Color8(120, 80, 140),
			16: Color8(140, 60, 160),
			32: Color8(160, 40, 180),
			64: Color8(180, 20, 200),
			128: Color8(200, 100, 100),
			256: Color8(200, 80, 80),
			512: Color8(200, 60, 60),
			1024: Color8(220, 40, 40),
			2048: Color8(240, 20, 20),
		},
		"tiles_fallback": Color8(100, 100, 100)
	},
	"Cyberpunk": {
		"bg": Color8(10, 10, 32),
		"empty": Color8(20, 20, 60),
		"header_bg": Color8(40, 20, 80),
		"text_dark": Color8(255, 255, 255),
		"text_light": Color8(0, 255, 255),
		"border": Color8(0, 255, 255),
		"tiles": {
			2: Color8(20, 40, 80),
			4: Color8(30, 60, 120),
			8: Color8(255, 0, 255),
			16: Color8(200, 0, 255),
			32: Color8(150, 0, 255),
			64: Color8(0, 255, 255),
			128: Color8(0, 200, 200),
			256: Color8(255, 255, 0),
			512: Color8(255, 180, 0),
			1024: Color8(255, 100, 0),
			2048: Color8(255, 0, 0)
		},
		"tiles_fallback": Color8(50, 50, 50)
	}
}

static func get_theme_colors(theme_name: String = "Classic") -> Dictionary:
	return THEMES.get(theme_name, THEMES["Classic"])

static func get_tile_color(value: int, theme_name: String = "Classic") -> Color:
	var theme = get_theme_colors(theme_name)
	var tiles = theme["tiles"]
	if tiles.has(value):
		return tiles[value]
	return theme["tiles_fallback"]

static func get_tile_text_color(value: int, theme_name: String = "Classic") -> Color:
	if theme_name == "Classic":
		if value <= 4:
			return Color8(119, 110, 101) # text_dark
		else:
			return Color8(249, 246, 242) # text_light
	elif theme_name == "Cyberpunk":
		return Color.WHITE
	return Color.WHITE
