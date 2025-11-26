class_name PVPEncounter extends NinePatchRect

func _on_pvp_lobby_updated(data) -> void:
	if data.update_type == "start_fight":
		if is_in_lobby(Util.game.websocket._user_id, data):
			hide()
			return
	
	for player in data.lobby:
		if player.id == Util.game.websocket._user_id:
			show()
			
			if data.size() == 1:
				$TopLabel.text = "Waiting for player..."
				$AttackButton.disabled = true
				$EnemySprite.hide()
				$EnemyName.hide()
				$EnemyLevel.hide()
		else:
			$TopLabel.text = "FOUND PLAYER!"
			$EnemyName.text = player.name
			$EnemyLevel.text = "Level: %s" % int(player.level)
			$AttackButton.disabled = false
			$EnemySprite.show()
			$EnemyName.show()
			$EnemyLevel.show()

func is_in_lobby(p_id, p_data) -> bool:
	for player in p_data.lobby:
		if player.id == p_id:
			return true
	return false

func _on_close_button_pressed() -> void:
	hide()
	var payload = {
		"type": "pvp_lobby_request",
		"update": "leave",
		"level": Util.game.player.level,
		"name": Util.game.websocket._username
	}
	Util.game.websocket._client.send_text(JSON.stringify(payload))


func _on_attack_button_pressed() -> void:
	var payload = {
		"type": "pvp_lobby_request",
		"update": "start_fight",
	}
	Util.game.websocket._client.send_text(JSON.stringify(payload))
