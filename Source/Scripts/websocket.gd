extends Node

var WEBSOCKET_URL: String
var _client = WebSocketPeer.new()
var _opened = false
const ADJECTIVES = ["Ancient", "Cobalt", "Cosmic", "Crimson", "Digital", "Electric", "Frost", "Gilded", "Hollow", "Infinite", "Iron", "Lunar", "Neon", "Noble", "Prime", "Rapid", "Silent", "Solar", "Velvet", "Wild"]
const NOUNS = ["Anchor", "Badge", "Canyon", "Echo", "Falcon", "Grove", "Haven", "Hunter", "Nomad", "Orbit", "Pixel", "Rider", "Shadow", "Signal", "Spark", "Storm", "Tiger", "Vector", "Viper", "Zenith"]
var _userID: String
var _user_color: String

signal message_received(message: String)

func _ready():
	WEBSOCKET_URL = Util.server_conf.get_value("NETWORK", "WEBSOCKET_PORT")
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
	_userID = random_adj + " " + random_noun


func _process(_delta: float) -> void:
	_client.poll()
	
	if _client.get_ready_state() == WebSocketPeer.STATE_OPEN:
		if _opened == false:
			print("connected")
			_opened = true
			#send_text works completely fine for emitting new message
			_client.send_text("hello testing from godot")
			
		while (_client.get_available_packet_count() > 0):
			print("new packet")
			# get_available_packet_count() returns the number of packets available to be processed,
			# so while it's greater than 0, print packet converted to a string
			var msg = _client.get_packet().get_string_from_utf8()
			print(msg)
			if msg == "DezuraCaptainNoob":
				print("function goes here - websocket.gd")
				# Do Something
			elif msg == "TuxModeActivate":
				print("Tux Mode Activated")
				# Do Something
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
		if text == "/reset":
			_client.send_text(text)
		elif text == "/tux":
			_client.send_text(text)
		else:
			var full_message = "[color=#%s]%s[/color]: %s" % [_user_color, _userID, text]
			_client.send_text(full_message)
			
		
func send_level_up_message(new_level: int) -> void:
	if _opened:
		var full_message = "[color=#%s]%s leveled up to %s![/color]" % [_user_color, _userID, new_level]
		_client.send_text(full_message)
	
