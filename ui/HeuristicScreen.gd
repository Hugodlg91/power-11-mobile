extends Control

@onready var game_board: Control = $GameBoard
@onready var score_label: Label = $ScoreBox/Value
@onready var best_label: Label = $BestBox/Value

var game: Game2048
var ai_player: AIPlayer
var speed: float = 0.2
var timer: float = 0.0

func _ready() -> void:
	game = Game2048.new()
	ai_player = AIPlayer.new()
	
	game_board.setup(500, 15)
	
	game.reset()
	game_board.spawn_board(game.get_board_array())
	
	best_label.text = str(Settings.get_highscore())
	
func _process(delta: float) -> void:
	if $BackButton.button_pressed:
		get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
		return
		
	if game_board.is_animating: return
	if game.is_game_over(): return
	
	timer += delta
	if timer >= speed:
		timer = 0.0
		_play_ai_move()

func _play_ai_move() -> void:
	# Heuristic (Greedy) or Expectimax?
	# heuristic_screen.py imports choose_best_move (Greedy/Heuristic).
	# expectimax_choose_move is different.
	# Let's use Expectimax (depth 2) for better show.
	
	var move = ai_player.choose_best_move(game.current_board_state, 2)
	if move:
		var old = game.get_board_array_copy()
		if game.move(move):
			game_board.animate_transition(old, game.get_board_array(), move)
			score_label.text = str(game.score)
			
			if game.score > Settings.get_highscore():
				Settings.set_highscore(game.score)
				best_label.text = str(game.score)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
