extends Control

var poi_menu
var poi_name_label
var poi_details_label 
var button
var level_label: Label
var hp_label: Label
var hp_bar: TextureProgressBar
var xp_bar: TextureProgressBar

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
	
	poi_menu.visible = true
	poi_name_label.text = data.name
	
	if data.categories.has("catering"):
		button.text = "Heal"
	elif data.categories.has("commercial"):
		button.text = "Get XP"
	elif data.categories.has("leisure"):
		button.text = "Leisure POI"
	else:
		button.text = "unknown POI"
	poi_details_label.text = var_to_str(data)


func _on_placeholder_button_pressed() -> void:
	print("placeholder, maybe to heal")

func _on_close_button_pressed() -> void:
	poi_menu.visible = false
