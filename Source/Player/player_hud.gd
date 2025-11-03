extends Control


func _process(_delta: float) -> void:
	$FPS.set_text("FPS " + str(Engine.get_frames_per_second()))
