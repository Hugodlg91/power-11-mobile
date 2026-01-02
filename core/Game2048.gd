class_name Game2048
extends RefCounted

## Console-based 2048 implementation (Godot Engine Port).
## Wraps Bitboard logic to provide a friendly API similar to Python's Game2048 logic.

var bitboard: Bitboard
var current_board_state: int = 0
var score: int = 0
var size: int = 4

func _init() -> void:
	bitboard = Bitboard.new()
	reset()

func reset() -> void:
	current_board_state = 0
	score = 0
	_add_random_tile()
	_add_random_tile()

func _add_random_tile() -> bool:
	var empties: Array[int] = bitboard.get_empty_positions(current_board_state)
	if empties.is_empty():
		return false
	
	var pos: int = empties.pick_random()
	# 90% chance of 2 (1), 10% chance of 4 (2)
	var val: int = 1 if randf() < 0.9 else 2
	current_board_state = bitboard.add_tile(current_board_state, pos, val)
	return true

func move(direction: String) -> bool:
	# Direction: "up", "down", "left", "right"
	# Maps to map/ui inputs if needed, but here we expect string.
	
	var result: Array = []
	match direction:
		"left": result = bitboard.move_left(current_board_state)
		"right": result = bitboard.move_right(current_board_state)
		"up": result = bitboard.move_up(current_board_state)
		"down": result = bitboard.move_down(current_board_state)
		_:
			push_error("Invalid direction: " + direction)
			return false
	
	var new_bb: int = result[0]
	var gained: int = result[1]
	
	if new_bb != current_board_state:
		current_board_state = new_bb
		score += gained
		_add_random_tile()
		return true
		
	return false

func get_board_array() -> Array:
	return bitboard.bitboard_to_board(current_board_state)

func get_board_array_copy() -> Array:
	return get_board_array().duplicate(true)

func is_game_over() -> bool:
	return bitboard.is_game_over(current_board_state)

func has_won() -> bool:
	# Check if max tile >= 2048
	return bitboard.get_max_tile(current_board_state) >= 2048
