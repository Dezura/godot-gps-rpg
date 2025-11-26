class_name ServerAPI extends Node

signal server_connected
signal tile_received(tile_pos: Vector2i, tile: MvtTile)
signal tile_failed(tile_pos: Vector2i, message: String)
signal city_poi_received(city_name: String, poi_list: Array[PointOfInterestData])
signal city_poi_failed(city_name: String, message: String)
signal city_tiles_received(city_name: String, tiles: Dictionary[Vector2i, MvtTile])
signal city_tiles_failed(city_name: String, message: String)
signal city_enemies_received(city_name: String, enemy_data: Dictionary[Vector2i, EnemyTileData])
signal city_enemies_failed(city_name: String, message: String)


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
	client.connect_to_host(host, port)
	
	while client.get_status() in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING]:
		print("[ServerAPI] Connecting to server... %s:%s" % [host, port])
		client.poll()
		await get_tree().process_frame
	
	print("[ServerAPI] Connected to %s:%s" % [host, port])


func request_tile_data(tile_pos: Vector2i) -> void:
	var new_request := RequestData.new()
	
	new_request.url = "/tile-data?x=%d&y=%d" % [tile_pos.x, tile_pos.y]
	for i in _request_queue.size():
		if _request_queue[i].url == new_request.url:
			return
	new_request.headers = [
		"Content-Type: application/x-protobuf",
		"Connection: keep-alive"
	]
	new_request.initial_data = tile_pos
	new_request.parse_method = _parse_tile_data
	new_request.received_signal = tile_received
	new_request.failed_signal = tile_failed
	_request_queue.append(new_request)
	print("[ServerAPI] New request added to queue (%s)" % _request_queue.size())


func request_poi_data(city: String, category: String) -> void:
	var new_request := RequestData.new()
	
	new_request.url = "/name?place=%s&categories=%s" % [city, category]
	for i in _request_queue.size():
		if _request_queue[i].url == new_request.url:
			return
	new_request.headers = [
		"Content-Type: application/json",
		"Connection: keep-alive"
	]
	new_request.initial_data = city
	new_request.parse_method = _parse_city_pois
	new_request.received_signal = city_poi_received
	new_request.failed_signal = city_poi_failed
	_request_queue.append(new_request)
	print("[ServerAPI] New request added to queue (%s)" % _request_queue.size())

func request_enemy_data(city: String, force_refresh := false, tux_mode := false) -> void:
	var new_request := RequestData.new()
	
	new_request.url = "/enemy-tile?place=%s&forceRefresh=%s&tuxMode=%s" % [city.uri_encode(), force_refresh, tux_mode]
	for i in _request_queue.size():
		if _request_queue[i].url == new_request.url:
			return
	new_request.headers = [
		"Content-Type: application/json",
		"Connection: keep-alive"
	]
	new_request.initial_data = city
	new_request.parse_method = _parse_enemy_data
	new_request.received_signal = city_enemies_received
	new_request.failed_signal = city_enemies_failed
	
	_request_queue.append(new_request)
	print("[ServerAPI] enemy request added to queue (%s)" % _request_queue.size())


func _process(_delta: float) -> void:
	if busy or _request_queue.is_empty():
		return
	busy = true
	var next_request = _request_queue.pop_front()
	_perform_request(next_request, 1)


func _perform_request(request: RequestData, attempt: int) -> void:
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		print("[ServerAPI] NOT CONNECTED to server (Status: %s)" % client.get_status())
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
		if Time.get_ticks_msec() - start > 25000:
			_finish_with_error(request, "timeout while requesting")
			return
		client.poll()
		await get_tree().process_frame
	
	# ---- no response (server closed connection or 204) ----
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
	
	
	# ---- parse ----
	if body.size() > 0:
		request.parse_method.call(request, body)
	else:
		_finish_with_error(request, "HTTP body returned empty")


func _reconnect() -> void:
	print("[ServerAPI] Reconnecting...")
	client.close()
	await _connect()


func _parse_tile_data(request: RequestData, body: PackedByteArray) -> void:
	var tile := MvtTile.read(body)
	if tile == null:
		_finish_with_error(request, "MvtTile.read() returned null")
		return
	_finish_with_success(request, tile)


func _parse_enemy_data(request: RequestData, body: PackedByteArray) -> void:
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		_finish_with_error(request, "no enemy data")
		return
	
	# This code is honestly a bit of a mess now but i dont really care
	var enemy_tiles: Dictionary[Vector2i, EnemyTileData]
	for key in json:
		var tile_pos := Vector2i(json[key].tileX, json[key].tileY)
		var extent: int = json[key].extent
		var expiry: int = json[key].expiryTime
		
		var enemy_list: Array[EnemyTileData.EnemyData]
		for enemy_dict in json[key].enemies:
			var enemy = EnemyTileData.EnemyData.new()
			enemy.id = enemy_dict.id
			enemy.type = enemy_dict.enemyType
			enemy.local_pos = Vector2i(enemy_dict.x, enemy_dict.y)
			enemy_list.append(enemy)
		
		enemy_tiles[tile_pos] = EnemyTileData.new(tile_pos, extent, expiry, enemy_list)
	
	print("[ServerAPI] SUCCESS: Fetched fresh enemies for %s." % request.initial_data)
	_finish_with_success(request, enemy_tiles)


func _parse_city_pois(request: RequestData, body: PackedByteArray) -> void:
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		_finish_with_error(request, "POI json.parse_string() returned null")
		return
	
	var poi_list: Array[PointOfInterestData] = []
	for place in json.features:
		var props = place.get("properties", {})
		
		var new_poi := PointOfInterestData.new(
			props.get("place_id", "uid_missing"),
			props.get("name", "Unnamed POI"), 
			GeoCoordinate.new(props.get("lat", 0.0), props.get("lon", 0.0)),
			props.get("categories", [])
		)
		poi_list.append(new_poi)
		
	_finish_with_success(request, poi_list)


func _finish_with_success(request: RequestData, parsed_data) -> void:
	busy = false
	print("[ServerAPI] ← data %s OK" % request.url)
	request.received_signal.emit(request.initial_data, parsed_data)


func _finish_with_error(request: RequestData, message: String) -> void:
	busy = false
	print("[ServerAPI] ← data FAILED: %s: %s" % [message, request.url])
	push_warning("[ServerAPI] ← data FAILED: %s: %s" % [message, request.url])
	request.failed_signal.emit(request.initial_data, message)
	
