extends Control

var poi_menu
var poi_name_label
var poi_details_label 
var button

func _ready() -> void:
	poi_menu = $POI_Menu
	poi_name_label = $POI_Menu/VBoxContainer/POI_Name 
	poi_details_label = $POI_Menu/VBoxContainer/POI_info 
	button = $POI_Menu/VBoxContainer/PlaceholderButton

func _process(_delta: float) -> void:
	$FPS.set_text("FPS " + str(Engine.get_frames_per_second()))

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
