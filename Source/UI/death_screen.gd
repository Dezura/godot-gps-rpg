extends NinePatchRect


func _on_close_button() -> void:
	Util.game.player.full_heal()
	hide()
