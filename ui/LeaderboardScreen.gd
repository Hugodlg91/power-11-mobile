extends Control

@onready var content_box: VBoxContainer = $ScrollContainer/Content
@onready var msg_label: Label = $MessageLabel
@onready var back_btn: Button = $BackButton

var db_manager: LeaderboardManager

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	
	# Clean placeholder
	for c in content_box.get_children():
		c.queue_free()
		
	# Instantiate Manager
	var DBClass = load("res://core/LeaderboardManager.gd")
	if not DBClass:
		print("LeaderboardScreen: Failed to load LeaderboardManager class")
		msg_label.text = "Error: Cannot load leaderboard system"
		msg_label.visible = true
		return
		
	db_manager = DBClass.new()
	if not db_manager:
		print("LeaderboardScreen: Failed to create LeaderboardManager instance")
		msg_label.text = "Error: Cannot initialize leaderboard"
		msg_label.visible = true
		return
		
	add_child(db_manager)
	
	_load_scores()

func _load_scores() -> void:
	msg_label.visible = true
	msg_label.text = "Loading..."
	
	var scores = await db_manager.get_top_scores(10)
	
	msg_label.visible = false
	
	if scores.is_empty():
		msg_label.text = "No scores available. Check your internet connection."
		msg_label.visible = true
		return
		
	for item in scores:
		_create_row(item["rank"], item["name"], item["score"])

func _create_row(rank, p_name, score) -> void:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	# Use custom minimum height?
	
	# Rank
	var lbl_rank = Label.new()
	lbl_rank.text = "#" + str(int(rank))
	lbl_rank.custom_minimum_size = Vector2(80, 0)
	lbl_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var c = Color(0.8, 0.8, 0.8)
	if int(rank) == 1: c = Color(1, 0.84, 0) # Gold
	elif int(rank) == 2: c = Color(0.75, 0.75, 0.75) # Silver
	elif int(rank) == 3: c = Color(0.8, 0.5, 0.2) # Bronze
	lbl_rank.modulate = c
	
	# Name
	var lbl_name = Label.new()
	lbl_name.text = str(p_name).substr(0, 12)
	lbl_name.custom_minimum_size = Vector2(250, 0)
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_name.modulate = c
	
	# Score
	var lbl_score = Label.new()
	lbl_score.text = str(int(score))
	lbl_score.custom_minimum_size = Vector2(150, 0)
	lbl_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl_score.modulate = c
	
	hbox.add_child(lbl_rank)
	
	# Spacer
	var s1 = Control.new()
	s1.custom_minimum_size = Vector2(20, 0)
	hbox.add_child(s1)
	
	hbox.add_child(lbl_name)
	
	# Spacer
	var s2 = Control.new()
	s2.custom_minimum_size = Vector2(20, 0)
	hbox.add_child(s2)
	
	hbox.add_child(lbl_score)
	
	content_box.add_child(hbox)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
