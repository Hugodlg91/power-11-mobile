extends Control

# NODES
@onready var game_board: Control = $GameBoard
@onready var score_label: Label = $Header/ScoreBox/Value
@onready var best_label: Label = $Header/BestBox/Value
@onready var game_over_overlay: Control = $GameOverOverlay
@onready var bg: ColorRect = $ColorRect

# BUTTONS
@onready var btn_back: Button = $BtnBack
@onready var btn_reset: Button = $BtnReset

# OVERLAY NODES
@onready var ov_score: Label = $GameOverOverlay/Content/FinalScore
@onready var ov_input: LineEdit = $GameOverOverlay/Content/InputContainer/NameInput
@onready var ov_submit: Button = $GameOverOverlay/Content/InputContainer/SubmitBtn
@onready var ov_status: Label = $GameOverOverlay/Content/InputContainer/StatusLabel
@onready var ov_restart: Button = $GameOverOverlay/Content/NavButtons/BtnRestart
@onready var ov_menu: Button = $GameOverOverlay/Content/NavButtons/BtnMenu

# LOGIC
var leaderboard_mgr: LeaderboardManager

# GAME STATE
var game: Game2048
var ai_player: AIPlayer # For debug
var old_board_state: Array = [] # For animation - saved BEFORE move

func _ready() -> void:
	game = Game2048.new()
	ai_player = AIPlayer.new()
	
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(reset_game)
	
	# Connect Overlay
	ov_submit.pressed.connect(_on_submit_score)
	ov_restart.pressed.connect(reset_game)
	ov_menu.pressed.connect(_on_back_pressed)
	
	# Instantiate Leaderboard Manager
	var DBClass = load("res://core/LeaderboardManager.gd")
	if DBClass:
		leaderboard_mgr = DBClass.new()
		add_child(leaderboard_mgr)
	
	# Setup GameBoard (matching VersusScreen approach)
	var board_size = 400.0  # Adjust based on your UI
	var margin = 10
	game_board.setup(board_size, margin)
	game_board.setup(board_size, margin)
	
	# Initial appearance
	_update_background()
	game_board.update_theme(Settings.get_setting("theme", "Classic"))
	
	# Listen for changes
	Settings.connect("theme_changed", _on_theme_changed)
	
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
				ov_score.text = "Final Score: " + str(game.score)
				ov_status.text = ""
				ov_input.text = ""
				ov_submit.disabled = false
				ov_input.editable = true
				
				SoundManager.play("gameover")

func _on_theme_changed(new_theme: String) -> void:
	_update_background()
	game_board.update_theme(new_theme)

func _update_background() -> void:
	var theme_name = Settings.get_theme_name()
	var theme_colors = UIAssets.get_theme_colors(theme_name)
	bg.color = theme_colors["bg"]
	
	# Update Score Text Colors
	var txt_color = theme_colors["text_dark"]
	if theme_name in ["Dark", "Cyberpunk", "Neon"]: # For dark themes, use light text
		txt_color = theme_colors["text_light"]
		if theme_name == "Cyberpunk": txt_color = Color.WHITE
		
	# Labels
	score_label.add_theme_color_override("font_color", txt_color)
	best_label.add_theme_color_override("font_color", txt_color)
	
	# Also update titles "SCORE" and "BEST" if possible, but they are not in variables.
	# We can get them via parent.
	var score_title = score_label.get_parent().get_node("Label")
	var best_title = best_label.get_parent().get_node("Label")
	if score_title: score_title.add_theme_color_override("font_color", txt_color)
	if best_title: best_title.add_theme_color_override("font_color", txt_color)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")

func _on_submit_score() -> void:
	if not leaderboard_mgr:
		ov_status.text = "Error: System faulty"
		return
		
	var p_name = ov_input.text.strip_edges()
	if p_name.length() < 3:
		ov_status.text = "Name too short (3-12 chars)"
		ov_status.add_theme_color_override("font_color", Color.RED)
		return
		
	ov_status.text = "Submitting..."
	ov_status.add_theme_color_override("font_color", Color.YELLOW)
	ov_submit.disabled = true
	ov_input.editable = false
	
	var success = await leaderboard_mgr.submit_score(p_name, game.score)
	
	if success:
		ov_status.text = "Score Saved Successfully!"
		ov_status.add_theme_color_override("font_color", Color.GREEN)
	else:
		ov_status.text = "Submission Failed. Try again."
		ov_status.add_theme_color_override("font_color", Color.RED)
		ov_submit.disabled = false
		ov_input.editable = true
