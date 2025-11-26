class_name Enemy extends Node2D

enum EnemyType {SLIME, SKELETON, WANDERING_EYE}

var type: int
var id: String

var enemy_name: String
var level: int
var max_hp: int
var damage_range: Vector2i

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = Util.game.player
		var distance = global_position.distance_to(player.global_position)
		
		if distance <= player.interaction_radius:
			Util.hud.enemy_encounter_menu.show_enemy_encounter(self)


func init_enemy_data(p_type: int, p_id: String) -> void:
	type = p_type
	id = p_id
	
	match type:
		EnemyType.SLIME:
			enemy_name = "Slime"
			level = randi_range(2, 4)
			damage_range = Vector2i(1, 3)
		EnemyType.SKELETON:
			enemy_name = "Skeleton"
			level = randi_range(5, 7)
			damage_range = Vector2i(3, 6)
		EnemyType.WANDERING_EYE:
			enemy_name = "Wandering Eye"
			level = randi_range(10, 15)
			damage_range = Vector2i(6, 10)
	var base_hp = 4
	var growth = 2
	var variance = 2
	max_hp = base_hp + (level - 1) * growth + randi_range(-variance, variance)
	
	$Sprite.texture = Util.enemy_textures[self.type]
	$Sprite.flip_h = bool(randi_range(0, 1))
	$Level.text = "LVL: %s" % level
