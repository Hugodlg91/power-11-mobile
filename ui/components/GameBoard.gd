extends Control

const TileScene = preload("res://ui/Tile.tscn")

@onready var board_bg: ColorRect = $BoardBG
@onready var tile_layer: Control = $TileLayer

var theme_name: String = "Classic"
var cell_size: int = 100
var margin: int = 15
var animation_duration: float = 0.20
var is_animating: bool = false
var grid_tiles: Dictionary = {} 

signal animation_finished

func setup(p_size: float, p_margin: int) -> void:
	# Calculate cell size based on container width/height (assumed square)
	# Size is available from self.size or custom_minimum_size
	# But actually we often set custom_minimum_size from outside.
	# Let's trust custom_minimum_size.x
	var side = p_size
	margin = p_margin
	cell_size = int((side - (5 * margin)) / 4)
	
	_draw_static_bg()

func update_theme(p_theme: String) -> void:
	theme_name = p_theme
	var theme_colors = UIAssets.get_theme_colors(theme_name)
	board_bg.color = theme_colors["bg"]
	# Update existing tiles?
	for t in grid_tiles.values():
		t.update_appearance(theme_name)
	# Re-draw static slots
	_draw_static_bg()

func _draw_static_bg() -> void:
	# Clear old slots
	for c in board_bg.get_children():
		c.queue_free()
		
	var theme_colors = UIAssets.get_theme_colors(theme_name)
	board_bg.color = theme_colors["bg"]
	
	for r in range(4):
		for c in range(4):
			var slot = ColorRect.new()
			slot.color = theme_colors["empty"]
			slot.size = Vector2(cell_size, cell_size)
			slot.position = get_tile_pos(c, r)
			board_bg.add_child(slot)

func get_tile_pos(col: int, row: int) -> Vector2:
	return Vector2(
		margin + col * (cell_size + margin),
		margin + row * (cell_size + margin)
	)

func clear_board() -> void:
	for t in tile_layer.get_children():
		t.queue_free()
	grid_tiles.clear()

func spawn_board(board_array: Array) -> void:
	clear_board()
	for r in range(4):
		for c in range(4):
			var val = board_array[r][c]
			if val != 0:
				create_tile(val, r, c, false)

func create_tile(val: int, row: int, col: int, anim_spawn: bool) -> Control:
	var t = TileScene.instantiate()
	tile_layer.add_child(t)
	var pos = get_tile_pos(col, row)
	t.setup(val, cell_size, Vector2i(row, col), pos, theme_name)
	
	grid_tiles[Vector2i(row, col)] = t
	
	if anim_spawn:
		t.animate_spawn()
		
	return t

