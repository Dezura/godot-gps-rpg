class_name Enemy extends Node2D

enum EnemyType {SLIME, SKELETON, WANDERING_EYE}

var enemy_name: String
var type: int
var id: String

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("coolio")
		


func init_enemy_data(p_type: int, p_id: String) -> void:
	type = p_type
	id = p_id
	
	match type:
		EnemyType.SLIME:
			$Sprite.texture = Util.textures.slime
			enemy_name = "Slime"
		EnemyType.SKELETON:
			$Sprite.texture = Util.textures.skeleton
			enemy_name = "Skeleton"
		EnemyType.WANDERING_EYE:
			$Sprite.texture = Util.textures.wandering_eye
			enemy_name = "Wandering Eye"
	$Sprite.flip_h = bool(randi_range(0, 1))
