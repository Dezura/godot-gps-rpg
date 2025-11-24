## GEMINI 3.0 PRO ADDED THE 5 MINUTE TIMER FOR POI

extends Control

var poi_menu
var poi_name_label
var poi_details_label 
var button
var level_label: Label
var hp_label: Label
var hp_bar: TextureProgressBar
var xp_bar: TextureProgressBar
var current_poi_data: PointOfInterestData 

func _ready() -> void:
	poi_menu = $POI_Menu
	poi_name_label = $POI_Menu/VBoxContainer/POI_Name 
	poi_details_label = $POI_Menu/VBoxContainer/POI_info 
	button = $POI_Menu/VBoxContainer/PlaceholderButton

	level_label = $Level
	hp_label = $"Health Text"
	hp_bar = $"Health Bar"
	xp_bar = $"Exp Bar"

func _process(_delta: float) -> void:
	$FPS.set_text("FPS " + str(Engine.get_frames_per_second()))
	if poi_menu.visible and current_poi_data:
		_update_button_state()

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
