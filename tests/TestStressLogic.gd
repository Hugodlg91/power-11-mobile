extends SceneTree

func _init():
	print("Starting Logic Stress Test (1000 random moves)...")
	var game = preload("res://core/Game2048.gd").new()
	game.reset()
	
	var moves = ["up", "down", "left", "right"]
	var total_moves = 0
	
	for i in range(1000):
		var dir = moves.pick_random()
		var old_board = game.get_board_array_copy()
		var moved = game.move(dir)
		
		# Sanity checks
		var new_board = game.get_board_array_copy()
		
		if moved:
			total_moves += 1
			# If moved, boards MUST be different
			if boards_equal(old_board, new_board):
				printerr("CRITICAL: Moved=true but boards are identical!")
				print("Direction: ", dir)
				print("Final BB: %x" % game.current_board_state)
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
				print("Old Array:")
				print_board(old_board)
				print("New Array:")
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
