extends Node

func _ready() -> void:
	print("Starting Leaderboard Network Tests...")
	run_tests()

func run_tests() -> void:
	var LBManager = load("res://core/LeaderboardManager.gd")
	var leaderboard = LBManager.new()
	add_child(leaderboard)
	
	print("1. Authenticating as 'GodotTester'...")
	var success = await leaderboard.start_session("GodotTester")
	
	if success:
		print("  ✓ Authentication success")
	else:
		push_error("FAIL: Authentication failed")
		print("FAIL: Authentication failed")
		
	print("2. Fetching Top 5 Scores...")
	var scores = await leaderboard.get_top_scores(5)
	
	if scores.size() > 0:
		print("  ✓ Retrieved %d scores" % scores.size())
		for s in scores:
			print("    - #%s %s: %s" % [str(s.rank), s.name, str(s.score)])
	else:
		print("  ! No scores retrieved or empty leaderboard (or error)")
		
	print("✅ Network Tests Completed")
	get_tree().quit()
