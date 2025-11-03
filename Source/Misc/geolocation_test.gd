extends Control

@export var log_label: Label
@export var geolocation_status_label: Label
@export var android_gps: AndroidGPSWrapper



func _ready():
	android_gps.location_permission_updated.connect(_on_location_permission)
	android_gps.cooridnates_updated.connect(_on_cooridnates_updated)


func _process(_delta: float):
	var is_listening = android_gps.is_listening_for_geolocation_updates()
	geolocation_status_label.text = str('Is Listening: ', is_listening)


func _on_Button_pressed() -> void:
	log_label.text = android_gps.ping()


func _on_permission_button_pressed() -> void:
	android_gps.request_location_permission()


func _on_has_permission_button_pressed() -> void:
	log_label.text = str(android_gps.has_location_permission())


func _on_start_listening_button_pressed() -> void:
	var minTimeMs: int = 1000
	var minDistanceM: float = 0.0
	var plugin_result = android_gps.start_geolocation_listener(minTimeMs, minDistanceM)
	log_label.text = str('Started listinening: ', plugin_result)


func _on_stop_listening_button_pressed() -> void:
	android_gps.stop_geolocation_listener()


func _on_location_permission(granted: bool) -> void:
	log_label.text = str('Location permission: ', granted)


func _on_cooridnates_updated(location_dictionary: Dictionary) -> void:
	var latitude: float = location_dictionary["latitude"]
	var longitude: float = location_dictionary["longitude"]
	log_label.text = str('Location Update: Latitude[', latitude, '], Longitude[', longitude, ']')
