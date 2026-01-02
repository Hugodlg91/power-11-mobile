extends SceneTree

func _init():
	print("Testing Bitboard Logic...")
	
	var bb = Bitboard.new()
	
	# Test 1: Single tile at (0, 3) (Top-Right)
	# Board:
	# 0 0 0 2
	# 0 0 0 0
	# ...
	var board_arr = create_empty_board()
	board_arr[0][3] = 2
	var bb_val = bb.board_to_bitboard(board_arr)
	
	print("Initial Board:")
	print_board(board_arr)
	
	# Move UP
	var res = bb.move_up(bb_val)
	var new_bb = res[0]
	var new_board = bb.bitboard_to_board(new_bb)
	
	print("After Move UP:")
	print_board(new_board)
	
	# Should stay at (0, 3)
	if new_board[0][3] == 2 and new_board[0][1] == 0:
		print("PASSED: Tile stayed in column 3")
	else:
		print("FAILED: Tile moved! Check logs.")
		if new_board[0][1] != 0:
			print("CRITICAL: Tile jumped to column 1!")

	# Test 2: Full Transpose Check
	# 0 1 2 3
	# 4 5 6 7
	# ...
	# Transpose -> 
	# 0 4 8 12
	# 1 5 9 13
	
	quit()

func create_empty_board():
	var b = []
	for r in range(4):
		var row = []
		for c in range(4): row.append(0)
		b.append(row)
	return b

func print_board(b):
	for r in b:
		print(r)
