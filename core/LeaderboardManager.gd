class_name LeaderboardManager
extends Node

## Manages online leaderboards using LootLocker API.
## Ported from core/leaderboard.py but adapted for Godot (Async/Signals).

const GAME_API_KEY: String = "dev_40da32792a654b99982ba75327e4a8b0"
const LEADERBOARD_KEY: String = "32471"
const API_URL: String = "https://api.lootlocker.io/game/v2/session/guest"
const LEADERBOARD_URL: String = "https://api.lootlocker.io/game/leaderboards/%s" % LEADERBOARD_KEY
const ID_FILE: String = "user://player_ids.json" # Use user:// for save data

var _session_token: String = ""
var _current_player_id: int = 0
var _current_player_name: String = ""

# Map to hold active requests to prevent garbage collection if we were using purely local vars,
# but adding children nodes handles their lifecycle.

func _ready() -> void:
	pass

# ============================================================================
# UUID Generation (Approximation of Python's uuid.uuid4())
# ============================================================================
func _generate_uuid_v4() -> String:
	# 8-4-4-4-12 hex digits
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var parts = []
	parts.append("%08x" % rng.randi())
	parts.append("%04x" % (rng.randi() & 0xFFFF))
	# version 4: 0100xxxx -> set bit 12-15 to 0100 (4)
	var time_hi = (rng.randi() & 0x0FFF) | 0x4000
	parts.append("%04x" % time_hi)
	# variant: 10xxxxxx -> set bit 6-7 to 10 (8, 9, A, B)
	var variant = (rng.randi() & 0x3FFF) | 0x8000
	parts.append("%04x" % variant)
	parts.append("%04x" % (rng.randi() & 0xFFFF) + "%08x" % rng.randi())
	
	return "-".join(parts)

# ============================================================================
# DATA PERSISTENCE
# ============================================================================
func get_uuid_for_name(p_name: String) -> String:
	var data: Dictionary = {}
	
	if FileAccess.file_exists(ID_FILE):
		var file = FileAccess.open(ID_FILE, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			var json = JSON.new()
			if json.parse(text) == OK:
				data = json.data
	
	if data.has(p_name):
		return data[p_name]
		
	var new_uuid: String = _generate_uuid_v4()
	data[p_name] = new_uuid
	
	var file_w = FileAccess.open(ID_FILE, FileAccess.WRITE)
	if file_w:
		file_w.store_string(JSON.stringify(data, "\t"))
		
	return new_uuid

# ============================================================================
# NETWORK CALLS
# ============================================================================

## Authernticate guest session. Returns true if successful.
func start_session(player_name: String = "Spectator") -> bool:
	if not _session_token.is_empty() and _current_player_name == player_name:
		return true
		
	var player_identifier: String = get_uuid_for_name(player_name)
	
	var headers: PackedStringArray = ["Content-Type: application/json"]
	var payload: Dictionary = {
		"game_key": GAME_API_KEY,
		"game_version": "1.0.0",
		"player_identifier": player_identifier
	}
	
	var json_payload: String = JSON.stringify(payload)
	
	# Create HTTPRequest node dynamically
	var request = HTTPRequest.new()
	add_child(request)
	request.request(API_URL, headers, HTTPClient.METHOD_POST, json_payload)
	
	# Await response
	var result = await request.request_completed
	# result is [result, response_code, headers, body]
	var response_code = result[1]
	var body = result[3]
	
	request.queue_free()
	
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.data
			_session_token = data.get("session_token", "")
			_current_player_id = data.get("player_id", 0)
			_current_player_name = player_name
			
			print("[ONLINE] Connected as '%s' (ID: %s)" % [player_name, _current_player_id])
			
			if player_name != "Spectator":
				_set_player_name_online(player_name)
				
			return true
	
	print("[ONLINE] Auth Error: Code %d" % response_code)
	return false

func _set_player_name_online(p_name: String) -> void:
	var url: String = "https://api.lootlocker.io/game/v1/player/name"
	var headers: PackedStringArray = [
		"Content-Type: application/json",
		"x-session-token: " + _session_token
	]
	var payload: Dictionary = {"name": p_name}
	
	var request = HTTPRequest.new()
	add_child(request)
	request.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(payload))
	await request.request_completed
	request.queue_free()
	# Fire and forget mostly, we don't strictly wait for this success to proceed game

## Submit score. key = "score", "member_id", "metadata"
func submit_score(player_name: String, score: int) -> bool:
	var success: bool = await start_session(player_name)
	if not success:
		return false
		
	var url: String = LEADERBOARD_URL + "/submit"
	var headers: PackedStringArray = [
		"Content-Type: application/json",
		"x-session-token: " + _session_token
	]
	
	var payload: Dictionary = {
		"score": str(score),
		"member_id": str(_current_player_id),
		"metadata": player_name
	}
	
	var request = HTTPRequest.new()
	add_child(request)
	request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	
	var result = await request.request_completed
	var response_code = result[1]
	request.queue_free()
	
	if response_code == 200:
		print("[ONLINE] Score submitted for %s: %d" % [player_name, score])
		return true
		
	print("[ONLINE] Submit Error: %d" % response_code)
	return false

## Returns Array of Dictionary {rank, name, score}
func get_top_scores(count: int = 10) -> Array:
	if _session_token.is_empty():
		var ok = await start_session("Spectator")
		if not ok: return []
		
	var url: String = LEADERBOARD_URL + "/list?count=%d" % count
	var headers: PackedStringArray = [
		"x-session-token: " + _session_token
	]
	
	var request = HTTPRequest.new()
	add_child(request)
	request.request(url, headers, HTTPClient.METHOD_GET)
	
	var result = await request.request_completed
	var response_code = result[1]
	var body = result[3]
	request.queue_free()
	
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.data
			var items = data.get("items", [])
			var final_list: Array = []
			
			for item in items:
				var rank = item.get("rank")
				var score = item.get("score")
				var player_name = item.get("metadata", "")
				
				if str(player_name).is_empty():
					var player = item.get("player", {})
					player_name = player.get("name", "")
				if str(player_name).is_empty():
					player_name = "Player " + str(item.get("member_id"))
					
				final_list.append({
					"rank": rank,
					"name": player_name,
					"score": score
				})
			return final_list
			
	print("[ONLINE] Fetch Error: %d" % response_code)
	return []
