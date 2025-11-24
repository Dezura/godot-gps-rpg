## GEMINI 3.0 PRO ADDED THE 5 MINUTE TIMER FOR POI
class_name PointOfInterestData

var name: String
var coords: GeoCoordinate
var categories: Array[String]
var place_id: String
var last_visited_at: int = 0


func _init(id: String, p_name: String, p_coords: GeoCoordinate, p_categories: Array) -> void:
	self.place_id = id
	self.name = p_name
	self.coords = p_coords
	for value in p_categories:
		if value is String:
			categories.append(value)
