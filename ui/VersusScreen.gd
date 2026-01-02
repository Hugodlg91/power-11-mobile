extends Control

# NODES
@onready var p_board: Control = $GameArea/LeftSide/Board
@onready var a_board: Control = $GameArea/RightSide/Board
@onready var p_score: Label = $GameArea/LeftSide/Score
@onready var a_score: Label = $GameArea/RightSide/Score
@onready var ai_label: Label = $GameArea/RightSide/Label
@onready var timer_label: Label = $TimerLabel

@onready var menu_overlay: Control = $MenuOverlay
@onready var diff_menu: Control = $MenuOverlay/DifficultyMenu
@onready var mode_menu: Control = $MenuOverlay/ModeMenu
@onready var game_over_menu: Control = $MenuOverlay/GameOverMenu
@onready var win_label: Label = $MenuOverlay/GameOverMenu/WinLabel
@onready var reason_label: Label = $MenuOverlay/GameOverMenu/ReasonLabel

# GAMES
var game_p: Game2048
var game_a: Game2048
var ai_player: AIPlayer

# STATE
enum State { SELECT_DIFFICULTY, SELECT_MODE, PLAYING, GAME_OVER }
var current_state = State.SELECT_DIFFICULTY
var difficulty: String = "Medium"
var ai_delay: float = 1.0
var ai_depth: int = 2
var game_mode: String = "RACE"
var time_limit: int = 180 # 3 mins
var remaining_time: float = 0.0

# THREADING
var ai_thread: Thread
var ai_semaphore: Semaphore # Not needed if standard thread flow
var ai_mutex: Mutex
var ai_move_pending = null
var is_ai_thinking: bool = false
var last_ai_move_time: float = 0.0

func _ready() -> void:
	game_p = Game2048.new()
	game_a = Game2048.new()
	ai_player = AIPlayer.new()
	
	p_board.setup(400, 10)
	a_board.setup(400, 10)
	p_board.update_theme("Classic") # Force classic for now or Settings.get_theme()
	a_board.update_theme("Classic")
	
	_setup_menus()
	_show_menu(diff_menu)
	
	ai_thread = Thread.new()
	ai_mutex = Mutex.new()

func _exit_tree() -> void:
	if ai_thread.is_started():
		ai_thread.wait_to_finish()

func _setup_menus() -> void:
	# Difficulty
	$MenuOverlay/DifficultyMenu/BtnEasy.pressed.connect(func(): _set_difficulty("Easy", 1.5, 1))
	$MenuOverlay/DifficultyMenu/BtnMedium.pressed.connect(func(): _set_difficulty("Medium", 1.0, 2))
	$MenuOverlay/DifficultyMenu/BtnHard.pressed.connect(func(): _set_difficulty("Hard", 0.75, 3))
	$MenuOverlay/DifficultyMenu/BtnDemon.pressed.connect(func(): _set_difficulty("Demon", 0.5, 4))
	
	# Mode
	$MenuOverlay/ModeMenu/BtnRace.pressed.connect(func(): _set_mode("RACE"))
	$MenuOverlay/ModeMenu/BtnTime.pressed.connect(func(): _set_mode("TIME"))
	
	# Game Over
	$MenuOverlay/GameOverMenu/BtnAgain.pressed.connect(_reset_selection)
	$MenuOverlay/GameOverMenu/BtnQuit.pressed.connect(_on_back_pressed)
	
	# Back
	$BtnBack.pressed.connect(_on_back_pressed)

func _set_difficulty(diff: String, delay: float, depth: int) -> void:
	difficulty = diff
	ai_delay = delay
	ai_depth = depth
	ai_label.text = "AI " + diff.to_upper()
	_show_menu(mode_menu)
	current_state = State.SELECT_MODE

func _set_mode(mode: String) -> void:
	game_mode = mode
	_start_game()

func _start_game() -> void:
	game_p.reset()
	game_a.reset()
	
	p_board.spawn_board(game_p.get_board_array())
	a_board.spawn_board(game_a.get_board_array())
	
	p_score.text = "SCORE: 0"
	a_score.text = "SCORE: 0"
	
	menu_overlay.visible = false
	current_state = State.PLAYING
	
	if game_mode == "TIME":
		time_limit = 180
		remaining_time = time_limit
		timer_label.text = "%02d:%02d" % [time_limit / 60, time_limit % 60]
	else:
		timer_label.text = "RACE TO 2048"
		
	last_ai_move_time = Time.get_ticks_msec() / 1000.0

