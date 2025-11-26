class_name PVPEncounter extends NinePatchRect


func _on_pvp_requested(data) -> void:
	if data.from_id == Util.game.websocket._user_id:
		wait_for_pvp_encounter()
	else:
		join_pvp_encounter(data.name, data.level)

func wait_for_pvp_encounter() -> void:
	$TopLabel.text = "Waiting for player..."
	show()

func join_pvp_encounter(found_username, found_level) -> void:
	$TopLabel.text = "FOUND PLAYER!"
	$EnemyName.text = found_username
	$EnemyLevel.text = found_level
	show()

func _on_close_button_pressed() -> void:
	hide()
