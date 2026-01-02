extends SceneTree

func _init():
	print("Testing Table Initialization...")
	
	# Force initialization
	Bitboard.__init_tables()
	
	if Bitboard.ROW_LEFT_TABLE.size() != 65536:
		printerr("Table size wrong! ", Bitboard.ROW_LEFT_TABLE.size())
		quit(1)
		
	# Test Left Move
	# Input: [0, 2, 0, 0] (0x0010 = 16)
	# Expected: [2, 0, 0, 0] (0x0001 = 1)
	var val_in = 16
	var val_out = Bitboard.ROW_LEFT_TABLE[val_in]
	print("Left Move [0,2,0,0] -> ", val_out)
	
	if val_out != 1:
		printerr("FAILED Left Move! Expected 1, got ", val_out)
	else:
		print("PASSED Left Move")

	# Test Right Move
	# Input: [2, 0, 0, 0] (0x0001 = 1)
	# Expected: [0, 0, 0, 2] (0x1000 = 4096)
	val_in = 1
	val_out = Bitboard.ROW_RIGHT_TABLE[val_in]
	print("Right Move [2,0,0,0] -> ", val_out)
	
	if val_out != 4096:
		printerr("FAILED Right Move! Expected 4096, got ", val_out)
	else:
		print("PASSED Right Move")
		
	print("Tables Verification Complete.")
	quit()
