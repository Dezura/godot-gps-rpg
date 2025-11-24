class_name EnemyManager extends Node2D

@export var game: GameManager
@export var server_api: ServerAPI



func _ready() -> void:
	server_api.city_enemies_received.connect(_on_city_enemies_received)
	server_api.city_enemies_failed.connect(_on_city_enemies_failed)


func fetch_enemy_data(city_name: String):
	server_api.request_enemy_data(city_name)


func _on_city_enemies_received(city_name: String, enemy_data: Dictionary[Vector2i, EnemyTileData]) -> void:
	print("Mna grihguoierhgiuoreh uoieawrtjgioerwn,hb oiuermjhgboirewhbiowerjbnh ioer")


func _on_city_enemies_failed(city_name: String, msg: String) -> void:
	push_warning("Enemies failed to fetch... (%s) (%s)" % [city_name, msg])
	fetch_enemy_data(city_name)
