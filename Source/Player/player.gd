class_name Player extends Node2D

@export var game: GameManager
@export var interaction_radius: float = 75.0


func _ready() -> void:
	game.player_coords_updated.connect(_on_player_coords_updated)
	queue_redraw()


func _process(_delta: float) -> void:
	position = position.lerp(game.player_coords.game_position, 0.05)
	

func _draw() -> void:
	draw_arc(Vector2.ZERO, interaction_radius, 0, TAU, 64, Color.GREEN, 2.0)


func _on_player_coords_updated(new_coords: GeoCoordinate, _old_coords: GeoCoordinate) -> void:
	$DebugGPSCoords.text = "Latitude: %s\nLongitude: %s\nPos X: %s\nPos Y: %s" % [new_coords.latitude, new_coords.longitude, new_coords.game_position.x, new_coords.game_position.y]
	
	var tile_position: Vector2i = new_coords.get_tile_position()
	var tile_offset: Vector2 = new_coords.get_tile_offset()
	$DebugTileCoords.text = "Tile X: %s\nTile Y: %s\nTileOffset X: %s\nTileOffset Y: %s\nZoom Level: %s" % [tile_position.x, tile_position.y, tile_offset.x, tile_offset.y, Util.TILE_LEVEL]
