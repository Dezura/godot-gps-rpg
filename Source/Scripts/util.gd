extends Node
# Autoload Singleton Script, can be used globally anywhere

const WORLD_SCALE: float = 100000
const TILE_LEVEL: int = 14

var server_conf = ConfigFile.new()

var dummy_prefab = preload("res://Source/Prefabs/dummy.tscn")
var dummies: Node2D

var world_lat_offset: float
var world_lon_offset: float



func _ready() -> void:
	if server_conf.load("res://server.cfg") == Error.OK:
		if not server_conf.has_section_key("NETWORK", "SERVER_ADDRESS"):
			printerr("Invalid server.cfg detected! Please add a valid SERVER_ADDRESS key under [NETWORK]")
	else:
		printerr("No server.cfg detected! Please create a new cfg on root.")
	
	#dummies = get_tree().current_scene.find_child("Dummies")


func spawn_new_dummy(pos: Vector2) -> Dummy:
	var new_dummy: Dummy = dummy_prefab.instantiate()
	new_dummy.global_position = pos
	dummies.add_child(new_dummy)
	return new_dummy


#region Vector Tile Stuff
func parse_feature_geometry_points(feature_geometry: Array, include_closepath_point = false) -> Array[PackedVector2Array]:
	var shapes: Array[PackedVector2Array]
	var current_points: PackedVector2Array
	var pen_position := Vector2.ZERO
	
	for instructions: Array in feature_geometry:
		var command_id = instructions[0]
		
		match command_id:
			1: # MoveTo command
				if not current_points.is_empty():
					shapes.append(current_points)
					current_points = []
				var delta = Vector2(instructions[1], instructions[2])
				
				pen_position += delta
				current_points.append(pen_position)
			2: # LineTo command
				var pair_count: int = (instructions.size() - 1) / 2
				for i in range(pair_count):
					var pair_index: int = (i * 2) + 1
					var delta := Vector2(instructions[pair_index], instructions[pair_index+1])
					
					pen_position += delta
					current_points.append(pen_position)
			7: # ClosePath command
				if include_closepath_point:
					current_points.append(current_points[0])
				
				shapes.append(current_points)
				current_points = []
	if not current_points.is_empty():
		shapes.append(current_points)
		current_points = []
	
	return shapes


func generate_tile_debug_files(tile: MvtTile):
	for layer: MvtLayer in tile.layers():
		var file := FileAccess.open("res://Assets/Testing Data/Tile Data/tile-data-" + layer.name() + ".txt", FileAccess.WRITE)
		var output_data: String = ""
		output_data += "Hi!!!!! " + layer.name() + "\n\n"
		
		for feature: MvtFeature in layer.features():
			output_data += "\n\n=====================\n"
			
			var tags: Dictionary = feature.tags(layer)
			for tag in tags:
				output_data += "%s: %s\n" % [tag, tags[tag]]
			
			output_data += "\nID: " + var_to_str(feature.id())
			
			output_data += "\n====== Geometry"
			for thing: Array in feature.geometry():
				output_data += "\n["
				for other_thing: int in thing:
					output_data += var_to_str(other_thing) + ", "
				output_data += "]"
		
		file.store_string(output_data)
		file.close()
#endregion


#region Longitude Latitude Stuff
func latlon_to_tile_xy(latitude: float, longitude: float, zoom_level := TILE_LEVEL) -> Vector2i:
	var clamped_lat = clamp(latitude, -85.05112878, 85.05112878)
	var lat_rad = deg_to_rad(clamped_lat)
	var n = pow(2.0, zoom_level)
	
	var x_tile = (longitude + 180.0) / 360.0 * n
	var y_tile = (1.0 - log(tan(lat_rad) + 1.0 / cos(lat_rad)) / PI) / 2.0 * n
	
	return Vector2i(int(x_tile), int(y_tile))


func get_latlon_tile_offset(lat: float, lon: float, zoom := TILE_LEVEL) -> Vector2:
	var clamped_lat = clamp(lat, -85.05112878, 85.05112878)
	var lat_rad = deg_to_rad(clamped_lat)
	var n = pow(2.0, zoom)
	
	var x_tile_exact = (lon + 180.0) / 360.0 * n
	var y_tile_exact = (1.0 - log(tan(lat_rad) + 1.0 / cos(lat_rad)) / PI) / 2.0 * n
	
	# Get integer tile index
	var tile_x = int(x_tile_exact)
	var tile_y = int(y_tile_exact)
	
	# Get offset within the tile (0.0–1.0 range)
	var offset_x = x_tile_exact - tile_x
	var offset_y = y_tile_exact - tile_y
	
	return Vector2(offset_x-0.5, offset_y-0.5)


func get_tile_center_position(x_tile: int, y_tile: int, zoom := TILE_LEVEL) -> GeoCoordinate:
	var n = pow(2.0, zoom)
	
	# Add 0.5 to get the tile’s center
	var lon = (x_tile + 0.5) / n * 360.0 - 180.0
	var lat_rad = atan(sinh(PI * (1.0 - 2.0 * (y_tile + 0.5) / n)))
	var lat = rad_to_deg(lat_rad)
	
	return GeoCoordinate.new(lat, lon)


func get_tile_unit_scale(zoom_level: int = TILE_LEVEL, extent: int = 4096) -> float:
	var tiles_per_world = pow(2, zoom_level)
	var tile_size_degrees = 360.0 / tiles_per_world
	var tile_size_game_units = tile_size_degrees * WORLD_SCALE
	return tile_size_game_units / extent
#endregion
