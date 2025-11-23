extends Node

var WEBSOCKET_URL: String
var _client = WebSocketPeer.new()
var _opened = false
var _userID = "Player" + OS.get_unique_id()

func _ready():
	WEBSOCKET_URL = Util.server_conf.get_value("NETWORK", "WEBSOCKET_PORT")
	WEBSOCKET_URL += "/?user=" + _userID
	print("attempting to connect to ", WEBSOCKET_URL)
	var res = _client.connect_to_url(WEBSOCKET_URL)
	assert(res == OK, "connect_to_host() failed")
	
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
			print(_client.get_packet().get_string_from_utf8())
			
	elif _client.get_ready_state() == WebSocketPeer.STATE_CLOSING:
		pass
	elif _client.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		if _opened:
			print("disconnected")
			_opened = false
