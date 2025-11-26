class_name EnemyEncounterMenu extends NinePatchRect

signal attack_pressed(from_enemy: Enemy)
signal menu_closed

var _current_enemy: Enemy


func show_enemy_encounter(from_enemy: Enemy) -> void:
	_current_enemy = from_enemy
	
	$EnemySprite.texture = Util.enemy_textures[_current_enemy.type]
	$EnemyName.text = _current_enemy.enemy_name
	$EnemyLevel.text = "Level: %s" % _current_enemy.level
	
	
	show()


func force_close() -> void:
	menu_closed.emit()
	hide()


func _on_close_button_pressed() -> void:
	force_close()


func _on_attack_button_pressed() -> void:
	force_close()
	if _current_enemy != null:
		attack_pressed.emit(_current_enemy)
