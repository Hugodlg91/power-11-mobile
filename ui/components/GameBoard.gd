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
	var side = p_size
	margin = p_margin
	cell_size = int((side - (5 * margin)) / 4)
	_draw_static_bg()

func update_theme(p_theme: String) -> void:
	theme_name = p_theme
	var theme_colors = UIAssets.get_theme_colors(theme_name)
	board_bg.color = theme_colors["bg"]
	for t in grid_tiles.values():
		t.update_appearance(theme_name)
	_draw_static_bg()

func _draw_static_bg() -> void:
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

func animate_transition(old_board: Array, new_board: Array, direction: String) -> void:
	is_animating = true
	
	var size = 4
	var animations: Array = []
	var spawn_animations: Array = []
	
	# Matrices de suivi
	var old_tiles_used = {}
	var new_tiles_used = {}
	for r in range(size):
		for c in range(size):
			old_tiles_used[Vector2i(r, c)] = false
			new_tiles_used[Vector2i(r, c)] = false
	
	# 1. DÉTECTION DES MOUVEMENTS ET FUSIONS
	if direction in ["left", "right"]:
		for row in range(size):
			var old_positions: Array = []
			var new_positions: Array = []
			
			# Collecte des positions non-vides
			var range_cols = range(size) if direction == "left" else range(size - 1, -1, -1)
			
			for c in range_cols:
				if old_board[row][c] != 0: old_positions.append(Vector2i(row, c))
				if new_board[row][c] != 0: new_positions.append(Vector2i(row, c))
			
			var old_idx = 0
			var new_idx = 0
			
			while new_idx < new_positions.size():
				# Si on a épuisé les vieilles tuiles, on arrête
				if old_idx >= old_positions.size():
					break 
				
				var new_pos = new_positions[new_idx]
				var old_pos = old_positions[old_idx]
				var new_val = new_board[new_pos.x][new_pos.y]
				var old_val = old_board[old_pos.x][old_pos.y]
				
				# Check Fusion
				if old_idx + 1 < old_positions.size():
					var next_old_pos = old_positions[old_idx + 1]
					var next_old_val = old_board[next_old_pos.x][next_old_pos.y]
					if old_val == next_old_val and old_val * 2 == new_val:
						# Animation pour les DEUX tuiles qui fusionnent
						animations.append({"value": old_val, "from_pos": old_pos, "to_pos": new_pos, "is_merge": true})
						animations.append({"value": next_old_val, "from_pos": next_old_pos, "to_pos": new_pos, "is_merge": true})
						
						old_tiles_used[old_pos] = true
						old_tiles_used[next_old_pos] = true
						new_tiles_used[new_pos] = true # Marqué APRÈS confirmation
						
						old_idx += 2
						new_idx += 1
						continue
				
				# Mouvement Simple
				animations.append({"value": old_val, "from_pos": old_pos, "to_pos": new_pos, "is_merge": false})
				old_tiles_used[old_pos] = true
				new_tiles_used[new_pos] = true # Marqué APRÈS confirmation
				old_idx += 1
				new_idx += 1

	else: # up / down
		for col in range(size):
			var old_positions: Array = []
			var new_positions: Array = []
			
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
				
				# Check Fusion
				if old_idx + 1 < old_positions.size():
					var next_old_pos = old_positions[old_idx + 1]
					var next_old_val = old_board[next_old_pos.x][next_old_pos.y]
					if old_val == next_old_val and old_val * 2 == new_val:
						animations.append({"value": old_val, "from_pos": old_pos, "to_pos": new_pos, "is_merge": true})
						animations.append({"value": next_old_val, "from_pos": next_old_pos, "to_pos": new_pos, "is_merge": true})
						
						old_tiles_used[old_pos] = true
						old_tiles_used[next_old_pos] = true
						new_tiles_used[new_pos] = true # Marqué APRÈS confirmation
						
						old_idx += 2
						new_idx += 1
						continue
				
				# Mouvement Simple
				animations.append({"value": old_val, "from_pos": old_pos, "to_pos": new_pos, "is_merge": false})
				old_tiles_used[old_pos] = true
				new_tiles_used[new_pos] = true # Marqué APRÈS confirmation
				old_idx += 1
				new_idx += 1

	# 2. DÉTECTION DES SPAWNS
	for r in range(size):
		for c in range(size):
			if new_board[r][c] != 0 and not new_tiles_used[Vector2i(r, c)]:
				spawn_animations.append({
					"value": new_board[r][c],
					"pos": Vector2i(r, c)
				})
	
	# Execute animations
	var tiles_to_remove = []
	var next_grid_tiles = {}
	
	for anim in animations:
		var from_pos = anim["from_pos"]
		var to_pos = anim["to_pos"]
		var is_merge = anim["is_merge"]
		
		if grid_tiles.has(from_pos):
			var tile = grid_tiles[from_pos]
			var target_px = get_tile_pos(to_pos.y, to_pos.x)
			
			tile.animate_move(target_px, animation_duration)
			
			if is_merge:
				tiles_to_remove.append(tile)
			else:
				tile.grid_pos = to_pos
				next_grid_tiles[to_pos] = tile
				
	# Update main grid with the new state
	grid_tiles = next_grid_tiles
	
	call_deferred("_finalize_animation", tiles_to_remove, animations, spawn_animations, new_board)

func _finalize_animation(tiles_to_remove: Array, animations: Array, spawn_animations: Array, new_board: Array) -> void:
	await get_tree().create_timer(animation_duration).timeout
	
	# Remove merged tiles
	for tile in tiles_to_remove:
		if is_instance_valid(tile):
			tile.queue_free()
	
	# Create merged result tiles
	var merge_targets = {}
	for anim in animations:
		if anim["is_merge"]:
			var to_pos = anim["to_pos"]
			if not merge_targets.has(to_pos):
				merge_targets[to_pos] = new_board[to_pos.x][to_pos.y]
	
	for pos in merge_targets:
		var value = merge_targets[pos]
		if not grid_tiles.has(pos):
			create_tile(value, pos.x, pos.y, false).animate_merge()
	
	# Create spawned tiles
	for spawn_anim in spawn_animations:
		var pos = spawn_anim["pos"]
		var value = spawn_anim["value"]
		if not grid_tiles.has(pos):
			create_tile(value, pos.x, pos.y, true)
	
	is_animating = false
	emit_signal("animation_finished")
