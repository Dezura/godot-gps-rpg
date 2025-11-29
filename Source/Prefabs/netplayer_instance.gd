class_name NetplayerInstance extends Node2D

@export var _anim_sprite: AnimatedSprite2D
var coords: GeoCoordinate

func init_netplayer(lat, lon, username, color, level) -> void:
	coords = GeoCoordinate.new(lat, lon)
	print("gt42ng034g8n5gj54gmj35gm3")
	print(color)
	$PlayerName.text = username
	$Level.text = "LVL: %s" % int(level)

func update_stats(lat, lon, level) -> void:
	coords.longitude = lon
	coords.latitude = lat
	$Level.text = "LVL: %s" % int(level)


func _process(delta: float) -> void:
	if global_position != coords.game_position:
		if not _anim_sprite.animation == "Walk":
			_anim_sprite.play("Walk")
		if coords.game_position.x < global_position.x:
			_anim_sprite.flip_h = true
		elif coords.game_position.x > global_position.x:
			_anim_sprite.flip_h = false
		global_position = global_position.lerp(coords.game_position, min(1, 1.5 * delta))
	
	# Stop lerping if we are close enough
	if abs(global_position.x - coords.game_position.x) < 2.25:
		global_position.x = coords.game_position.x
	if abs(global_position.y - coords.game_position.y) < 2.25:
		global_position.y = coords.game_position.y
	
	if global_position == coords.game_position:
		_anim_sprite.play("Idle")
