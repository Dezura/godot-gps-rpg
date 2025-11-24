extends Control

var level_label: Label
var hp_label: Label
var hp_bar: TextureProgressBar
var xp_bar: TextureProgressBar

func _ready() -> void:
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
