class_name TileAPI extends Node

signal server_connected
signal tile_received(tile_pos: Vector2i, tile: MvtTile)
signal tile_failed(tile_pos: Vector2i, error: String)

var client: HTTPClient
var queue: Array[Vector2i] = []
var busy := false
var host: String
var port: int

# ------------------------------------------------------------------
func _ready() -> void:
	host = Util.server_conf.get_value("NETWORK", "SERVER_ADDRESS")
	port = Util.server_conf.get_value("NETWORK", "SERVER_PORT")
	await _connect()
	server_connected.emit()
	set_process(true)

# ------------------------------------------------------------------
func _connect() -> void:
	client = HTTPClient.new()
	var err = client.connect_to_host(host, port)
	assert(err == OK, "connect_to_host() failed")
	
	while client.get_status() in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING]:
		client.poll()
		await get_tree().process_frame
	
	assert(client.get_status() == HTTPClient.STATUS_CONNECTED, "Connection failed")
	print("[TileAPI] Connected to %s:%s" % [host, port])

# ------------------------------------------------------------------
func request_tile_data(tile_pos: Vector2i) -> void:
	if queue.has(tile_pos):
		return
	queue.append(tile_pos)

# ------------------------------------------------------------------
func _process(_delta: float) -> void:
	if busy or queue.is_empty():
		return
	busy = true
	var pos = queue.pop_front()
	_perform_request(pos, 1)

# ------------------------------------------------------------------
func _perform_request(tile_pos: Vector2i, attempt: int) -> void:
	# ---- 1. make sure we are connected ----
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		print("[TileAPI] Status not CONNECTED (%s) – reconnecting..." % client.get_status())
		await _reconnect()
	
	var url := "/tile-data?x=%d&y=%d" % [tile_pos.x, tile_pos.y]
	var headers := [
		"Content-Type: application/x-protobuf",
		"Connection: keep-alive"
	]
	
	print("[TileAPI] → GET %s (attempt %d)" % [url, attempt])
	var err := client.request(HTTPClient.METHOD_GET, url, headers)
	
	# ---- request() failed → probably dead socket ----
	if err == ERR_INVALID_PARAMETER:
		if attempt >= 3:
			_finish(tile_pos, "max reconnect attempts")
			return
		await _reconnect()
		_perform_request(tile_pos, attempt + 1)
		return
	if err != OK:
		_finish(tile_pos, "request error %s" % err)
		return
	
	# ---- wait for response (with timeout) ----
	var start := Time.get_ticks_msec()
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		if Time.get_ticks_msec() - start > 8000:
			_finish(tile_pos, "timeout while requesting")
			return
		client.poll()
		await get_tree().process_frame
	
	# ---- NO RESPONSE ? (server closed connection or 204) ----
	if not client.has_response():
		# Try ONE reconnect – sometimes the server just dropped us
		if attempt == 1:
			print("[TileAPI] No response – retrying after reconnect...")
			await _reconnect()
			_perform_request(tile_pos, 2)
			return
		_finish(tile_pos, "no response (even after retry)")
		return
	
	if client.get_status() != HTTPClient.STATUS_BODY:
		_finish(tile_pos, "expected BODY, got %s" % client.get_status())
		return
	
	# ---- read body ----
	var body := PackedByteArray()
	while client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()
		var chunk := client.read_response_body_chunk()
		if chunk.size() > 0:
			body.append_array(chunk)
		await get_tree().process_frame
	
	# ---- drain final BODY state (critical!) ----
	while client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()
		await get_tree().process_frame
	
	assert(client.get_status() == HTTPClient.STATUS_CONNECTED, "client not idle")
	
	# ---- parse ----
	var tile: MvtTile = null
	if body.size() > 0:
		tile = MvtTile.read(body)
		if tile == null:
			_finish(tile_pos, "MvtTile.read() returned null")
			return
	
	_finish(tile_pos, "", tile)

# ------------------------------------------------------------------
func _reconnect() -> void:
	print("[TileAPI] Reconnecting...")
	client.close()
	await _connect()

# ------------------------------------------------------------------
func _finish(tile_pos: Vector2i, msg: String, tile: MvtTile = null) -> void:
	busy = false
	if tile:
		print("[TileAPI] ← tile %s OK" % tile_pos)
		tile_received.emit(tile_pos, tile)
	else:
		push_warning("[TileAPI] ← tile %s FAILED: %s" % [tile_pos, msg])
		tile_failed.emit(tile_pos, msg)
