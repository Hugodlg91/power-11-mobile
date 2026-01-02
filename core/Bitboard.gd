class_name Bitboard
extends RefCounted

## Bitboard-based 2048 engine for high-performance AI simulation.
##
## Ported from Python to GDScript.
## Represents the 4x4 game board as a single 64-bit integer (int),
## where each tile occupies 4 bits.
##
## Encoding:
## - 4 bits per tile (exponent): 0=empty, 1=2, 2=4, ..., 15=32768
## - Row-major order: bits 0-3 = board[0][0], bits 4-7 = board[0][1], etc.
##
## Note on 64-bit integers in Godot:
## Godot (and GDScript) uses signed 64-bit integers. 
## The 16th tile (index 15) uses bits 60-63.
## Bit 63 is the sign bit. Since standard 2048 tiles don't exceed 32768 (exponent 15),
## we won't strictly overflow into a "meaningless" negative number interpretation 
## that breaks logic, provided we treat the bits as a container.
## Bitwise operations work correctly on the full 64 bits.

# Lookup tables (16-bit row -> result)
# Lookup tables (16-bit row -> result)
# We use generic Array to ensure 64-bit integers are handled correctly without 
# implicit 32-bit truncation during shifts.
static var ROW_LEFT_TABLE: Array = []
static var ROW_RIGHT_TABLE: Array = []
static var SCORE_TABLE: Array = []

# Flag to ensure tables are initialized only once
static var _tables_initialized: bool = false

func _init() -> void:
	if not _tables_initialized:
		__init_tables()

## Initialize lookup tables.
## Can be called manually or automatically by the constructor.
static func __init_tables() -> void:
	if _tables_initialized:
		return
	
	# Resize arrays to 65536 and fill with 0
	ROW_LEFT_TABLE.resize(65536)
	ROW_RIGHT_TABLE.resize(65536)
	SCORE_TABLE.resize(65536)
	
	ROW_LEFT_TABLE.fill(0)
	ROW_RIGHT_TABLE.fill(0)
	SCORE_TABLE.fill(0)
	
	# Pass 1: Compute ROW_LEFT_TABLE and SCORE_TABLE
	for row_val in range(65536):
		# Extract 4 tiles from the 16-bit row
		var tiles: Array[int] = []
		for i in range(4):
			tiles.append((row_val >> (4 * i)) & 0xF)
		
		# Convert to actual values for merging logic
		var actual_values: Array[int] = []
		for t in tiles:
			if t == 0:
				actual_values.append(0)
			else:
				actual_values.append(1 << t)
		
		# Collapse LEFT
		var filtered: Array[int] = []
		for v in actual_values:
			if v != 0:
				filtered.append(v)
		
		var merged: Array[int] = []
		var gained: int = 0
		var idx: int = 0
		
		while idx < filtered.size():
			if idx + 1 < filtered.size() and filtered[idx] == filtered[idx + 1]:
				var new_value: int = filtered[idx] * 2
				merged.append(new_value)
				gained += new_value
				idx += 2
			else:
				merged.append(filtered[idx])
				idx += 1
		
		# Pad with zeros
		while merged.size() < 4:
			merged.append(0)
			
		# Convert back to exponents and encode
		var left_result: int = 0
		for i in range(4):
			var val: int = merged[i]
			if val > 0:
				var exponent: int = _get_exponent(val)
				left_result |= (exponent << (4 * i))
		
		ROW_LEFT_TABLE[row_val] = left_result
		SCORE_TABLE[row_val] = gained

	# Pass 2: Compute ROW_RIGHT_TABLE (Depends on ROW_LEFT_TABLE)
	for row_val in range(65536):
		var tiles: Array[int] = []
		for i in range(4):
			tiles.append((row_val >> (4 * i)) & 0xF)
			
		# Reverse input tiles
		var reversed_row_val: int = 0
		for i in range(4):
			reversed_row_val |= (tiles[3 - i] << (4 * i))
		
		# Safe to lookup now because ROW_LEFT_TABLE is fully populated
		var right_result_reversed: int = ROW_LEFT_TABLE[reversed_row_val]
		
		# Un-reverse result
		var right_result: int = 0
		for i in range(4):
			var tile_val: int = (right_result_reversed >> (4 * i)) & 0xF
			right_result |= (tile_val << (4 * (3 - i)))
			
		ROW_RIGHT_TABLE[row_val] = right_result
		
	_tables_initialized = true

static func _get_exponent(val: int) -> int:
	# val is 2, 4, 8 ...
	# returns 1, 2, 3 ...
	if val == 0: return 0
	# Use bit counting or log
	# built-in log(val) / log(2) is float based.
	# Bit scan reverse is cleaner.
	# In pure GDScript loop is cheap for these small numbers.
	var exponent: int = 0
	while val > 1:
		val >>= 1
		exponent += 1
	return exponent

# ============================================================================
# BITBOARD MOVE OPERATIONS
# ============================================================================

func _transpose(bb: int) -> int:
	# Loop-based transposition (Safe and robust for Godot 64-bit int)
	var result: int = 0
	for r in range(4):
		for c in range(4):
			# Get nibble at (r, c)
			var shift_src = 4 * (r * 4 + c)
			var val = (bb >> shift_src) & 0xF
			
			if val != 0:
				# Place at (c, r)
				var shift_dst = 4 * (c * 4 + r)
				result |= (val << shift_dst)
	return result

