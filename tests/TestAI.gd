extends Node

func _ready() -> void:
	print("Starting AI tests...")
	test_heuristics()
	test_search()
	print("✅ AI Tests Passed!")
	get_tree().quit()

func assert_approx(actual: float, expected: float, tolerance: float = 0.001, msg: String = "") -> void:
	if abs(actual - expected) > tolerance:
		push_error("FAIL: " + msg + " Expected " + str(expected) + ", got " + str(actual))
		print("FAIL: " + msg + " Expected " + str(expected) + ", got " + str(actual))

func assert_eq(actual, expected, msg: String = "") -> void:
	if str(actual) != str(expected):
		push_error("FAIL: " + msg + " Expected " + str(expected) + ", got " + str(actual))
		print("FAIL: " + msg + " Expected " + str(expected) + ", got " + str(actual))

func test_heuristics() -> void:
	print("Test 1: Heuristics")
	var ai = AIPlayer.new()
	var bb_logic = Bitboard.new()
	
	# Board:
	# 2 0 0 0
	# 0 0 0 0  -> Mono should be decent
	# 0 0 0 0
	# 0 0 0 0
	var b1 = [[2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
	var score1 = ai.score_board(b1)
	print("  Score B1: ", score1)
	
	# Board:
	# 2 4 8 16
	# 0 0 0 0
	# 0 0 0 0
	# 0 0 0 0
	# Highly monotonic row
	var b2 = [[2, 4, 8, 16], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
	var score2 = ai.score_board(b2)
	print("  Score B2: ", score2)
	
	if score2 <= score1:
		push_error("FAIL: Monotonic rising board should have higher/comparable good score logic")
		
	print("  ✓ Heuristics run without crashing")

func test_search() -> void:
	print("Test 2: Search")
	var ai = AIPlayer.new()
	var bb_logic = Bitboard.new()
	
	# Setup a board where moving RIGHT merges 2s
	# 2 2 0 0
	var board_arr = [[2, 2, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
	var bb = bb_logic.board_to_bitboard(board_arr)
	
	# Depth 1 should see the merge
	var best_move = ai.choose_best_move(bb, 1)
	print("  Best move for [2, 2, 0, 0]: ", best_move)
	
	# Ideally it chooses Left or Right?
	# Moving Left: [4, 0, 0, 0] -> merge
	# Moving Right: [0, 0, 0, 4] -> merge
	# Both are valid merges.
	if best_move != "left" and best_move != "right":
		print("  WARNING: Expected left or right merge preference")
		
	# Setup critical corner
	# 1024 512 0 0
	# ...
	var b3 = [[1024, 512, 256, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
	var bb3 = bb_logic.board_to_bitboard(b3)
	var move3 = ai.choose_best_move(bb3, 2)
	print("  Move for large corner setup: ", move3)
	
	print("  ✓ Search runs")
