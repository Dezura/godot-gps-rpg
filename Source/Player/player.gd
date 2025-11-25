class_name Player extends Node2D

signal update_level(new_level: int)
signal update_xp(new_xp: int, max_xp: int)
signal update_hp(new_hp: int, max_hp: int)

var level: int = 1
var xp: int = 0
var max_xp: int = 100
var hp: int = 8
var max_hp: int = 16

@export var game: GameManager
@onready var _anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var interaction_radius: float = 75.0


func _ready() -> void:
	print("player script is active")
	game.player_coords_updated.connect(_on_player_coords_updated)
	queue_redraw()
	

func gain_xp(amount: int) -> void:
	xp += amount
	
	if xp >= max_xp:
		xp = xp - max_xp
		level += 1
		max_xp += 10
		max_hp += 1
		hp += 1
		update_level.emit(level)
		
	update_xp.emit(xp, max_xp)
	update_hp.emit(hp, max_hp)

func modify_health(amount: int) -> void:
	hp += amount
	hp = clamp(hp, 0, max_hp)
	update_hp.emit(hp, max_hp)

func full_heal() -> void:
	hp = max_hp
	update_hp.emit(hp, max_hp)
	

func _process(_delta: float) -> void:
	if global_position != game.player_coords.game_position:
		global_position = global_position.lerp(game.player_coords.game_position, min(1, 5 * _delta))
	
	# Stop lerping if we are close enough
	if abs(global_position.x - game.player_coords.game_position.x) < 0.2:
		global_position.x = game.player_coords.game_position.x
	if abs(global_position.y - game.player_coords.game_position.y) < 0.2:
		global_position.y = game.player_coords.game_position.y
	
	if global_position == game.player_coords.game_position:
		_anim_sprite.play("Idle")

func _draw() -> void:
	draw_arc(Vector2.ZERO, interaction_radius, 0, TAU, 64, Color.GREEN, 2.0)


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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Press 'T' to test XP gain and potential Level Up
		if event.keycode == KEY_T:
			print("Debug: Adding 20 XP")
			gain_xp(20)
			
		# Press 'H' to test Health damage
		elif event.keycode == KEY_H:
			print("Debug: Taking 10 Damage")
			modify_health(-10)
