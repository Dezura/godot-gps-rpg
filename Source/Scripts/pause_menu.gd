extends Control

@export var pause_button: Button

func _ready() -> void:
	pause_button.pressed.connect(open_menu)
	
	hide()
	$CenterContainer/PanelContainer/VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$CenterContainer/PanelContainer/VBoxContainer/Placeholder1.pressed.connect(_on_placeholder_1_pressed)
	$CenterContainer/PanelContainer/VBoxContainer/Placeholder2.pressed.connect(_on_placeholder_2_pressed)

func _on_resume_pressed() -> void:
	#get_tree().paused = false
	hide()

func _on_placeholder_1_pressed() -> void:
	print("Placeholder 1 pressed")

func _on_placeholder_2_pressed() -> void:
	print("Placeholder 2 pressed")

func open_menu() -> void:
	show()
	#get_tree().paused = true
