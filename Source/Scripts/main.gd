class_name GameManager extends Node2D

signal player_coords_updated(new_coords: GeoCoordinate, old_coords: GeoCoordinate)

@export var map_renderer: MapRenderer
@export var android_gps: AndroidGPSWrapper
@export var server_api: ServerAPI
@export var player: Player
@export var loadingScreen: Control 

const MVT = preload("res://addons/geo-tile-loader/vector_tile_loader.gd")

var player_coords := GeoCoordinate.new()
var _tasks_loading: int = 0

func _ready() -> void:
	if loadingScreen:
		loadingScreen.visible = true
	
	player.update_level.connect($CanvasLayer/PlayerHUD._on_level_changed)
	player.update_xp.connect($CanvasLayer/PlayerHUD._on_xp_changed)
	player.update_hp.connect($CanvasLayer/PlayerHUD._on_hp_changed)
	
	$CanvasLayer/PlayerHUD._on_level_changed(player.level)
	$CanvasLayer/PlayerHUD._on_xp_changed(player.xp, player.max_xp)
	$CanvasLayer/PlayerHUD._on_hp_changed(player.hp, player.max_hp)

	set_process(false)
	Util.dummies = $Dummies
	android_gps.cooridnates_fetched.connect(_on_cooridnates_fetched)
	
	server_api.tile_received.connect(_on_loading_task_finished.unbind(2))
	server_api.city_poi_received.connect(_on_loading_task_finished.unbind(2))
	server_api.city_enemies_received.connect(_on_loading_task_finished.unbind(2))
	
	if android_gps.is_listening_for_geolocation_updates():
		await android_gps.cooridnates_updated
		Util.world_lat_offset = player_coords._lat_to_mercator(player_coords.latitude)
		Util.world_lon_offset = player_coords.longitude
	else:
		_on_cooridnates_fetched({"latitude": 43.224945591106234, "longitude": -79.88860876481552})
		Util.world_lat_offset = player_coords._lat_to_mercator(player_coords.latitude)
		Util.world_lon_offset = player_coords.longitude
	
	player.position = player_coords.game_position
	var new_dummy = Util.spawn_new_dummy(GeoCoordinate.new(43.224945591106234, -79.88860876481552).game_position)
	new_dummy.name = "My Super Cool House"
	new_dummy.bottom_label.text = "My Super Cool House"
	
	var coolerHouse = Util.spawn_new_dummy(GeoCoordinate.new(43.211297, -79.891929).game_position)
	coolerHouse.name = "My Even Cooler Super Cool House"
	coolerHouse.bottom_label.text = "My Even Cooler Super Cool House"
	
	if server_api.client.get_status() != HTTPClient.STATUS_CONNECTED: 
		await server_api.server_connected
	
	_tasks_loading += 9
	map_renderer.update_3x3_tile_render(player_coords.get_tile_position())
	_tasks_loading += 3
	map_renderer.queue_render_pois("Hamilton,Ontario")
	_tasks_loading += 1
	server_api.request_enemy_data("Hamilton, Ontario")

func _process(_delta: float) -> void:
	if Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") != Vector2.ZERO:
		var movement: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * 0.003 * _delta
		_on_cooridnates_fetched({"latitude": player_coords.latitude - movement.y, "longitude": player_coords.longitude + movement.x})
	


func _on_cooridnates_fetched(location_dictionary: Dictionary) -> void:
	var old_coords := GeoCoordinate.new(player_coords.latitude, player_coords.longitude)
	
	var latitude: float = location_dictionary["latitude"]
	var longitude: float = location_dictionary["longitude"]
	player_coords.latitude = latitude
	player_coords.longitude = longitude
	
	player_coords_updated.emit(player_coords, old_coords)
	
	if old_coords.get_tile_position() != player_coords.get_tile_position():
		map_renderer.update_3x3_tile_render(player_coords.get_tile_position())


func _on_loading_task_finished() -> void:
	_tasks_loading -= 1
	if _tasks_loading <= 0:
		if loadingScreen:
			loadingScreen.visible = false
		set_process(true) 
		
		server_api.tile_received.disconnect(_on_loading_task_finished.unbind(2))
		server_api.city_poi_received.disconnect(_on_loading_task_finished.unbind(2))
		server_api.city_enemies_received.disconnect(_on_loading_task_finished.unbind(2))
