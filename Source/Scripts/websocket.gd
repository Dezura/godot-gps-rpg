class_name WebSocketThingy extends Node

var WEBSOCKET_URL: String
var _client = WebSocketPeer.new()
var _opened = false
const ADJECTIVES = ["Ancient", "Cobalt", "Cosmic", "Crimson", "Digital", "Electric", "Frost", "Gilded", "Hollow", "Infinite", "Iron", "Lunar", "Neon", "Noble", "Prime", "Rapid", "Silent", "Solar", "Velvet", "Wild"]
const NOUNS = ["Anchor", "Badge", "Canyon", "Echo", "Falcon", "Grove", "Haven", "Hunter", "Nomad", "Orbit", "Pixel", "Rider", "Shadow", "Signal", "Spark", "Storm", "Tiger", "Vector", "Viper", "Zenith"]
var _user_id := OS.get_unique_id()
var _username: String
var _user_color: String

signal message_received(message: String)
signal pvp_lobby_updated(data)
signal pos_payload_updated(data)

func _ready():
	WEBSOCKET_URL = Util.server_conf.get_value("NETWORK", "WEBSOCKET_PORT") + "/?user=%s" % _user_id
	print("attempting to connect to ", WEBSOCKET_URL)
	var res = _client.connect_to_url(WEBSOCKET_URL)
	assert(res == OK, "connect_to_host() failed")
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var r = rng.randf_range(0.5, 1.0)
	var g = rng.randf_range(0.5, 1.0)
	var b = rng.randf_range(0.5, 1.0)
	_user_color = Color(r, g, b).to_html(false)
	
	var random_adj = ADJECTIVES[rng.randi_range(0, ADJECTIVES.size() - 1)]
	var random_noun = NOUNS[rng.randi_range(0, NOUNS.size() - 1)]
	_username = random_adj + " " + random_noun


func _process(_delta: float) -> void:
	_client.poll()
	
	if _client.get_ready_state() == WebSocketPeer.STATE_OPEN:
		if _opened == false:
			print("connected")
			_opened = true
			#send_text works completely fine for emitting new message
			_client.send_text("hello testing from godot")
			
		while (_client.get_available_packet_count() > 0):
			# get_available_packet_count() returns the number of packets available to be processed,
			# so while it's greater than 0, print packet converted to a string
			var msg = _client.get_packet().get_string_from_utf8()
			
			var parsed = {}
			var is_json = false
			# Try parsing JSON
			if msg.begins_with("{") and msg.ends_with("}"):
				parsed = JSON.parse_string(msg)
				if typeof(parsed) != null:
					is_json = true
			
			if is_json:
				if parsed.has("type") and parsed.type == "pvp_lobby_update":
					print("new packet")
					print(parsed.lobby)
					pvp_lobby_updated.emit(parsed)
					print(msg)
				elif parsed.has("type") and parsed.type == "position_lobby_update":
					pos_payload_updated.emit(parsed)
			else:
				print("new packet")
				print(msg)
				if msg == "DezuraCaptainNoob":
					print("function goes here - websocket.gd")
					# Do Something
					Util.game.enemy_manager._reset_all_enemies()
					Util.game.enemy_manager.fetch_enemy_data(Util.game.current_city)
				elif msg == "TuxModeActivate":
					print("Tux Mode Activated")
					# Do Something
					Util.game.enemy_manager._reset_all_enemies()
					Util.game.enemy_manager.fetch_enemy_data(Util.game.current_city, true)
				elif msg == "ClearedPVPLobby":
					print("Cleared PVP Lobby")
					Util.hud.pvp_encounter_menu.hide()
				else:
					message_received.emit(msg)
			
	elif _client.get_ready_state() == WebSocketPeer.STATE_CLOSING:
		pass
	elif _client.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		if _opened:
			print("disconnected")
			_opened = false
			
func send_message(text: String) -> void:
	if _opened:
		if text.begins_with("/reset"):
			Util.game.server_api.request_enemy_reset(Util.game.current_city)
			_client.send_text(text)
		elif text.begins_with("/tux"):
			Util.game.server_api.request_enemy_reset(Util.game.current_city)
			_client.send_text(text)
		elif text.begins_with("/start-tracking"):
			Util.game.is_tracking_pos = true
			Util.game.position_track_timer.start()
			if not pos_payload_updated.is_connected(Util.game._on_receive_pos_payload):
				pos_payload_updated.connect(Util.game._on_receive_pos_payload)
		elif text.begins_with("/stop-tracking"):
			Util.game.is_tracking_pos = false
			Util.game.position_track_timer.stop()
			for netplayer_id in Util.game.tracked_players:
				Util.game.tracked_players[netplayer_id].queue_free()
			if pos_payload_updated.is_connected(Util.game._on_receive_pos_payload):
				pos_payload_updated.disconnect(Util.game._on_receive_pos_payload)
			var payload = {
				"type": "position_lobby_update",
				"update": "disconnect",
			}
			_client.send_text(JSON.stringify(payload))
		elif text.begins_with("/debug-clear-lobby"):
			_client.send_text(text)
		elif text.begins_with("/pvp"):
			var payload = {
				"type": "pvp_lobby_request",
				"update": "join",
				"level": Util.game.player.level,
				"name": _username,
				"hp": Util.game.player.hp,
				"max_hp": Util.game.player.max_hp
			}
			_client.send_text(JSON.stringify(payload))
		else:
			var full_message = "[color=#%s]%s[/color]: %s" % [_user_color, _username, text]
			_client.send_text(full_message)
			
		
func send_level_up_message(new_level: int) -> void:
	if _opened:
		var full_message = "[color=#%s]%s leveled up to %s![/color]" % [_user_color, _username, new_level]
		_client.send_text(full_message)
	
