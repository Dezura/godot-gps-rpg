class_name ServerAPI extends Node

signal server_connected
signal tile_received(tile_pos: Vector2i, tile: MvtTile)
signal tile_failed(tile_pos: Vector2i, message: String)
signal city_poi_received(city_name: String, poi_list: Array[Vector2])
signal city_poi_failed(city_name: String, message: String)
signal city_tiles_received(city_name: String, tiles: Dictionary[Vector2i, MvtTile])
signal city_tiles_failed(city_name: String, message: String)

class RequestData:
	var initial_data
	var url: String
	var headers: Array[String]
	var max_attempts: int = 3
	
	var parse_method: Callable
	
	var received_signal: Signal
	var failed_signal: Signal

var client: HTTPClient
var busy := false
var host: String
var port: int

var _request_queue: Array[RequestData] = []



func _ready() -> void:
	host = Util.server_conf.get_value("NETWORK", "SERVER_ADDRESS")
	port = Util.server_conf.get_value("NETWORK", "SERVER_PORT")
	await _connect()
	server_connected.emit()
	set_process(true)


func _connect() -> void:
	client = HTTPClient.new()
	var err = client.connect_to_host(host, port)
	assert(err == OK, "connect_to_host() failed")
	
	while client.get_status() in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING]:
		print("[ServerAPI] Connecting to server... %s:%s" % [host, port])
		client.poll()
		await get_tree().process_frame
	
	assert(client.get_status() == HTTPClient.STATUS_CONNECTED, "Connection failed")
	print("[ServerAPI] Connected to %s:%s" % [host, port])


func request_tile_data(tile_pos: Vector2i) -> void:
	# Check if an existing request already exists before proceeding
	for i in _request_queue.size():
		if _request_queue[i].initial_data == tile_pos:
			return
	var new_request := RequestData.new()
	
	new_request.url = "/tile-data?x=%d&y=%d" % [tile_pos.x, tile_pos.y]
	new_request.headers = [
		"Content-Type: application/x-protobuf",
		"Connection: keep-alive"
	]
	new_request.initial_data = tile_pos
	new_request.parse_method = _parse_tile_data
	new_request.received_signal = tile_received
	new_request.failed_signal = tile_failed
	_request_queue.append(new_request)


func request_poi_data() -> void:
	pass


func _process(_delta: float) -> void:
	if busy or _request_queue.is_empty():
		return
	busy = true
	var next_request = _request_queue.pop_front()
	_perform_request(next_request, 1)


func _perform_request(request: RequestData, attempt: int) -> void:
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		print("[ServerAPI] Status not CONNECTED (%s) – reconnecting..." % client.get_status())
		await _reconnect()
	
	print("[ServerAPI] → GET %s (attempt %d)" % [request.url, attempt])
	var err := client.request(HTTPClient.METHOD_GET, request.url, request.headers)
	
	# ---- request failed ? ----
	if err == ERR_INVALID_PARAMETER:
		if attempt >= request.max_attempts:
			_finish_with_error(request, "max reconnect attempts")
			return
		await _reconnect()
		_perform_request(request, attempt + 1)
		return
	if err != OK:
		_finish_with_error(request, "request error %s" % err)
		return
	
	# ---- wait for response (with timeout) ----
	var start := Time.get_ticks_msec()
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		if Time.get_ticks_msec() - start > 8000:
			_finish_with_error(request, "timeout while requesting")
			return
		client.poll()
		await get_tree().process_frame
	
	# ---- NO RESPONSE ? (server closed connection or 204) ----
	if not client.has_response():
		if attempt >= request.max_attempts:
			_finish_with_error(request, "no response (even after retry)")
			return
		print("[ServerAPI] No response – retrying after reconnect...")
		await _reconnect()
		_perform_request(request, attempt + 1)
		return
	
	if client.get_status() != HTTPClient.STATUS_BODY:
		_finish_with_error(request, "expected BODY, got %s" % client.get_status())
		return
	
	# ---- read body ----
	var body := PackedByteArray()
	while client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()
		var chunk := client.read_response_body_chunk()
		if chunk.size() > 0:
			body.append_array(chunk)
		await get_tree().process_frame
	
	
	while client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()
		await get_tree().process_frame
	
	assert(client.get_status() == HTTPClient.STATUS_CONNECTED, "client not idle")
	
	# ---- parse ----
	request.parse_method.call(request, body)


func _reconnect() -> void:
	print("[ServerAPI] Reconnecting...")
	client.close()
	await _connect()


func _parse_tile_data(request: RequestData, body: PackedByteArray) -> void:
	var tile: MvtTile = null
	if body.size() > 0:
		tile = MvtTile.read(body)
		if tile == null:
			_finish_with_error(request, "MvtTile.read() returned null")
			return
	_finish_with_success(request, tile)


func _finish_with_success(request: RequestData, parsed_data) -> void:
	busy = false
	print("[ServerAPI] ← data %s OK")
	request.received_signal.emit(request.initial_data, parsed_data)


func _finish_with_error(request: RequestData, message: String) -> void:
	busy = false
	push_warning("[ServerAPI] ← data FAILED: %s: $s" % [message, request.url])
	request.failed_signal.emit(request.initial_data, message)
