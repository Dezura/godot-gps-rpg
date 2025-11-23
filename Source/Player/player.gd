class_name Player extends Node2D

@export var game: GameManager
@onready var _anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	game.player_coords_updated.connect(_on_player_coords_updated)


func _process(_delta: float) -> void:
	if global_position != game.player_coords.game_position:
		global_position = global_position.lerp(game.player_coords.game_position, 0.05)
	
	# Stop lerping if we
	if abs(global_position.x - game.player_coords.game_position.x) < 0.1:
		global_position.x = game.player_coords.game_position.x
	if abs(global_position.y - game.player_coords.game_position.y) < 0.1:
		global_position.y = game.player_coords.game_position.y
	
	if global_position == game.player_coords.game_position:
		_anim_sprite.play("Idle")

func _on_player_coords_updated(new_coords: GeoCoordinate, old_coords: GeoCoordinate) -> void:
	$DebugGPSCoords.text = "Latitude: %s\nLongitude: %s\nPos X: %s\nPos Y: %s" % [new_coords.latitude, new_coords.longitude, new_coords.game_position.x, new_coords.game_position.y]
	
	var tile_position: Vector2i = new_coords.get_tile_position()
	var tile_offset: Vector2 = new_coords.get_tile_offset()
	$DebugTileCoords.text = "Tile X: %s\nTile Y: %s\nTileOffset X: %s\nTileOffset Y: %s\nZoom Level: %s" % [tile_position.x, tile_position.y, tile_offset.x, tile_offset.y, Util.TILE_LEVEL]
	
	_anim_sprite.play("Walk")
	if new_coords.game_position.x < old_coords.game_position.x:
		_anim_sprite.flip_h = true
	elif new_coords.game_position.x > old_coords.game_position.x:
		_anim_sprite.flip_h = false