# ============================================================================
# ANIMATION LOGIC (Refactored from PlayScreen)
# ============================================================================
func animate_transition(_old_board: Array, new_board: Array, direction: String) -> void:
	is_animating = true
	
	var spawns_from_merge: Array = []
	var spawns_random: Array = []
	var moves: Array = [] 
	
	# --- SIMULATION LOGIC (Same as PlayScreen) ---
	# We process grid_tiles based on direction
	
	# Helper to find tile at r,c
	# (Already mostly correct in PlayScreen logic, just needing 'grid_tiles')
	
	if direction == "left":
		for r in range(4):
			var new_col_cursor = 0
			var last_val = -1
			
			for c in range(4):
				if not grid_tiles.has(Vector2i(r, c)): continue
				var tile = grid_tiles[Vector2i(r, c)]
				var val = tile.value
				
				if last_val == val:
					moves.append({ "node": tile, "tr": r, "tc": new_col_cursor - 1, "is_merge": true })
					last_val = -1
					spawns_from_merge.append({ "r": r, "c": new_col_cursor - 1, "val": val * 2 })
				else:
					last_val = val
					moves.append({ "node": tile, "tr": r, "tc": new_col_cursor, "is_merge": false })
					new_col_cursor += 1
					
	elif direction == "right":
		for r in range(4):
			var new_col_cursor = 3
			var last_val = -1
			
			for c in range(3, -1, -1):
				if not grid_tiles.has(Vector2i(r, c)): continue
				var tile = grid_tiles[Vector2i(r, c)]
				var val = tile.value
				
				if last_val == val:
					moves.append({ "node": tile, "tr": r, "tc": new_col_cursor + 1, "is_merge": true })
					last_val = -1; spawns_from_merge.append({ "r": r, "c": new_col_cursor + 1, "val": val * 2 })
				else:
					last_val = val; moves.append({ "node": tile, "tr": r, "tc": new_col_cursor, "is_merge": false })
					new_col_cursor -= 1
					
	elif direction == "up":
		for c in range(4):
			var new_row_cursor = 0
			var last_val = -1
			
			for r in range(4):
				if not grid_tiles.has(Vector2i(r, c)): continue
				var tile = grid_tiles[Vector2i(r, c)]
				var val = tile.value
				
				if last_val == val:
					moves.append({ "node": tile, "tr": new_row_cursor - 1, "tc": c, "is_merge": true })
					last_val = -1; spawns_from_merge.append({ "r": new_row_cursor - 1, "c": c, "val": val * 2 })
				else:
					last_val = val; moves.append({ "node": tile, "tr": new_row_cursor, "tc": c, "is_merge": false })
					new_row_cursor += 1
					
	elif direction == "down":
		for c in range(4):
			var new_row_cursor = 3
			var last_val = -1
			
			for r in range(3, -1, -1):
				if not grid_tiles.has(Vector2i(r, c)): continue
				var tile = grid_tiles[Vector2i(r, c)]
				var val = tile.value
				
				if last_val == val:
					moves.append({ "node": tile, "tr": new_row_cursor + 1, "tc": c, "is_merge": true })
					last_val = -1; spawns_from_merge.append({ "r": new_row_cursor + 1, "c": c, "val": val * 2 })
				else:
					last_val = val; moves.append({ "node": tile, "tr": new_row_cursor, "tc": c, "is_merge": false })
					new_row_cursor -= 1

	grid_tiles.clear()
	
	# Random Spawns logic (Simplified: any non-zero in new_board not covered by move target)
	# Actually, simpler: Any tile in new_board that wasn't a merge target is either a moved tile or random spawn.
	# But we need to know WHICH one is random to trigger pop animation.
	# The logic "Any slot not covered by a Move Destination (slide or merge) is Random" holds.
	
	var destinations = {}
	for m in moves:
		destinations[Vector2i(m.tr, m.tc)] = true
		
	# Wait, if a merge happens at (0,0), destinations[(0,0)] is true.
	# If a slide happens to (0,1), destinations[(0,1)] is true.
	# The random spawn appears at an EMPTY spot.
	# So if we animate everything correctly, the random spawn appears where no tile "landed".
	
	for r in range(4):
		for c in range(4):
			if new_board[r][c] != 0:
				if not destinations.has(Vector2i(r, c)):
					spawns_random.append({ "r": r, "c": c, "val": new_board[r][c] })

	# Fire Tweens
	for m in moves:
		var tile = m.node
		var target_pos = get_tile_pos(m.tc, m.tr)
		tile.animate_move(target_pos, animation_duration)
		
		# If merge, destroy after
		if m.is_merge:
			get_tree().create_timer(animation_duration).timeout.connect(func(): tile.queue_free())
		else:
			# Check if this slide ends up dying inside a merge (the "first half" of merge logic)
			var dies = false
			for sm in spawns_from_merge:
				if sm.r == m.tr and sm.c == m.tc:
					dies = true; break
			
			if dies:
				get_tree().create_timer(animation_duration).timeout.connect(func(): tile.queue_free())
			else:
				# Keep it
				tile.grid_pos = Vector2i(m.tr, m.tc)
				grid_tiles[Vector2i(m.tr, m.tc)] = tile
				
	# Schedule Results
	get_tree().create_timer(animation_duration).timeout.connect(func():
		_finalize_turn(spawns_from_merge, spawns_random)
	)

func _finalize_turn(merges: Array, randoms: Array) -> void:
	for m in merges:
		create_tile(m.val, m.r, m.c, false).animate_merge()
	for r in randoms:
		create_tile(r.val, r.r, r.c, true)
		
	is_animating = false
	emit_signal("animation_finished")
