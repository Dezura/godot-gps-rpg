class_name PVPEncounter extends NinePatchRect

func _on_pvp_lobby_updated(data) -> void:
	for player in data:
		print(player)
		if player.id == Util.game.websocket._user_id:
			show()
			
			if data.size() == 1:
				$TopLabel.text = "Waiting for player..."
				$EnemySprite.hide()
				$EnemyName.hide()
				$EnemyLevel.hide()
		else:
			$TopLabel.text = "FOUND PLAYER!"
			$EnemyName.text = player.name
			$EnemyLevel.text = "Level: %s" % int(player.level)
			$EnemySprite.show()
			$EnemyName.show()
			$EnemyLevel.show()


func _on_close_button_pressed() -> void:
	hide()
	var payload = {
		"type": "pvp_lobby_request",
		"update": "leave",
		"level": Util.game.player.level,
		"name": Util.game.websocket._username
	}
	Util.game.websocket._client.send_text(JSON.stringify(payload))
