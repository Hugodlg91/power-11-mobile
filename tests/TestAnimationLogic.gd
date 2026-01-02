extends SceneTree

func _init():
	print("Starting Animation Logic Verification...")
	test_simple_spawn()
	test_simple_move()
	test_merge()
	test_move_and_spawn()
	test_multi_merge()
	print("All tests passed!")
	quit()

func assert_true(condition: bool, msg: String):
	if not condition:
		printerr("FAILED: " + msg)
		quit(1)
	else:
		print("PASSED: " + msg)

# Mocking the logic from GameBoard.gd for testing purposes
# We replicate the exact algorithm to test it in isolation
func get_animations(old_board, new_board, direction):
	var size = 4
	var animations = []
	var spawn_animations = []
	
	var old_tiles_used = {}
	var new_tiles_used = {}
	for r in range(size):
		for c in range(size):
			old_tiles_used[Vector2i(r, c)] = false
			new_tiles_used[Vector2i(r, c)] = false
			
	if direction in ["left", "right"]:
		for row in range(size):
			var old_positions = []
			var new_positions = []
			var range_cols = range(size) if direction == "left" else range(size - 1, -1, -1)
			
			for c in range_cols:
				if old_board[row][c] != 0: old_positions.append(Vector2i(row, c))
				if new_board[row][c] != 0: new_positions.append(Vector2i(row, c))
			
			var old_idx = 0
			var new_idx = 0
			
			while new_idx < new_positions.size():
				if old_idx >= old_positions.size():
					break
				
				var new_pos = new_positions[new_idx]
				var old_pos = old_positions[old_idx]
				var new_val = new_board[new_pos.x][new_pos.y]
				var old_val = old_board[old_pos.x][old_pos.y]
				
				if old_idx + 1 < old_positions.size():
					var next_old_pos = old_positions[old_idx + 1]
					var next_old_val = old_board[next_old_pos.x][next_old_pos.y]
					if old_val == next_old_val and old_val * 2 == new_val:
						animations.append({"type": "merge", "from": old_pos, "to": new_pos, "val": old_val})
						animations.append({"type": "merge", "from": next_old_pos, "to": new_pos, "val": next_old_val})
						old_tiles_used[old_pos] = true
						old_tiles_used[next_old_pos] = true
						new_tiles_used[new_pos] = true
						old_idx += 2
						new_idx += 1
						continue
				
				animations.append({"type": "move", "from": old_pos, "to": new_pos, "val": old_val})
				old_tiles_used[old_pos] = true
				new_tiles_used[new_pos] = true
				old_idx += 1
				new_idx += 1

	else: # up / down
		for col in range(size):
			var old_positions = []
			var new_positions = []
			var range_rows = range(size) if direction == "up" else range(size - 1, -1, -1)
			
			for r in range_rows:
				if old_board[r][col] != 0: old_positions.append(Vector2i(r, col))
				if new_board[r][col] != 0: new_positions.append(Vector2i(r, col))
				
			var old_idx = 0
			var new_idx = 0
			
			while new_idx < new_positions.size():
				if old_idx >= old_positions.size():
					break
				
				var new_pos = new_positions[new_idx]
				var old_pos = old_positions[old_idx]
				var new_val = new_board[new_pos.x][new_pos.y]
				var old_val = old_board[old_pos.x][old_pos.y]
				
				if old_idx + 1 < old_positions.size():
					var next_old_pos = old_positions[old_idx + 1]
					var next_old_val = old_board[next_old_pos.x][next_old_pos.y]
					if old_val == next_old_val and old_val * 2 == new_val:
						animations.append({"type": "merge", "from": old_pos, "to": new_pos, "val": old_val})
						animations.append({"type": "merge", "from": next_old_pos, "to": new_pos, "val": next_old_val})
						old_tiles_used[old_pos] = true
						old_tiles_used[next_old_pos] = true
						new_tiles_used[new_pos] = true
						old_idx += 2
						new_idx += 1
						continue
				
				animations.append({"type": "move", "from": old_pos, "to": new_pos, "val": old_val})
				old_tiles_used[old_pos] = true
				new_tiles_used[new_pos] = true
				old_idx += 1
				new_idx += 1

	for r in range(size):
		for c in range(size):
			if new_board[r][c] != 0 and not new_tiles_used[Vector2i(r, c)]:
				spawn_animations.append({"pos": Vector2i(r, c), "val": new_board[r][c]})
				
	return {"anims": animations, "spawns": spawn_animations}

