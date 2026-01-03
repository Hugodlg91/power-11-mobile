extends Button

@export var bg_color: Color = Color8(143, 122, 102)
@export var text_color: Color = Color.WHITE

@onready var bg_rect: ColorRect = $ColorRect
@onready var label: Label = $Label

func _ready() -> void:
	# Hide default button style
	flat = true
	
	bg_rect.color = bg_color
	label.text = text
	label.modulate = text_color
	
	# Connect signals
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	
	# Initial Sizing
	call_deferred("_update_size") # Defer to ensure fonts are loaded/theme applied

func _process(_delta: float) -> void:
	# Keep label synced if changed in editor
	if label.text != text:
		label.text = text
		_update_size()

func _update_size() -> void:
	if not is_node_ready(): return
	
	# Add padding to text size
	var font = label.get_theme_font("font")
	var font_size = label.get_theme_font_size("font_size")
	if not font:
		return 
		
	var text_size = font.get_string_size(
		text, 
		HORIZONTAL_ALIGNMENT_LEFT, 
		-1, 
		font_size
	)
	var min_w = max(80, text_size.x + 40) # Minimum 80, or text + 40px padding
	custom_minimum_size.x = min_w

func _on_hover() -> void:
	bg_rect.color = bg_color.lightened(0.1)

func _on_exit() -> void:
	bg_rect.color = bg_color

func _on_down() -> void:
	bg_rect.color = bg_color.darkened(0.1)
	position.y += 2

func _on_up() -> void:
	bg_rect.color = bg_color.lightened(0.1)
	position.y -= 2