func _reset_selection() -> void:
	current_state = State.SELECT_DIFFICULTY
	menu_overlay.visible = true
	_show_menu(diff_menu)

func _show_menu(menu: Control) -> void:
	diff_menu.visible = false
	mode_menu.visible = false
	game_over_menu.visible = false
	menu.visible = true

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")

func _process(delta: float) -> void:
	if current_state != State.PLAYING: return
	
	# 1. Timer
	if game_mode == "TIME":
		remaining_time -= delta
		if remaining_time <= 0:
			remaining_time = 0
			_resolve_time_attack()
		
		var m = int(remaining_time) / 60
		var s = int(remaining_time) % 60
		timer_label.text = "%02d:%02d" % [m, s]
		if remaining_time < 10:
			timer_label.modulate = Color.RED
		else:
			timer_label.modulate = Color.WHITE
			
	# 2. Check Input (Player)
	# Handled in _input but checked against state
	
	# 3. AI Logic
	_process_ai()
	
func _input(event: InputEvent) -> void:
	if current_state != State.PLAYING: return
	if p_board.is_animating: return
	
	var dir = ""
	if event.is_action_pressed("ui_left"): dir = "left"
	elif event.is_action_pressed("ui_right"): dir = "right"
	elif event.is_action_pressed("ui_up"): dir = "up"
	elif event.is_action_pressed("ui_down"): dir = "down"
	
	if dir != "":
		var old = game_p.get_board_array_copy()
		if game_p.move(dir):
			p_board.animate_transition(old, game_p.get_board_array(), dir)
			p_score.text = "SCORE: " + str(game_p.score)
			SoundManager.play("move")
			_check_win_condition_after_move()

func _process_ai() -> void:
	# Apply pending move
	ai_mutex.lock()
	if ai_move_pending != null:
		var move = ai_move_pending
		ai_move_pending = null
		ai_mutex.unlock()
		
		if ai_thread.is_started():
			ai_thread.wait_to_finish()
			
		var old = game_a.get_board_array_copy()
		if game_a.move(move):
			a_board.animate_transition(old, game_a.get_board_array(), move)
			a_score.text = "SCORE: " + str(game_a.score)
			_check_win_condition_after_move()
		
		last_ai_move_time = Time.get_ticks_msec() / 1000.0
		is_ai_thinking = false
		return
	else:
		ai_mutex.unlock()
		
	# Start new think if needed
	if is_ai_thinking: return
	if a_board.is_animating: return
	
	var time_now = Time.get_ticks_msec() / 1000.0
	if time_now - last_ai_move_time >= ai_delay:
		is_ai_thinking = true
		ai_thread.start(_ai_think_task.bind(game_a.current_board_state, ai_depth))


func _ai_think_task(board_val: int, depth: int) -> void:
	# This runs on thread
	var move = ai_player.choose_best_move(board_val, depth)
	
	ai_mutex.lock()
	ai_move_pending = move
	ai_mutex.unlock()

func _check_win_condition_after_move() -> void:
	# 1. Check Race
	if game_mode == "RACE":
		if game_p.has_won():
			_end_game("player", "Reached 2048!")
		elif game_a.has_won():
			_end_game("ai", "Reached 2048!")
		elif game_p.is_game_over():
			_end_game("ai", "Opponent Eliminated!")
		elif game_a.is_game_over():
			_end_game("player", "Opponent Eliminated!")
			
	# 2. Check KO in Time Attack
	elif game_mode == "TIME":
		if game_p.is_game_over():
			_end_game("ai", "Knockout!")
		elif game_a.is_game_over():
			_end_game("player", "Knockout!")

func _resolve_time_attack() -> void:
	if game_p.score > game_a.score:
		_end_game("player", "Time's Up - Higher Score!")
	elif game_a.score > game_p.score:
		_end_game("ai", "Time's Up - Higher Score!")
	else:
		_end_game("tie", "Draw!")

func _end_game(winner: String, reason: String) -> void:
	current_state = State.GAME_OVER
	menu_overlay.visible = true
	_show_menu(game_over_menu)
	
	if winner == "player":
		win_label.text = "YOU WIN!"
		win_label.modulate = Color(0.2, 0.8, 0.2)
		SoundManager.play("merge") # Win sound?
	elif winner == "ai":
		win_label.text = "AI WINS!"
		win_label.modulate = Color(0.8, 0.2, 0.2)
		SoundManager.play("gameover")
	else:
		win_label.text = "DRAW!"
		win_label.modulate = Color.YELLOW
		
	reason_label.text = reason
