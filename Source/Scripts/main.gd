class_name GameManager extends Node2D

signal player_coords_updated(new_coords: GeoCoordinate, old_coords: GeoCoordinate)

@export var map_renderer: MapRenderer
@export var android_gps: AndroidGPSWrapper
@export var server_api: ServerAPI
@export var player: Player
const MVT = preload("res://addons/geo-tile-loader/vector_tile_loader.gd")

var player_coords := GeoCoordinate.new()


func _ready() -> void:
	
	var pauseButton = $CanvasLayer/PlayerHUD/PauseButton
	pauseButton.pressed.connect($CanvasLayer/PauseMenu.open_menu)

	set_process(false)
	android_gps.cooridnates_fetched.connect(_on_cooridnates_fetched)
	
	if android_gps.is_listening_for_geolocation_updates():
		await android_gps.cooridnates_updated
		Util.world_lat_offset = player_coords._lat_to_mercator(player_coords.latitude)
		Util.world_lon_offset = player_coords.longitude
	else:
		_on_cooridnates_fetched({"latitude": 43.224945591106234, "longitude": -79.88860876481552})
		Util.world_lat_offset = player_coords._lat_to_mercator(player_coords.latitude)
		Util.world_lon_offset = player_coords.longitude
	player.position = player_coords.game_position
	print(player_coords.get_tile_position())
	var new_dummy = Util.spawn_new_dummy(GeoCoordinate.new(43.224945591106234, -79.88860876481552).game_position)
	new_dummy.name = "My Super Cool House"
	new_dummy.bottom_label.text = "My Super Cool House"
	
	var coolerHouse = Util.spawn_new_dummy(GeoCoordinate.new(43.211297, -79.891929).game_position)
	coolerHouse.name = "My Even Cooler Super Cool House"
	coolerHouse.bottom_label.text = "My Even Cooler Super Cool House"
	
	#tile_api.request_points_of_interest(player_coords, 100, 100)
	#tile_api.request_points_of_interest(player_coords, 100, 100)
	#map.queue_render_tile(player_coords.get_tile_position())
	
	if server_api.client.get_status() != HTTPClient.STATUS_CONNECTED: 
		await server_api.server_connected
	
	map_renderer.queue_render_tile(player_coords.get_tile_position())
	map_renderer.queue_render_pois("Hamilton,Ontario")
	
	set_process(true)
	

func _process(_delta: float) -> void:
	if Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") != Vector2.ZERO:
		var movement: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * 0.003 * _delta
		
		_on_cooridnates_fetched({"latitude": player_coords.latitude - movement.y, "longitude": player_coords.longitude + movement.x})
	if not map_renderer.is_tile_rendered(player_coords.get_tile_position()):
		map_renderer.queue_render_tile(player_coords.get_tile_position())


func _on_cooridnates_fetched(location_dictionary: Dictionary) -> void:
	var old_coords := GeoCoordinate.new(player_coords.latitude, player_coords.longitude)
	
	var latitude: float = location_dictionary["latitude"]
	var longitude: float = location_dictionary["longitude"]
	player_coords.latitude = latitude
	player_coords.longitude = longitude
	
	player_coords_updated.emit(player_coords, old_coords)