## Returns [new_bitboard: int, score_gained: int]
func move_left(bb: int) -> Array:
	if not _tables_initialized:
		__init_tables()
		
	var result: int = 0
	var total_score: int = 0
	
	for row in range(4):
		# Extract 16-bit row
		# (bb >> 48) might sign-extend if bit 63 is set.
		# & 0xFFFF cleans it up.
		var row_val: int = (bb >> (16 * row)) & 0xFFFF
		
		var new_row: int = ROW_LEFT_TABLE[row_val]
		var score: int = SCORE_TABLE[row_val]
		
		result |= (new_row << (16 * row))
		total_score += score
		
	return [result, total_score]

## Returns [new_bitboard: int, score_gained: int]
func move_right(bb: int) -> Array:
	if not _tables_initialized:
		__init_tables()
		
	var result: int = 0
	var total_score: int = 0
	
	for row in range(4):
		var row_val: int = (bb >> (16 * row)) & 0xFFFF
		var new_row: int = ROW_RIGHT_TABLE[row_val]
		
		# Calculate score using left table and reversed row (as in Python logic)
		# But since we have SCORE_TABLE computed for 'row_val' based on Left Move,
		# wait: The score for a right move on a row is the SAME as the score for a left move 
		# on the REVERSED row. A simple lookup is better than re-calculating reversals mid-game.
		# 
		# Optimization: The Python code does:
		# reversed_row_val = ...
		# score = SCORE_TABLE[reversed_row_val]
		# 
		# We should do the same.
		var reversed_tiles_val: int = 0
		for i in range(4):
			# reading nibbles of row_val: 0, 1, 2, 3
			var nibble: int = (row_val >> (4 * i)) & 0xF
			reversed_tiles_val |= (nibble << (4 * (3 - i)))
			
		var score: int = SCORE_TABLE[reversed_tiles_val]
		
		result |= (new_row << (16 * row))
		total_score += score
		
	return [result, total_score]

## Returns [new_bitboard: int, score_gained: int]
func move_up(bb: int) -> Array:
	# Transpose, move left, transpose back
	var transposed: int = _transpose(bb)
	var res: Array = move_left(transposed)
	var moved: int = res[0]
	var score: int = res[1]
	return [_transpose(moved), score]

## Returns [new_bitboard: int, score_gained: int]
func move_down(bb: int) -> Array:
	# Transpose, move right, transpose back
	var transposed: int = _transpose(bb)
	var res: Array = move_right(transposed)
	var moved: int = res[0]
	var score: int = res[1]
	return [_transpose(moved), score]

# ============================================================================
# CONVERSION OPERATIONS
# ============================================================================

func board_to_bitboard(board: Array) -> int:
	# Expects 4x4 array of integers
	var bb: int = 0
	for row in range(4):
		for col in range(4):
			var val: int = board[row][col]
			if val > 0:
				# log2 of val
				var exponent: int = _get_exponent(val)
				bb |= (exponent << (4 * (row * 4 + col)))
	return bb

func bitboard_to_board(bb: int) -> Array:
	var board: Array = []
	for row in range(4):
		var row_arr: Array[int] = []
		for col in range(4):
			var shift: int = 4 * (row * 4 + col)
			var exponent: int = (bb >> shift) & 0xF
			if exponent > 0:
				row_arr.append(1 << exponent)
			else:
				row_arr.append(0)
		board.append(row_arr)
	return board

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func get_empty_positions(bb: int) -> Array[int]:
	# Returns list of indices 0-15
	var empty: Array[int] = []
	for pos in range(16):
		if ((bb >> (4 * pos)) & 0xF) == 0:
			empty.append(pos)
	return empty

func count_empty(bb: int) -> int:
	var count: int = 0
	for pos in range(16):
		if ((bb >> (4 * pos)) & 0xF) == 0:
			count += 1
	return count

func add_tile(bb: int, position: int, exp_value: int) -> int:
	# position 0-15
	return bb | (exp_value << (4 * position))

func is_move_valid(bb: int, direction: String) -> bool:
	var new_bb: int
	if direction == "left":
		new_bb = move_left(bb)[0]
	elif direction == "right":
		new_bb = move_right(bb)[0]
	elif direction == "up":
		new_bb = move_up(bb)[0]
	elif direction == "down":
		new_bb = move_down(bb)[0]
	else:
		push_error("Invalid direction: " + direction)
		return false
	
	return new_bb != bb

func is_game_over(bb: int) -> bool:
	if count_empty(bb) > 0:
		return false
		
	if is_move_valid(bb, "left"): return false
	if is_move_valid(bb, "right"): return false
	if is_move_valid(bb, "up"): return false
	if is_move_valid(bb, "down"): return false
	
	return true

func get_max_tile(bb: int) -> int:
	var max_exp: int = 0
	for pos in range(16):
		var exponent: int = (bb >> (4 * pos)) & 0xF
		if exponent > max_exp:
			max_exp = exponent
	
	if max_exp == 0:
		return 0
	return 1 << max_exp
