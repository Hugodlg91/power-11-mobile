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

func _process(_delta: float) -> void:
	# Keep label synced if changed in editor
	if label.text != text:
		label.text = text

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
