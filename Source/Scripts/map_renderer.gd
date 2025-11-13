class_name MapRenderer extends Node2D

var _rendered_map_tiles: Array[Vector2i]

@export var game: GameManager
@export var server_api: ServerAPI
const MVT = preload("res://addons/geo-tile-loader/vector_tile_loader.gd")

@export var texture_test: Texture

func _ready() -> void:
	server_api.tile_received.connect(_on_tile_received)
	server_api.tile_failed.connect(_on_tile_failed)


func queue_render_tile(tile_pos: Vector2i) -> void:
	if is_tile_rendered(tile_pos): 
		return
	server_api.request_tile_data(tile_pos)
	_rendered_map_tiles.append(Vector2i(tile_pos.x, tile_pos.y))


func is_tile_rendered(tile_pos: Vector2i) -> bool:
	return _rendered_map_tiles.has(tile_pos)


func _on_tile_received(tile_pos: Vector2i, tile: MvtTile) -> void:
	_render_tile(tile_pos, tile)
	print("Rendered %s" % tile_pos)


func _on_tile_failed(tile_pos: Vector2i, msg: String) -> void:
	push_warning("A tile failed to fetch... (%s) (%s)", tile_pos, msg)


func _render_tile(tile_pos: Vector2i, tile: MvtTile) -> void:
	var new_chunk := Node2D.new()
	new_chunk.name = "newChunk"
	add_child(new_chunk)
	new_chunk.global_position = Util.get_tile_center_position(tile_pos.x, tile_pos.y).game_position
	var test := Sprite2D.new()
	test.texture = texture_test
	new_chunk.add_child(test)
	
	#Util.generate_tile_debug_files(tile)
	for layer: MvtLayer in tile.layers():
		match layer.name():
			"transportation":
				_render_layer_linestrings(layer, new_chunk, Color(0.363, 0.377, 0.49, 1.0), 8)
			"pathway":
				_render_layer_linestrings(layer, new_chunk, Color(0.363, 0.377, 0.49, 1.0), 5)
			
			
			#"commercial":
				#_render_layer_polygons(layer, new_chunk, Color(0.707, 0.42, 0.0, 0.5))
			#"education", "industrial", "leisure", "construction":
				#_render_layer_polygons(layer, new_chunk, Color(0.861, 0.198, 0.407, 0.5))
			
			
			"landcover":
				_render_layer_polygons(layer, new_chunk, Color(0.639, 0.88, 0.158, 0.361), "park")
			
			"water":
				_render_layer_polygons(layer, new_chunk, Color(0.495, 0.471, 1.892, 0.69))
			"building":
				_render_layer_polygons(layer, new_chunk, Color(0.154, 0.163, 0.23, 1.0))
			_:
				pass
				print(layer.name())
				if layer.name().begins_with("poi") and not layer.name() in ["poi_station", "poi_transport"]:
					_render_pois(layer, new_chunk)


func _render_pois(layer: MvtLayer, parent: Node2D) -> void:
	for feature: MvtFeature in layer.features():
		if not feature.tags(layer).has("name"):
			continue
		var points = feature.geometry()
		
		for point: Array in points:
			var layer_extent = layer.extent()
			var new_point = Vector2(point[1], point[2])
			new_point -= Vector2(layer_extent/2.0, layer_extent/2.0)
			new_point *= Util.get_tile_unit_scale()
			
			var new_dummy: Dummy = Util.dummy_prefab.instantiate()
			parent.add_child(new_dummy)
			new_dummy.position = new_point
			new_dummy.name = feature.tags(layer)["name"]
			new_dummy.name_label.text = feature.tags(layer)["name"]


func _render_layer_polygons(layer: MvtLayer, parent: Node2D, color: Color, target_subclass: String = "") -> void:
	for feature: MvtFeature in layer.features():
		if target_subclass != "":
			if feature.tags(layer).has("subclass"):
				if feature.tags(layer)["subclass"] != target_subclass:
					return
		var polygons = Util.parse_feature_geometry_points(feature.geometry())
		
		for polygon: PackedVector2Array in polygons:
			var new_polygon := Polygon2D.new()
			parent.add_child(new_polygon)
			
			new_polygon.color = color
			var new_data: PackedVector2Array = []
			
			for point in polygon:
				var layer_extent = layer.extent()
				var world_point := point
				world_point -= Vector2(layer_extent/2.0, layer_extent/2.0)
				world_point *= Util.get_tile_unit_scale()
				
				new_data.append(world_point)
			new_polygon.polygon = new_data


func _render_layer_linestrings(layer: MvtLayer, parent: Node2D, color: Color, line_width: float) -> void:
	for feature: MvtFeature in layer.features():
		var paths =  Util.parse_feature_geometry_points(feature.geometry())
		
		for path: PackedVector2Array in paths:
			var new_line := Line2D.new()
			parent.add_child(new_line)
			new_line.width = line_width
			new_line.default_color = color
			if feature.tags(layer).has("name"):
				new_line.name = feature.tags(layer)["name"]
			for point in path:
				var layer_extent = layer.extent()
				var world_point := point
				world_point -= Vector2(layer_extent/2.0, layer_extent/2.0)
				world_point *= Util.get_tile_unit_scale()
				
				new_line.add_point(world_point)
