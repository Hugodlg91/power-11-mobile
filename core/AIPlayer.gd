class_name AIPlayer
extends RefCounted

## AI player for 2048 using Expectimax algorithm.
## Ported from core/ai_player.py

var bitboard_logic: Bitboard

# Transposition table for caching evaluated states
# Key: int (bitboard), Value: float (score)
var _transposition_table: Dictionary = {}

func _init() -> void:
	bitboard_logic = Bitboard.new()

func _log2(v: int) -> float:
	if v <= 0: return 0.0
	# Since v is a power of 2, we can just find the bit index.
	# But for float return to match Python math.log2:
	# Iterate or use built-in.
	# Fast way for power-of-2 integer:
	var exponent: int = 0
	while v > 1:
		v >>= 1
		exponent += 1
	return float(exponent)

# ============================================================================
# HEURISTICS
# ============================================================================

func _monotonicity(board: Array) -> float:
	# board is 4x4 array of integers (values, not exponents)
	var size: int = 4
	var total: float = 0.0
	
	# Rows
	for r in range(size):
		var values: Array[float] = []
		for c in range(size):
			values.append(_log2(board[r][c]))
			
		var inc: float = 0.0
		var dec: float = 0.0
		for i in range(size - 1):
			var diff: float = values[i] - values[i+1]
			if diff > 0:
				inc += diff
			else:
				dec += -diff
		total += maxf(inc, dec)
		
	# Columns
	for c in range(size):
		var values: Array[float] = []
		for r in range(size):
			values.append(_log2(board[r][c]))
			
		var inc: float = 0.0
		var dec: float = 0.0
		for i in range(size - 1):
			var diff: float = values[i] - values[i+1]
			if diff > 0:
				inc += diff
			else:
				dec += -diff
		total += maxf(inc, dec)
		
	return total

func _smoothness(board: Array) -> float:
	var size: int = 4
	var score: float = 0.0
	
	for r in range(size):
		for c in range(size):
			if board[r][c] == 0:
				continue
				
			var v: float = _log2(board[r][c])
			
			# Right neighbor
			if c + 1 < size and board[r][c+1] != 0:
				score -= absf(v - _log2(board[r][c+1]))
				
			# Down neighbor
			if r + 1 < size and board[r+1][c] != 0:
				score -= absf(v - _log2(board[r+1][c]))
				
	return score

func _max_tile_in_corner(board: Array) -> int:
	var size: int = 4
	var corners: Array[int] = [
		board[0][0], 
		board[0][size-1], 
		board[size-1][0], 
		board[size-1][size-1]
	]
	
	var max_tile: int = 0
	for r in range(size):
		for c in range(size):
			if board[r][c] > max_tile:
				max_tile = board[r][c]
				
	if corners.has(max_tile):
		return 1
	return 0

func _empty_cells(board: Array) -> int:
	var count: int = 0
	for row in board:
		for val in row:
			if val == 0:
				count += 1
	return count

func score_board(board: Array, weights: Dictionary = {}) -> float:
	# Default weights
	var w_mono: float = weights.get("mono", 1.0)
	var w_smooth: float = weights.get("smooth", 0.1)
	var w_corner: float = weights.get("corner", 2.0)
	var w_empty: float = weights.get("empty", 2.5)
	
	var mono: float = _monotonicity(board)
	var smooth: float = _smoothness(board)
	var corner: int = _max_tile_in_corner(board)
	var empty: int = _empty_cells(board)
	
	return (w_mono * mono) + (w_smooth * smooth) + (w_corner * float(corner)) + (w_empty * float(empty))

func score_board_from_bitboard(bb: int, weights: Dictionary = {}) -> float:
	var board: Array = bitboard_logic.bitboard_to_board(bb)
	return score_board(board, weights)

# ============================================================================
# EXPECTIMAX SEARCH
# ============================================================================

func _clear_transposition_table() -> void:
	_transposition_table.clear()

