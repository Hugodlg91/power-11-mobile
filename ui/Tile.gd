extends Control

@onready var bg_panel: Panel = $Panel
@onready var number_label: Label = $Label

var value: int = 0
var grid_pos: Vector2i = Vector2i(0, 0)
var tile_size: int = 0

func setup(val: int, p_size: int, pos_grid: Vector2i, pos_px: Vector2, theme_name: String) -> void:
	value = val
	tile_size = p_size
	grid_pos = pos_grid
	
	size_flags_horizontal = 0
	size_flags_vertical = 0
	custom_minimum_size = Vector2(p_size, p_size)
	
	position = pos_px
	size = Vector2(p_size, p_size)
	
	update_appearance(theme_name)

func update_appearance(theme_name: String) -> void:
	var color = UIAssets.get_tile_color(value, theme_name)
	
	# Create rounded style
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8) # 8px radius looks good for 100px tiles
	style.corner_detail = 5
	
	bg_panel.add_theme_stylebox_override("panel", style)
	
	number_label.text = str(value)
	number_label.modulate = UIAssets.get_tile_text_color(value, theme_name)
	
	# Initial Font Sizing
	var font_scale = 0.5
	if value < 10:
		font_scale = 0.55
	elif value < 100:
		font_scale = 0.45 
	elif value < 1000:
		font_scale = 0.35
	else:
		font_scale = 0.25
		
	number_label.add_theme_font_size_override("font_size", int(tile_size * font_scale))

func animate_spawn() -> void:
	pivot_offset = Vector2(tile_size/2.0, tile_size/2.0)
	scale = Vector2(0, 0)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func animate_merge() -> void:
	pivot_offset = Vector2(tile_size/2.0, tile_size/2.0)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func animate_move(target_pos: Vector2, duration: float) -> void:
	var tw = create_tween()
	tw.tween_property(self, "position", target_pos, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
