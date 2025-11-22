class_name Dummy extends Node2D

@export var top_label: Label
@export var bottom_label: Label
@export var name_label: Label
@export var label_button: Button

var data: PointOfInterestData


func _on_button_pressed():
	if (data):
		print(var_to_str(data))
		if (data.name):
			print("clicked on ", data.name)
		else:
			print("clicked on poi with no data")
	else:
		print("clicked on poi with no data")	