func _expectimax_search(bb: int, depth: int, is_max_node: bool, weights: Dictionary = {}) -> float:
	# Check cache
	if _transposition_table.has(bb):
		# Note: In a real robust implementation we might check depth too, 
		# but for this specific 2048 port we follow the Python logic which just checks 'bb'.
		return _transposition_table[bb]
		
	# Base case
	if depth == 0 or bitboard_logic.is_game_over(bb):
		var score: float = score_board_from_bitboard(bb, weights)
		_transposition_table[bb] = score
		return score
		
	if is_max_node:
		# MAX NODE: Player chooses best move
		var max_score: float = -1.0e18 # Float min-ish
		
		# Try 4 directions
		var directions: Array[String] = ["up", "down", "left", "right"]
		var has_move: bool = false
		
		for dir in directions:
			# We need to simulate the move.
			# Bitboard.gd has instance methods move_*.
			var res: Array = []
			if dir == "left": res = bitboard_logic.move_left(bb)
			elif dir == "right": res = bitboard_logic.move_right(bb)
			elif dir == "up": res = bitboard_logic.move_up(bb)
			elif dir == "down": res = bitboard_logic.move_down(bb)
			
			var new_bb: int = res[0]
			var score_gained: int = res[1]
			
			if new_bb == bb:
				continue
				
			has_move = true
			
			var expected_value: float = _expectimax_search(new_bb, depth, false, weights)
			var total_score: float = expected_value + float(score_gained) * 0.1
			
			if total_score > max_score:
				max_score = total_score
				
		if has_move:
			_transposition_table[bb] = max_score
			return max_score
		else:
			# No valid moves
			var score: float = score_board_from_bitboard(bb, weights)
			_transposition_table[bb] = score
			return score
			
	else:
		# CHANCE NODE
		var empty_positions: Array[int] = bitboard_logic.get_empty_positions(bb)
		
		if empty_positions.is_empty():
			var score: float = score_board_from_bitboard(bb, weights)
			_transposition_table[bb] = score
			return score
			
		var expected_value: float = 0.0
		var sample_positions: Array[int] = []
		
		if empty_positions.size() > 6:
			# Sample 6 random positions
			empty_positions.shuffle()
			sample_positions = empty_positions.slice(0, 6)
		else:
			sample_positions = empty_positions
			
		for pos in sample_positions:
			# 90% chance of 2
			var bb_2: int = bitboard_logic.add_tile(bb, pos, 1)
			# Pass alpha as -inf (not really used in the Python recursive calls for chance nodes in the same way, but keeping signature clean)
			# Python code: _expectimax_search(bb_with_2, depth - 1, True, alpha, weights)
			# I omitted alpha in argument list as it wasn't strictly used for pruning in the chance node in Python (it was passed but logic didn't prune chance node loops explicitly in the provided snippet)
			var score_2: float = _expectimax_search(bb_2, depth - 1, true, weights)
			expected_value += 0.9 * score_2
			
			# 10% chance of 4
			var bb_4: int = bitboard_logic.add_tile(bb, pos, 2)
			var score_4: float = _expectimax_search(bb_4, depth - 1, true, weights)
			expected_value += 0.1 * score_4
			
		expected_value /= float(sample_positions.size())
		
		_transposition_table[bb] = expected_value
		return expected_value

func choose_best_move(game_bb: int, depth: int = 3, weights: Dictionary = {}) -> String:
	_clear_transposition_table()
	
	var best_move: String = ""
	var best_score: float = -1.0e18
	
	var moves: Dictionary = {
		"up": func(b): return bitboard_logic.move_up(b),
		"down": func(b): return bitboard_logic.move_down(b),
		"left": func(b): return bitboard_logic.move_left(b),
		"right": func(b): return bitboard_logic.move_right(b)
	}
	
	for move_name in moves:
		var res: Array = moves[move_name].call(game_bb)
		var new_bb: int = res[0]
		var score_gained: int = res[1]
		
		if new_bb == game_bb:
			continue
			
		var expected_value: float = _expectimax_search(new_bb, depth, false, weights)
		var total_score: float = expected_value + float(score_gained) * 0.1
		
		if total_score > best_score:
			best_score = total_score
			best_move = move_name
			
	return best_move
