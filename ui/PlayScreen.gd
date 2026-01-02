extends Control

# NODES
@onready var game_board: Control = $BoardContainer
@onready var score_label: Label = $Header/ScoreBox/Value
@onready var best_label: Label = $Header/BestBox/Value
@onready var game_over_overlay: Control = $GameOverOverlay

# BUTTONS
@onready var btn_back: Button = $BtnBack
@onready var btn_reset: Button = $BtnReset

# GAME STATE
var game: Game2048
var ai_player: AIPlayer
var leaderboard: LeaderboardManager

func _ready() -> void:
	game = Game2048.new()
	
	# Connect Buttons
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(reset_game)
	
	# Layout
	# game_board is a CenterContainer or Control, we need to pass size?
	# GameBoard calculates size from its rect.
	game_board.setup(game_board.size.x, 15)
	
	spawn_initial_board()
	update_score_display()
	
	game_over_overlay.visible = false
	
	# Initial Highscore
	best_label.text = str(Settings.get_highscore())
	
	# Apply Theme
	game_board.update_theme(Settings.get_theme_name())

	# Optional: AI
	ai_player = AIPlayer.new()
	
	# Optional: Leaderboard (add to tree to enable processing)
	var LBClass = load("res://core/LeaderboardManager.gd")
	leaderboard = LBClass.new()
	add_child(leaderboard)

func _process(_delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if game_board.is_animating: return
	if game.is_game_over(): return
	
	var moved: bool = false
	var direction: String = ""
	
	if event.is_action_pressed("ui_left"):
		direction = "left"
	elif event.is_action_pressed("ui_right"):
		direction = "right"
	elif event.is_action_pressed("ui_up"):
		direction = "up"
	elif event.is_action_pressed("ui_down"):
		direction = "down"
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		reset_game()
		return
	
	# AI Debug Key 'A'
	if event is InputEventKey and event.pressed and event.keycode == KEY_A:
		run_ai_move()
		return
		
	if direction != "":
		# 1. Capture Old State (Deep Copy)
		var old_board: Array = game.get_board_array_copy()
		
		# 2. Logic Move
		moved = game.move(direction)
		
		# 3. Animate if moved
		if moved:
			var new_board: Array = game.get_board_array() # Current state
			game_board.animate_transition(old_board, new_board, direction)
			update_score_display()
			SoundManager.play("move")
			
			if game.score > Settings.get_highscore():
				Settings.set_highscore(game.score)
				best_label.text = str(game.score)
			
			if game.is_game_over():
				show_game_over()

func run_ai_move() -> void:
	if game_board.is_animating or game.is_game_over(): return
	var best_move = ai_player.choose_best_move(game.current_board_state)
	if best_move != null:
		var old_board = game.get_board_array_copy()
		if game.move(best_move):
			game_board.animate_transition(old_board, game.get_board_array(), best_move)
			update_score_display()
			SoundManager.play("move")

func reset_game() -> void:
	game.reset()
	game_over_overlay.visible = false
	
	spawn_initial_board()
	update_score_display()

func spawn_initial_board() -> void:
	game_board.spawn_board(game.get_board_array())

func update_score_display() -> void:
	score_label.text = str(game.score)

func show_game_over() -> void:
	game_over_overlay.visible = true
	SoundManager.play("gameover")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
