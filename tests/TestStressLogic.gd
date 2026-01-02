extends SceneTree

func _init():
	print("Starting Logic Stress Test (1000 moves)...")
	var game = preload("res://core/Game2048.gd").new()
	# We need to mock the scene tree connection or avoid it.
	# Game2048 doesn't use SceneTree directly except for maybe signals?
	# It extends Node.
	
	game.reset()
	
	print("Initial Board State (Hex): %x" % game.current_board_state)
	print("Initial Board Array:")
	print_board(game.get_board_array_copy())
	
	var moves = ["up", "down", "left", "right"]
	var total_moves = 0
	
	for i in range(1000):
		var dir = moves.pick_random()
		
		# Trace states
		var old_board = game.get_board_array_copy()
		var pre_move_bb = game.current_board_state
		
		var dir_res_bb = 0
		if dir == "left": dir_res_bb = game.bitboard.move_left(pre_move_bb)[0]
		elif dir == "right": dir_res_bb = game.bitboard.move_right(pre_move_bb)[0]
		elif dir == "up": dir_res_bb = game.bitboard.move_up(pre_move_bb)[0]
		elif dir == "down": dir_res_bb = game.bitboard.move_down(pre_move_bb)[0]
		
		# Now actually run game logic
		var moved = game.move(dir)
		var post_move_bb = game.current_board_state
		var new_board = game.get_board_array_copy()
		
		if moved:
			# If moved, boards MUST be different
			if boards_equal(old_board, new_board):
				printerr("CRITICAL: Moved=true but boards are identical!")
				print("Direction: ", dir)
				print("Pre-Move BB:  %x" % pre_move_bb)
				print("Move Result BB: %x" % dir_res_bb)
				print("Final BB (w/Spawn): %x" % post_move_bb)
				
				# Sanity check: did move result actually change?
				if pre_move_bb == dir_res_bb:
					print("WTF: Pre-Move == Move Result, yet game.move() returned true?!")
				
				# Check if spawn happened
				if dir_res_bb == post_move_bb:
					print("WTF: Move Result == Final BB. No spawn added?!")
					
				print("Old Array:")
				print_board(old_board)
				print("New Array:")
				print_board(new_board)
				quit(1)
		else:
			# If not moved, boards MUST be identical
			if not boards_equal(old_board, new_board):
				printerr("CRITICAL: Moved=false but boards changed!")
				print("Direction: ", dir)
				print("Pre-Move BB:  %x" % pre_move_bb)
				print("Final BB:     %x" % post_move_bb)
				print_board(old_board)
				print("vs")
				print_board(new_board)
				quit(1)
	
	print("Stress Test Passed. Total successful moves: ", total_moves)
	quit()

func boards_equal(b1, b2):
	for r in range(4):
		for c in range(4):
			if b1[r][c] != b2[r][c]: return false
	return true

func print_board(b):
	for r in b:
		print(r)
