class_name GeoCoordinate

var latitude: float
var longitude: float
var game_position: Vector2:
	get:
		# Convert latitude to Mercator projection for y-coordinate
		var mercator_y = _lat_to_mercator(latitude)
		# Apply scaling and offsets for game world coordinates
		return Vector2(longitude - Util.world_lon_offset, -mercator_y + Util.world_lat_offset) * Util.WORLD_SCALE
	set(new_value):
		# Reverse scaling and offsets
		var scaled_x = new_value.x / Util.WORLD_SCALE
		var scaled_y = new_value.y / Util.WORLD_SCALE
		# Convert x back to longitude
		longitude = scaled_x + Util.world_lon_offset
		# Convert y back to latitude from Mercator
		var mercator_y = -scaled_y + Util.world_lat_offset
		latitude = _mercator_to_lat(mercator_y)


func _init(lat: float = 0.0, lon: float = 0.0):
	latitude = lat
	longitude = lon


func get_tile_position() -> Vector2i:
	return Util.latlon_to_tile_xy(latitude, longitude, Util.TILE_LEVEL)


func get_tile_offset() -> Vector2:
	return Util.get_latlon_tile_offset(latitude, longitude, Util.TILE_LEVEL)


func _lat_to_mercator(lat: float) -> float:
	# Convert latitude to radians and apply Mercator projection
	var lat_rad = deg_to_rad(lat)
	var mercator_y = log(tan(PI / 4.0 + lat_rad / 2.0)) * 180.0 / PI
	return mercator_y


func _mercator_to_lat(mercator_y: float) -> float:
	# Reverse Mercator projection to get latitude in degrees
	var lat_rad = 2.0 * atan(exp(mercator_y * PI / 180.0)) - PI / 2.0
	return rad_to_deg(lat_rad)
