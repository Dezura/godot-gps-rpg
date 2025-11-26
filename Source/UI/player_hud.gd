class_name PlayerHUD extends Control

var poi_menu
var poi_name_label
var poi_details_label 
var button
var level_label: Label
var hp_label: Label
var hp_bar: TextureProgressBar
var xp_bar: TextureProgressBar
var current_poi_data: PointOfInterestData 
var chat_history: RichTextLabel
var chat_input: LineEdit
var chat_panel: PanelContainer

@onready var enemy_encounter_menu: EnemyEncounterMenu = $EnemyEncounter
@onready var enemy_fight_ui: EnemyFightUI = $EnemyFightUI


signal chat_message_sent(text: String)


func _ready() -> void:
	poi_menu = $POI_Menu
	poi_name_label = $POI_Menu/VBoxContainer/POI_Name 
	#poi_details_label = $POI_Menu/VBoxContainer/POI_info 
	button = $POI_Menu/VBoxContainer/PlaceholderButton

	level_label = $Level
	hp_label = $"Health Text"
	hp_bar = $"Health Bar"
	xp_bar = $"Exp Bar"
	
	$PauseMenu.visibility_changed.connect(on_pause_menu_visibility_changed)
	chat_history = $ChatPanel/VBoxContainer/ChatHistory
	chat_input = $ChatPanel/VBoxContainer/ChatInput
	chat_panel = $ChatPanel
	chat_input.text_submitted.connect(on_chat_input_submitted)
	
	enemy_encounter_menu.attack_pressed.connect(enemy_fight_ui.start_ui)
	enemy_fight_ui.player_died.connect(_on_player_death)
	enemy_fight_ui.player_victory.connect(_on_player_victory)
	
func add_chat_message(message: String) -> void:
	var time = Time.get_time_dict_from_system()
	var timestamp = "%02d:%02d" % [time.hour, time.minute]
	chat_history.append_text("[color=#FF0000]" + timestamp + "[/color] - " + message + "\n")

func on_chat_input_submitted(text: String) -> void:
	if text.strip_edges() == "":
		return
	chat_message_sent.emit(text)
	chat_input.clear()
	chat_input.release_focus()
	
	
func _process(_delta: float) -> void:
	$FPS.set_text("FPS " + "100" + str(Engine.get_frames_per_second()))
	if poi_menu.visible and current_poi_data:
		_update_button_state()
		

func _input(event: InputEvent) -> void:
	if chat_input.has_focus():
		return
	if $EnemyEncounter.visible:
		return
	
	if event is InputEventKey and event.keycode == KEY_P and event.pressed:
		$PauseMenu.visible = not $PauseMenu.visible

func on_pause_menu_visibility_changed() -> void:
	var is_in_menu = $PauseMenu.visible
	$"Virtual Joystick".visible = not is_in_menu
	if is_in_menu:
		$"Virtual Joystick".process_mode = PROCESS_MODE_DISABLED
	else:
		$"Virtual Joystick".process_mode = PROCESS_MODE_INHERIT
	
	if is_in_menu:
		poi_menu.visible = false

func _on_player_death() -> void:
	$DeathScreen.show()

func _on_player_victory(gained_xp: int) -> void:
	var old_player_level = Util.game.player.level
	$VictoryScreen/Text.text = "+%s XP Gained!" % gained_xp
	Util.game.player.gain_xp(gained_xp)
	if old_player_level != Util.game.player.level:
		$VictoryScreen/Text.text += "\nReached Level %s!" % Util.game.player.level
	$VictoryScreen.show()

func _on_level_changed(new_level: int) -> void:
	level_label.text = "Level: %d" % new_level

func _on_xp_changed(new_xp: int, max_xp: int) -> void:
	xp_bar.max_value = max_xp
	xp_bar.value = new_xp

func _on_hp_changed(new_hp: int, max_hp: int) -> void:
	hp_label.text = "%d/%d" % [new_hp, max_hp]
	hp_bar.max_value = max_hp
	hp_bar.value = new_hp

func show_poi_info(data: PointOfInterestData) -> void:
	if not poi_menu: return
	
	current_poi_data = data
	
	poi_menu.visible = true
	poi_name_label.text = data.name
	
	var current_time = int(Time.get_unix_time_from_system())
	var time_diff = current_time - data.last_visited_at
	var cooldown_duration = 300 # 5 minutes in seconds

	# If less than 5 minutes have passed since last visit
	if data.last_visited_at != 0 and time_diff < cooldown_duration:
		button.disabled = true
		var minutes_left = int((cooldown_duration - time_diff) / 60)
		var seconds_left = int(cooldown_duration - time_diff) % 60
		button.text = "Cooldown: (%02d:%02d)" % [minutes_left, seconds_left]
		return # Stop here so we don't overwrite the text below
	
	button.disabled = false # Re-enable if cooldown is over
	
	if data.categories.has("catering"):
		button.text = "Heal"
	elif data.categories.has("commercial"):
		button.text = "Get XP"
	elif data.categories.has("leisure"):
		button.text = "Heal and Get XP"
	else:
		button.text = "unknown POI"
	

func _update_button_state() -> void:
	var current_time = int(Time.get_unix_time_from_system())
	var time_diff = current_time - current_poi_data.last_visited_at
	var cooldown_duration = 300 # 5 minutes

	# Check Cooldown
	if current_poi_data.last_visited_at != 0 and time_diff < cooldown_duration:
		button.disabled = true
		var minutes_left = int((cooldown_duration - time_diff) / 60)
		var seconds_left = int(cooldown_duration - time_diff) % 60
		button.text = "Cooldown (%02d:%02d)" % [minutes_left, seconds_left]
	else:
		button.disabled = false
		# Restore correct text based on category
		if current_poi_data.categories.has("catering"):
			button.text = "Heal"
		elif current_poi_data.categories.has("commercial"):
			button.text = "Get XP"
		elif current_poi_data.categories.has("leisure"):
			button.text = "Heal and Get XP"
		else:
			button.text = "unknown POI"

func _on_placeholder_button_pressed() -> void:
	var game_manager = get_tree().current_scene as GameManager
	var player = game_manager.player
	
	current_poi_data.last_visited_at = int(Time.get_unix_time_from_system())
	
	if current_poi_data.categories.has("catering"):
		player.modify_health(player.max_hp - player.hp)
		
	elif current_poi_data.categories.has("commercial"):
		player.gain_xp(20)
		
	elif current_poi_data.categories.has("leisure"):
		player.modify_health(player.max_hp - player.hp)
		player.gain_xp(40)
	
	poi_menu.visible = false

func _on_close_button_pressed() -> void:
	poi_menu.visible = false
