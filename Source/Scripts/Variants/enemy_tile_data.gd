class_name EnemyTileData

enum EnemyType {SLIME, SKELETON, ORC}

var expiry_time_ms: int
var tile_pos: Vector2i
var extent: int
var enemies: Array[EnemyData]

class EnemyData:
	var id: String
	var type: EnemyType
	var local_pos: Vector2i


func _init(p_tile_pos: Vector2i, p_extent: int, p_expiry: int, p_enemies: Array[EnemyData]) -> void:
	self.tile_pos = p_tile_pos
	self.extent = p_extent
	self.expiry_time_ms = p_expiry
	self.enemies = p_enemies


func is_expired() -> bool:
	return false