func create_empty_board():
	var b = []
	for r in range(4):
		var row = []
		for c in range(4): row.append(0)
		b.append(row)
	return b

func test_simple_spawn():
	print("Test: Simple Spawn (Start Game)")
	var old_b = create_empty_board()
	var new_b = create_empty_board()
	new_b[0][0] = 2
	
	var res = get_animations(old_b, new_b, "left")
	assert_true(res.spawns.size() == 1, "Should identify 1 spawn")
	assert_true(res.spawns[0].pos == Vector2i(0,0), "Spawn at (0,0)")
	assert_true(res.anims.size() == 0, "No moves")

func test_simple_move():
	print("Test: Simple Move (Left)")
	var old_b = create_empty_board()
	old_b[0][2] = 2
	
	var new_b = create_empty_board()
	new_b[0][0] = 2 # Moved to left
	
	var res = get_animations(old_b, new_b, "left")
	assert_true(res.anims.size() == 1, "Should identify 1 move")
	assert_true(res.anims[0].from == Vector2i(0,2), "From (0,2)")
	assert_true(res.anims[0].to == Vector2i(0,0), "To (0,0)")
	assert_true(res.spawns.size() == 0, "No spawns")

func test_merge():
	print("Test: Merge (Down)")
	var old_b = create_empty_board()
	old_b[0][0] = 2
	old_b[1][0] = 2
	
	var new_b = create_empty_board()
	new_b[3][0] = 4 # Merged at bottom
	
	var res = get_animations(old_b, new_b, "down")
	assert_true(res.anims.size() == 2, "Should identify 2 merge parts")
	assert_true(res.anims[0].type == "merge", "Is merge")
	assert_true(res.anims[0].to == Vector2i(3,0), "Target (3,0)")
	assert_true(res.spawns.size() == 0, "No spawns")

func test_move_and_spawn():
	print("Test: Move + Spawn")
	var old_b = create_empty_board()
	old_b[0][0] = 2
	
	var new_b = create_empty_board()
	new_b[0][0] = 2 # Stayed put (e.g. move left but already at left)
	new_b[0][1] = 2 # New spawn
	
	var res = get_animations(old_b, new_b, "left")
	assert_true(res.anims.size() == 1, "Should identify 1 move (stationary)")
	assert_true(res.anims[0].from == Vector2i(0,0), "From (0,0)")
	assert_true(res.anims[0].to == Vector2i(0,0), "To (0,0)")
	
	assert_true(res.spawns.size() == 1, "Should identify 1 spawn")
	assert_true(res.spawns[0].pos == Vector2i(0,1), "Spawn at (0,1)")

func test_multi_merge():
	print("Test: Multi Merge Row")
	# [2, 2, 4, 4] -> Left -> [4, 8, 0, 0]
	var old_b = create_empty_board()
	old_b[0] = [2, 2, 4, 4]
	
	var new_b = create_empty_board()
	new_b[0] = [4, 8, 0, 0]
	
	var res = get_animations(old_b, new_b, "left")
	
	# First merge (2+2->4 at 0,0)
	# Second merge (4+4->8 at 0,1)
	assert_true(res.anims.size() == 4, "Should have 4 merge animations (2 pairs)")
	assert_true(res.anims[0].from == Vector2i(0,0), "First: 0,0")
	assert_true(res.anims[0].to == Vector2i(0,0), "First Target: 0,0")
	
	assert_true(res.anims[2].from == Vector2i(0,2), "Second Pair First: 0,2")
	assert_true(res.anims[2].to == Vector2i(0,1), "Second Pair Target: 0,1")
	
	assert_true(res.spawns.size() == 0, "No spawns")
