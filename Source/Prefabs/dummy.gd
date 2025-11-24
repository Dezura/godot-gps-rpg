class_name Dummy extends Node2D

@export var top_label: Label
@export var bottom_label: Label
@export var name_label: Label
@export var label_button: Button

var data: PointOfInterestData


# Reminder to future self, update this logic from using a button to using input_pickable instead
# this should be in a poi.gd anyways
func _on_button_pressed():
	var game_manager = get_tree().current_scene as GameManager
	var player = game_manager.player
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= player.interaction_radius:
		print("player in range")
		# 3. Find the HUD and show data
		# Recursive search ensures we find PlayerHUD under CanvasLayer
		var hud = game_manager.find_child("PlayerHUD", true, false)
		if hud and data:
			hud.show_poi_info(data)
	else:
		print("player not in range, distance: %.2f / %.2f" % [distance, player.interaction_radius])
	
	if (data):
		print(var_to_str(data))
		if (data.name):
			print("clicked on ", data.name)
		else:
			print("clicked on poi with no data")
	else:
		print("clicked on poi with no data")
