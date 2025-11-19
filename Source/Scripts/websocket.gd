extends Node

var WEBSOCKET_URL = Util.server_conf.get_value("NETWORK", "WEBSOCKET_PORT")

var _client = WebSocketPeer.new()
var _opened = false

func _ready():
	print("attempting to connect")
	var res = _client.connect_to_url(WEBSOCKET_URL)
	if !res.ok:
		print("problem with connection: %s", res)
		return
	
func _process(_delta: float) -> void:
	_client.poll()
	
	if _client.get_ready_state() == WebSocketPeer.STATE_OPEN:
		if _opened == false:
			print("connected")
			_opened = true
			
	elif _client.get_ready_state() == WebSocketPeer.STATE_CLOSING:
		pass
	elif _client.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		if _opened:
			print("disconnected")
			_opened = false
