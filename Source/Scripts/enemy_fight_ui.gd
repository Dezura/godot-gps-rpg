class_name EnemyFightUI extends ColorRect

signal player_fled
signal player_victory(gained_xp: int)
signal player_died

var game: GameManager
var player: Player
var _current_enemy: Enemy

var _enemy_hp: int
var _enemy_lvl: int
var _enemy_max_hp: int
var _enemy_damage_range: Vector2i
var _enemy_stun := false

var _player_block := false

var timer: Timer

var fight_active := false

func _ready() -> void:
	timer = $Timer

# God help me this is some of the worst damn code ive written in ages, but its rushed enough to work
func start_ui(from_enemy: Enemy) -> void:
	fight_active = true
	
	_current_enemy = from_enemy
	_enemy_hp =_current_enemy.max_hp
	_enemy_lvl =_current_enemy.level
	_enemy_max_hp = _current_enemy.max_hp
	_enemy_damage_range = _current_enemy.damage_range
	_enemy_stun = false
	_player_block = false
	
	$EnemySprite.texture = Util.enemy_textures[_current_enemy.type]
	$EnemyBox/EnemyName.text = _current_enemy.enemy_name
	$EnemyBox/EnemyLevel.text = "LVL: %s" % _enemy_lvl
	
	$PlayerContainer/Level.text = "LVL: %s" % player.level
	$PlayerContainer/PlayerName.text = game.websocket._userID
	_update_hp_bars()
	
	
	show()
	timer.start()
	await timer.timeout
	_allow_turn()


func _on_enemy_turn() -> void:
	timer.start()
	await timer.timeout
	if not _enemy_stun:
		if _player_block:
			player.modify_health(-int(randi_range(_enemy_damage_range.x, _enemy_damage_range.y)/3.0))
		else:
			player.modify_health(-randi_range(_enemy_damage_range.x, _enemy_damage_range.y))
	else:
		if randf() < 0.6:
			_enemy_stun = false
	_update_hp_bars()
	timer.start()
	await timer.timeout
	_allow_turn()

func _allow_turn() -> void:
	if not fight_active:
		return
	
	if _player_block:
		$CommandUI/AttackButton.text = "Strong Attack"
		_player_block = false
	else:
		$CommandUI/AttackButton.text = "Attack"
	$TurnBlockedUI.hide()

func _end_turn() -> void:
	_update_hp_bars()
	if not fight_active:
		return
	
	$TurnBlockedUI.show()
	_on_enemy_turn()

func _update_hp_bars() -> void:
	if not fight_active:
		return
	
	_enemy_hp = max(0, _enemy_hp)
	$EnemyBox/TextHP.text = "%s/%s HP" % [_enemy_hp, _enemy_max_hp]
	$EnemyBox/HealthBar.max_value = _enemy_max_hp
	$EnemyBox/HealthBar.value = _enemy_hp
	
	$PlayerContainer/TextHP.text = "%s/%s HP" % [player.hp, player.max_hp]
	$PlayerContainer/HealthBar.max_value = player.max_hp
	$PlayerContainer/HealthBar.value = player.hp
	
	if _enemy_stun:
		$EnemyBox/StunStatus.show()
	else:
		$EnemyBox/StunStatus.hide()
	
	if player.hp == 0:
		$TurnBlockedUI.show()
		fight_active = false
		timer.start()
		await timer.timeout
		if _current_enemy != null:
			_current_enemy.queue_free()
		player_died.emit()
		hide()
		return
	if _enemy_hp == 0:
		fight_active = false
		$TurnBlockedUI.show()
		timer.start()
		await timer.timeout
		var calculated_xp = randi_range(20 + (_enemy_lvl -1) * 15 - 5, 20 + (_enemy_lvl -1) * 15 + 5)
		if _current_enemy != null:
			_current_enemy.queue_free()
		player_victory.emit(calculated_xp)
		hide()
		return


func _on_flee_button_pressed() -> void:
	fight_active = false
	player_fled.emit()
	hide()


func _on_attack_button_pressed() -> void:
	if $CommandUI/AttackButton.text == "Strong Attack":
		_enemy_hp -= int(randi_range(player.damage_range.x, player.damage_range.y)*1.75)
	else:
		_enemy_hp -= randi_range(player.damage_range.x, player.damage_range.y)
	_end_turn()


func _on_bash_button_pressed() -> void:
	_enemy_hp -= int(randi_range(player.damage_range.x, player.damage_range.y)/2.0)
	if randf() < 0.6:
		_enemy_stun = true
	_end_turn()


func _on_block_button_pressed() -> void:
	_player_block = true
	_end_turn()
