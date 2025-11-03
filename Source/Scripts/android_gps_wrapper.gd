class_name AndroidGPSWrapper extends Node
# A wrapper/helper class for the  Android Geolocation Plugin. 

var _plugin_name = "GeolocationPlugin"
var _plugin

# Emitted when the user accepts/rejects the location permission request.
signal location_permission_updated(granted: bool)

# Emitted periodically with the updated geolocation.
# The location_dictionary will contain either:
# 1. 2 keys: "latitude" and "longitude". Both keys have float values.
# 2. No keys: Failed to retrieve the location.
signal cooridnates_fetched(location_dictionary: Dictionary)



func _ready():
	if Engine.has_singleton(_plugin_name):
		_plugin = Engine.get_singleton(_plugin_name)
		_plugin.connect("locationPermission", _on_location_permission)
		_plugin.connect("locationUpdate", _on_cooridnates_fetched)
		
		if !has_location_permission():
			request_location_permission()
			var granted: bool = await location_permission_updated
			if not granted:
				print("User didn't grant location permissions!")
				return
		
		start_geolocation_listener()
	
	else:
		printerr("Couldn't find plugin " + _plugin_name)


# Pings the plugin and returns its name and version.
func ping() -> String:
	if _plugin:
		return _plugin.ping()
	else:
		return "Couldn't find plugin" + _plugin_name


# Returns true if location permissions are granted.
# Returns false otherwise.
func has_location_permission() -> bool:
	if _plugin:
		return _plugin.hasLocationPermission()
	else:
		return false


# Sends a location permission request to the device (Android)
# The result of the request will be published asynchronously on the location_permission_updated signal. 
func request_location_permission() -> void:
	if _plugin:
		_plugin.requestLocationPermission()


func is_listening_for_geolocation_updates() -> bool:
	if _plugin:
		return _plugin.isListeningForGeolocationUpdates()
	else:
		return false


func start_geolocation_listener(minTimeMs: int = 250, minDistanceM: float = 0.0) -> bool:
	if _plugin:
		return _plugin.startGeolocationListener(minTimeMs, minDistanceM)
	else:
		return false


func stop_geolocation_listener() -> void:
	if _plugin:
		_plugin.stopGeolocationListener()


func _on_location_permission(granted: bool) -> void:
	location_permission_updated.emit(granted)


func _on_cooridnates_fetched(location_dictionary: Dictionary) -> void:
	cooridnates_fetched.emit(location_dictionary)
