extends Node2D

var game: Game2048
@onready var label: Label = $BoardLabel

func _ready() -> void:
	game = Game2048.new()
	update_display()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			game.reset()
			update_display()
			return
			
		var moved: bool = false
		if event.is_action_pressed("ui_left"):
			moved = game.move("left")
		elif event.is_action_pressed("ui_right"):
			moved = game.move("right")
		elif event.is_action_pressed("ui_up"):
			moved = game.move("up")
		elif event.is_action_pressed("ui_down"):
			moved = game.move("down")
			
		if moved:
			update_display()
			if game.is_game_over():
				label.text += "\n\nGAME OVER! Press R"

func update_display() -> void:
	var board = game.get_board_array()
	var text = "Score: %d\n\n" % game.score
	
	for row in board:
		for val in row:
			if val == 0:
				text += "[ . ]\t"
			else:
				text += "[ %d ]\t" % val
		text += "\n\n"
	
	text += "\nControls: Arrows / WASD\nR: Restart"
	label.text = text
