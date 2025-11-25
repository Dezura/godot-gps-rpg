class_name EnemyManager extends Node2D

@export var game: GameManager
@export var server_api: ServerAPI

var _enemy_prefab := preload("res://Source/Prefabs/enemy.tscn")

var _enemy_tiles: Dictionary[Vector2i, EnemyTileData]
var _current_loaded_enemy_tiles: Dictionary[Vector2i, Node2D]


func _ready() -> void:
	game.player_tile_changed.connect(_on_player_tile_changed)
	server_api.city_enemies_received.connect(_on_city_enemies_received)
	server_api.city_enemies_failed.connect(_on_city_enemies_failed)


func fetch_enemy_data(city_name: String) -> void:
	server_api.request_enemy_data(city_name)


func load_enemy_tile(tile_pos: Vector2i) -> void:
	if not _enemy_tiles.has(tile_pos):
		print("NO ENEMY DATA FOR TILE ", tile_pos)
		return
	if _current_loaded_enemy_tiles.has(tile_pos):
		print("LOADED ENEMY TILE EXISTS ", tile_pos)
		return
	var new_chunk := Node2D.new()
	add_child(new_chunk)
	new_chunk.global_position = Util.get_tile_center_position(tile_pos.x, tile_pos.y).game_position
	
	for enemy_data: EnemyTileData.EnemyData in _enemy_tiles[tile_pos].enemies:
		var new_enemy: Enemy = _enemy_prefab.instantiate()
		new_chunk.add_child(new_enemy)
		new_enemy.id = enemy_data.id
		new_enemy.type = enemy_data.type
		
		var extent = _enemy_tiles[tile_pos].extent
		var converted_pos: Vector2 = enemy_data.local_pos
		converted_pos -= Vector2(extent/2.0, extent/2.0)
		converted_pos *= Util.get_tile_unit_scale()
		converted_pos += new_chunk.global_position
		new_enemy.global_position = converted_pos
	_current_loaded_enemy_tiles[tile_pos] = new_chunk


func _on_player_tile_changed(tile_pos: Vector2i, old_tile_pos: Vector2i) -> void:
	load_enemy_tile(tile_pos)


func _on_city_enemies_received(city_name: String, enemy_data: Dictionary[Vector2i, EnemyTileData]) -> void:
	print("Mna grihguoierhgiuoreh uoieawrtjgioerwn,hb oiuermjhgboirewhbiowerjbnh ioer")
	# Very informative print statement, I like it
	# RE: Im keeping this print in the final build cry about it
	
	for key in enemy_data:
		self._enemy_tiles[key] = enemy_data[key]


func _on_city_enemies_failed(city_name: String, msg: String) -> void:
	push_warning("Enemies failed to fetch... (%s) (%s)" % [city_name, msg])
	fetch_enemy_data(city_name)
