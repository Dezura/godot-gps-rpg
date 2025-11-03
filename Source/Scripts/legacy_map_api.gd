class_name LegacyMapAPI extends HTTPRequest

signal tile_data_fetched(data)
signal points_of_interest_fetched(json_data)

var server_address: String


func _ready() -> void:
	request_completed.connect(_on_request_completed)
	
	server_address = Util.server_conf.get_value("NETWORK", "SERVER_ADDRESS")


func request_points_of_interest(geo_position: GeoCoordinate, radius: float, amount: int) -> void:
	var request_string: String = "http://%s/radius?" % server_address
	request_string += "long1=" + str(geo_position.longitude)
	request_string += "&lat1=" + str(geo_position.latitude)
	request_string += "&radius=" + str(radius)
	request_string += "&limit=" + str(amount)
	
	print(request_string)
	var error = request(request_string)
	if error != OK:
		push_error("An error occurred in the HTTP request.")


func request_tile_data(tile_x: int, tile_y: int) -> void:
	var request_string: String = "http://%s/tile-data?" % server_address
	request_string += "x=" + str(tile_x)
	request_string += "&y=" + str(tile_y)
	
	print(request_string)
	var error = request(request_string)
	if error != OK:
		push_error("An error occurred in the HTTP request.")


func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("[%s : %s]" % [result, response_code])
	print(headers)
	print("=========")
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if json != null:
		for place in json["features"]:
			continue
			if not place["properties"].has("name"):
				continue
			print("============ New Place =============")
			print("name: " + str(place["properties"]["name"]))
			print("categories: " + str(place["properties"]["categories"]))
			print("formatted: " + str(place["properties"]["formatted"]))
			print("distance: " + str(place["properties"]["distance"]))
			print("lat: " + str(place["properties"]["lat"]))
			print("lon: " + str(place["properties"]["lon"]))
			print("====================================")
		points_of_interest_fetched.emit(json["features"])
	else:
		tile_data_fetched.emit(json)
