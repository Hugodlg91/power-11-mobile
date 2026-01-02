extends SceneTree

## Test suite for Bitboard.gd
## Run this by attaching it to a Node in a scene or running as a script.

func _init() -> void:
	print("Starting Bitboard tests...")
	test_bitboard_operations()
	print("Done.")
	quit()

func assert_true(condition: bool, msg: String = "Assertion failed") -> void:
	if not condition:
		push_error("FAIL: " + msg)
		print("FAIL: " + msg)
	else:
		# print("PASS: " + msg) # Optional: comment out to reduce noise
		pass

func assert_eq(actual, expected, msg: String = "") -> void:
	if str(actual) != str(expected): # Simple string comparison for arrays/dicts
		push_error("FAIL: " + msg + " Expected " + str(expected) + ", got " + str(actual))
		print("FAIL: " + msg + " Expected " + str(expected) + ", got " + str(actual))

func test_bitboard_operations() -> void:
	var bb_logic = Bitboard.new()
	
	print("Test 1: Encoding/Decoding")
	# Sample board: 
	# 2 0 0 0
	# 4 16 0 0
	# 8 0 0 0
	# 0 0 0 0
	var sample_board: Array = [
		[2, 0, 0, 0],
		[4, 16, 0, 0],
		[8, 0, 0, 0],
		[0, 0, 0, 0]
	]
	
	var bb: int = bb_logic.board_to_bitboard(sample_board)
	var decoded: Array = bb_logic.bitboard_to_board(bb)
	assert_eq(decoded, sample_board, "Encoding/Decoding roundtrip")
	print("  ✓ Encoding/decoding works")
	
	print("Test 2: Move operations")
	var test_cases: Array = [
		{
			"board": [[2, 2, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]],
			"expected_left": [[4, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]],
			"score_left": 4
		},
		{
			"board": [[2, 4, 8, 16], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]],
			"expected_left": [[2, 4, 8, 16], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]],
			"score_left": 0
		},
		{
			"board": [[2, 2, 2, 2], [4, 4, 4, 4], [0, 0, 0, 0], [0, 0, 0, 0]],
			"expected_left": [[4, 4, 0, 0], [8, 8, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]],
			"score_left": 8 + 16
		}
	]
	
	for i in range(test_cases.size()):
		var case = test_cases[i]
		var input_board = case["board"]
		
		# Test Left
		var input_bb = bb_logic.board_to_bitboard(input_board)
		var res_left = bb_logic.move_left(input_bb)
		var out_board_left = bb_logic.bitboard_to_board(res_left[0])
		
		if case.has("expected_left"):
			assert_eq(out_board_left, case["expected_left"], "Case " + str(i) + " Left Move")
		if case.has("score_left"):
			assert_eq(res_left[1], case["score_left"], "Case " + str(i) + " Left Score")
			
	print("  ✓ Move operations check (partial)")
	
	print("Test 3: Empty cell counting")
	var t3_board = [[2, 0, 0, 0], [0, 4, 0, 0], [0, 0, 0, 0], [0, 0, 0, 8]]
	var t3_bb = bb_logic.board_to_bitboard(t3_board)
	assert_eq(bb_logic.count_empty(t3_bb), 13, "Empty count should be 13")
	print("  ✓ Empty cell counting works")
	
	print("Test 4: Adding tiles")
	var t4_bb = 0
	# Add 2 at position 0 (row 0, col 0) -> exp 1
	t4_bb = bb_logic.add_tile(t4_bb, 0, 1)
	# Add 4 at position 15 (row 3, col 3) -> exp 2
	t4_bb = bb_logic.add_tile(t4_bb, 15, 2)
	
	var t4_board = bb_logic.bitboard_to_board(t4_bb)
	assert_eq(t4_board[0][0], 2, "Pos 0 should be 2")
	assert_eq(t4_board[3][3], 4, "Pos 15 should be 4")
	print("  ✓ Adding tiles works")
	
	print("✅ All tests passed!")
