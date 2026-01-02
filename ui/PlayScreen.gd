extends Control

# NODES
@onready var game_board: Control = $GameBoard
@onready var score_label: Label = $Header/ScoreBox/Value
@onready var best_label: Label = $Header/BestBox/Value
@onready var game_over_overlay: Control = $GameOverOverlay

# BUTTONS
@onready var btn_back: Button = $BtnBack
@onready var btn_reset: Button = $BtnReset

# GAME STATE
var game: Game2048
var ai_player: AIPlayer # For debug
var old_board_state: Array = [] # For animation - saved BEFORE move

func _ready() -> void:
	game = Game2048.new()
	ai_player = AIPlayer.new()
	
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(reset_game)
	
	# Setup GameBoard (matching VersusScreen approach)
	var board_size = 400.0  # Adjust based on your UI
	var margin = 10
	game_board.setup(board_size, margin)
	game_board.update_theme(Settings.get_setting("theme", "Classic"))
	
	# Initial board spawn
	reset_game()
	
	# Initial highscore
	best_label.text = str(Settings.get_highscore())
	
	# AI for testing/debugging
	ai_player = AIPlayer.new()
	
	# Debug keys: R = Reset game, A = AI hint move

func reset_game() -> void:
	game.reset()
	game_over_overlay.visible = false
	old_board_state = game.get_board_array_copy()
	game_board.spawn_board(game.get_board_array())
	score_label.text = "0"

func _input(event: InputEvent) -> void:
	if game.is_game_over(): return
	if game_board.is_animating: return  # Don't accept input during animation
	
	var moved = false
	var direction = ""
	
	if event.is_action_pressed("ui_left"): direction = "left"
	elif event.is_action_pressed("ui_right"): direction = "right"
	elif event.is_action_pressed("ui_up"): direction = "up"
	elif event.is_action_pressed("ui_down"): direction = "down"
	
	# Manual Reset
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		reset_game()
		return
		
	# AI Debug
	if event is InputEventKey and event.pressed and event.keycode == KEY_A:
		var best = ai_player.choose_best_move(game.current_board_state)
		if best:
			direction = best
	
	if direction != "":
		# Save old board BEFORE the move (matching Python original)
		old_board_state = game.get_board_array_copy()
		
		# Make the move
		moved = game.move(direction)
		
		if moved:
			SoundManager.play("move")
			
			# Animate transition (matching Python's animator.start_move_animation)
			var new_board = game.get_board_array()
			game_board.animate_transition(old_board_state, new_board, direction)
			
			# Update score
			score_label.text = str(game.score)
			if game.score > Settings.get_highscore():
				Settings.set_highscore(game.score)
				best_label.text = str(game.score)
			
			# Check game over
			if game.is_game_over():
				game_over_overlay.visible = true
				SoundManager.play("gameover")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
