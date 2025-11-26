class_name PVPFightUI extends ColorRect

signal player_victory(gained_xp: int)
signal player_died

var game: GameManager
var player: Player
var websocket: WebSocketThingy
var _current_enemy: Enemy

var _enemy_hp: int
var _enemy_lvl: int
var _enemy_max_hp: int
var _enemy_damage_range: Vector2i
var _enemy_stun := false

var _player_block := false

var timer: Timer

var fight_active := false


var current_turn: int
var player_i: int
var enemy_i: int
var lobby_data

func _ready() -> void:
	timer = $Timer


func _on_pvp_lobby_updated(data) -> void:
	if data.update_type == "start_fight":
		for i in range(data.lobby.size()):
			if data.lobby[i].id == Util.game.websocket._user_id:
				lobby_data = data.lobby
				show()
				current_turn = data.current_turn
				player_i = i
				fight_active = true
			else:
				enemy_i = i
			
		if fight_active:
			$PlayerContainer/StunStatus.hide()
			$PlayerContainer/PlayerName.text = websocket._username
			$PlayerContainer/HealthBar.max_value = player.max_hp
			$PlayerContainer/HealthBar.value = player.hp
			$PlayerContainer/TextHP.text = "%s/%s HP" % [player.hp, player.max_hp]
			$PlayerContainer/Level.text = "LVL: %s" % player.level
			
			$EnemyBox/StunStatus.hide()
			$EnemyBox/EnemyName.text = lobby_data[enemy_i].name
			$EnemyBox/TextHP.text = "%s/%s HP" % [lobby_data[enemy_i].hp, lobby_data[enemy_i].max_hp]
			$EnemyBox/HealthBar.max_value = lobby_data[enemy_i].max_hp
			$EnemyBox/HealthBar.value = lobby_data[enemy_i].hp
			$EnemyBox/EnemyLevel.text = "LVL: %s" % lobby_data[enemy_i].level
			
			if data.current_turn == player_i:
				_allow_turn()
			else:
				$TurnBlockedUI.show()
	if data.update_type == "next_turn" and fight_active:
		lobby_data = data.lobby
		sync_local_stats_to_data()
		if data.current_turn == player_i:
			_allow_turn()
		else:
			$TurnBlockedUI.show()
	if data.update_type == "end_fight" and fight_active:
		fight_active = false
		lobby_data = data.lobby
		sync_local_stats_to_data()
		$TurnBlockedUI.show()
		timer.start()
		await timer.timeout
		hide()
		for i in range(lobby_data.size()):
			if lobby_data[i].hp <= 0:
				if lobby_data[i].id == websocket._user_id:
					player_died.emit()
				else:
					var calculated_xp = randi_range(40 + (lobby_data[enemy_i].level -1) * 15 - 5, 40 + (lobby_data[enemy_i].level -1) * 15 + 5)
					player_victory.emit(calculated_xp)


func sync_local_stats_to_data() -> void:
	player.set_health(lobby_data[player_i].hp)
	$PlayerContainer/HealthBar.value = player.hp
	$PlayerContainer/TextHP.text = "%s/%s HP" % [player.hp, player.max_hp]
	
	$EnemyBox/HealthBar.value = lobby_data[enemy_i].hp
	$EnemyBox/TextHP.text = "%s/%s HP" % [lobby_data[enemy_i].hp, lobby_data[enemy_i].max_hp]
	
	if lobby_data[player_i].stunned:
		$PlayerContainer/StunStatus.show()
	else:
		$PlayerContainer/StunStatus.hide()
	if lobby_data[enemy_i].stunned:
		$EnemyBox/StunStatus.show()
	else:
		$EnemyBox/StunStatus.hide()

func _end_turn() -> void:
	var payload
	if lobby_data[player_i].hp <= 0 or lobby_data[enemy_i].hp <= 0:
		payload = {
			"type": "pvp_lobby_request",
			"update": "end_fight",
			"lobby": lobby_data,
		}
	else:
		payload = {
			"type": "pvp_lobby_request",
			"update": "next_turn",
			"lobby": lobby_data
		}
	Util.game.websocket._client.send_text(JSON.stringify(payload))


func _allow_turn() -> void:
	if lobby_data[player_i].stunned:
		timer.start()
		await timer.timeout
		
		if randf() < 0.6:
			lobby_data[player_i].stunned = false
		_end_turn()
		return
	
	if _player_block:
		$CommandUI/AttackButton.text = "Strong Attack"
		_player_block = false
	else:
		$CommandUI/AttackButton.text = "Attack"
	$TurnBlockedUI.hide()



func _on_attack_button_pressed() -> void:
	var damage: int
	if $CommandUI/AttackButton.text == "Strong Attack":
		damage = int(randi_range(player.damage_range.x, player.damage_range.y)*1.75)
	else:
		damage = randi_range(player.damage_range.x, player.damage_range.y)
	if lobby_data[enemy_i].blocking:
		damage /= 3
	lobby_data[enemy_i].hp = max(0, lobby_data[enemy_i].hp - int(damage))
	_end_turn()


func _on_bash_button_pressed() -> void:
	var damage = int(randi_range(player.damage_range.x, player.damage_range.y)/2.0)
	if lobby_data[enemy_i].blocking:
		damage /= 3
	lobby_data[enemy_i].hp = max(0, lobby_data[enemy_i].hp - int(damage))
	if randf() < 0.6:
		lobby_data[enemy_i].stunned = true
	_end_turn()


func _on_block_button_pressed() -> void:
	lobby_data[player_i].blocked = true
	_end_turn()
