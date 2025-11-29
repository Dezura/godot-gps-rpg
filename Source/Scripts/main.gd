class_name GameManager extends Node2D

signal player_coords_updated(new_coords: GeoCoordinate, old_coords: GeoCoordinate)
signal player_tile_changed(tile_pos: Vector2i, old_tile_pos: Vector2i)

@export var map_renderer: MapRenderer
@export var enemy_manager: EnemyManager
@export var android_gps: AndroidGPSWrapper
@export var server_api: ServerAPI
@export var player: Player
@export var loadingScreen: Control 
@export var websocket: WebSocketThingy 

const MVT = preload("res://addons/geo-tile-loader/vector_tile_loader.gd")

var current_city := "Hamilton,Ontario"
var player_coords := GeoCoordinate.new()
var _tasks_loading: int = 0

@export var position_track_timer: Timer
var is_tracking_pos := false
var tracked_players: Dictionary[String, NetplayerInstance]

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
	Util.game = self
	Util.dummies = $YSorter/Dummies
	Util.hud = $CanvasLayer/PlayerHUD
	enemy_manager.enemies_unloaded.connect(Util.hud.enemy_encounter_menu.force_close)
	Util.hud.enemy_fight_ui.game = self
	Util.hud.pvp_fight_ui.game = self
	Util.hud.pvp_fight_ui.websocket = websocket
	Util.hud.enemy_fight_ui.player = player
	Util.hud.pvp_fight_ui.player = player
	
	android_gps.cooridnates_fetched.connect(_on_cooridnates_fetched)
	
	server_api.tile_received.connect(_on_loading_task_finished.unbind(2))
	server_api.city_poi_received.connect(_on_loading_task_finished.unbind(2))
	server_api.city_enemies_received.connect(_on_loading_task_finished.unbind(2))
	position_track_timer.timeout.connect(_send_position_payload)
	
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
	map_renderer.queue_render_pois(current_city)
	_tasks_loading += 1
	enemy_manager.fetch_enemy_data(current_city)
	$CanvasLayer/LoadingScreen/ProgressBar.max_value = _tasks_loading
	
	$WebSocket.message_received.connect($CanvasLayer/PlayerHUD.add_chat_message)
	$CanvasLayer/PlayerHUD.chat_message_sent.connect($WebSocket.send_message)
	websocket.pvp_lobby_updated.connect(Util.hud.pvp_encounter_menu._on_pvp_lobby_updated)
	websocket.pvp_lobby_updated.connect(Util.hud.pvp_fight_ui._on_pvp_lobby_updated)
	
	player.update_level.connect($WebSocket.send_level_up_message)

func _process(_delta: float) -> void:
	if $CanvasLayer/PlayerHUD/PauseMenu.visible:
		return
	if $CanvasLayer/PlayerHUD/EnemyEncounter.visible:
		return
	
	if Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") != Vector2.ZERO:
		var movement: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * 0.003 * _delta
		_on_cooridnates_fetched({"latitude": player_coords.latitude - movement.y, "longitude": player_coords.longitude + movement.x})
	


func _send_position_payload() -> void:
	if not is_tracking_pos:
		return
	
	# client ID is sent by the server in a different payload for all clients
	var payload = {
		"type": "position_lobby_update",
		"update": "update",
		"name": websocket._username,
		"color": websocket._user_color,
		"lon": player_coords.longitude,
		"lat": player_coords.latitude,
		"level": player.level,
	}
	websocket._client.send_text(JSON.stringify(payload))

func _on_receive_pos_payload(payload) -> void:
	if not is_tracking_pos or payload.id == websocket._user_id:
		return
	match payload.update_type:
		"update":
			if not tracked_players.has(payload.id):
				var new_netplayer: NetplayerInstance = Util.netplayer_prefab.instantiate()
				$YSorter.add_child(new_netplayer)
				new_netplayer.init_netplayer(payload.lat, payload.lon, payload.name, payload.color, payload.level)
				tracked_players.set(payload.id, new_netplayer)
			else:
				tracked_players[payload.id].update_stats(payload.lat, payload.lon, payload.level)
		"disconnect":
			if tracked_players.has(payload.id):
				tracked_players[payload.id].queue_free()
				tracked_players.erase(payload.id)

func _on_cooridnates_fetched(location_dictionary: Dictionary) -> void:
	var old_coords := GeoCoordinate.new(player_coords.latitude, player_coords.longitude)
	
	var latitude: float = location_dictionary["latitude"]
	var longitude: float = location_dictionary["longitude"]
	player_coords.latitude = latitude
	player_coords.longitude = longitude
	
	player_coords_updated.emit(player_coords, old_coords)
	
	if old_coords.get_tile_position() != player_coords.get_tile_position():
		player_tile_changed.emit(player_coords.get_tile_position(), old_coords.get_tile_position())


func _on_loading_task_finished() -> void:
	_tasks_loading -= 1
	$CanvasLayer/LoadingScreen/ProgressBar.value += 1
	if _tasks_loading <= 0:
		if loadingScreen:
			loadingScreen.visible = false
		set_process(true) 
		
		server_api.tile_received.disconnect(_on_loading_task_finished.unbind(2))
		server_api.city_poi_received.disconnect(_on_loading_task_finished.unbind(2))
		server_api.city_enemies_received.disconnect(_on_loading_task_finished.unbind(2))
