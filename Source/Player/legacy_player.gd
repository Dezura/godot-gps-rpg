class_name LegacyPlayer extends Node2D
# These early scripts might be breaking a few design rules, but expect early commits to have a lot
# of placeholder logic for testing that will be restructured later

# For example, this player script really shouldn't be responsible for conducting all this POI logic

const MVT = preload("res://addons/geo-tile-loader/vector_tile_loader.gd")

@export var map: MapChunkManager
@export var android_gps: AndroidGPSWrapper
@export var map_api: MapAPI
@export var parent: Node2D

var initialized: bool = false
var geo_position: GeoCoordinate = GeoCoordinate.new()
var tracked_places: Array


func _ready() -> void:
	android_gps.cooridnates_updated.connect(_on_cooridnates_updated)
	map_api.points_of_interest_fetched.connect(_on_points_of_interest_fetched)
	
	if android_gps.is_listening_for_geolocation_updates():
		await android_gps.cooridnates_updated
		Util.world_lat_offset = geo_position.latitude
		Util.world_lon_offset = geo_position.longitude
	else:
		_on_cooridnates_updated({"latitude": 43.2251834, "longitude": -79.8849275688911})
		Util.world_lat_offset = geo_position.latitude
		Util.world_lon_offset = geo_position.longitude
	
	position = geo_position.game_position
	#map_api.request_points_of_interest(geo_position, 1000, 100)
	
	var tile_path: String = "res://Assets/Testing Data/test_data" # tile-data.pbf
	var tile: MvtTile = MVT.load_tile(tile_path)
	
	var new_chunk := Node2D.new()
	new_chunk.name = "newChunk"
	parent.add_child(new_chunk)
	new_chunk.global_position = geo_position.game_position
	print(new_chunk.name)
	print(new_chunk.get_parent())
	
	for layer: MvtLayer in tile.layers():
		if layer.name() == "highways":
			print(layer.name())
			for feature: MvtFeature in layer.features():
				var paths = bullshit(feature.geometry())
				print(feature.geometry())
				print(paths)
				print("====")
				for path: Array[Vector2] in paths:
					var new_line := Line2D.new()
					new_chunk.add_child(new_line)
					new_line.width = 4
					new_line.position = Vector2.ZERO
					for point in path:
						new_line.add_point(point / 50.0)
	
	initialized = true


func _process(_delta: float) -> void:
	if Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") != Vector2.ZERO:
		var movement: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * 0.003 * _delta
		
		_on_cooridnates_updated({"latitude": geo_position.latitude - movement.y, "longitude": geo_position.longitude + movement.x})
	
	position = position.lerp(geo_position.game_position, 0.05)


func bullshit(feature_geometry: Array) -> Array[Array]:
	var paths: Array[Array]
	var current_path: Array[Vector2]
	
	for instructions: Array in feature_geometry:
		var command_id = instructions[0]
		
		match command_id:
			1: # MoveTo command
				if not current_path.is_empty():
					paths.append(current_path)
				# Start a new path
				current_path = []
				current_path.append(Vector2(instructions[1], instructions[2]))
			2: # LineTo command
				var pair_count: int = (instructions.size() - 1) / 2
				for i in pair_count:
					var pair_index: int = (i * 2) + 1
					var pair := Vector2(instructions[pair_index], instructions[pair_index+1])
					
					var previous_point: Vector2 = current_path[-1]
					current_path.append(previous_point + pair)
			7: # ClosePath command, 
				var first_point = current_path[0]
				current_path.append(first_point)
				
				paths.append(current_path)
				current_path = []
	if not current_path.is_empty():
		paths.append(current_path)
		current_path = []
	
	return paths


func _on_points_of_interest_fetched(places: Array) -> void:
	for place in places:
		if not place["properties"].has("name"):
			continue
		if tracked_places.has(place["properties"]["name"]):
			continue
		var place_lat: float = place["properties"]["lat"]
		var place_lon: float = place["properties"]["lon"]
		var new_coords: GeoCoordinate = GeoCoordinate.new(place_lat, place_lon)
		
		var new_dummy: Dummy = Util.spawn_new_dummy(new_coords.game_position)
		new_dummy.top_label.text = place["properties"]["name"]
		tracked_places.append(place["properties"]["name"])


func _on_cooridnates_updated(location_dictionary: Dictionary) -> void:
	var latitude: float = location_dictionary["latitude"]
	var longitude: float = location_dictionary["longitude"]
	geo_position.latitude = latitude
	geo_position.longitude = longitude
	
	
	$DebugGPSCoords.text = "Latitude: %s\nLongitude: %s\nPos X: %s\nPos Y: %s" % [latitude, longitude, geo_position.game_position.x, geo_position.game_position.y]
	
	var tile_position: Vector2i = Util.latlon_to_tile_xy(latitude, longitude, 14)
	var tile_offset: Vector2 = Util.get_latlon_tile_offset(latitude, longitude, 14)
	$DebugTileCoords.text = "Tile X: %s\nTile Y: %s\nTileOffset X: %s\nTileOffset Y: %s\nZoom Level: %s" % [tile_position.x, tile_position.y, tile_offset.x, tile_offset.y, 14]
	
	if !map.is_tile_loaded(tile_position.x, tile_position.y):
		#map_api.request_points_of_interest(geo_position, 1000, 100)
		map.load_tile(tile_position.x, tile_position.y)
		map.current_tile = tile_position
