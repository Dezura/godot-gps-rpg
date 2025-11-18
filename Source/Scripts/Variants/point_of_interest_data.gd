class_name PointOfInterestData

var name: String
var coords: GeoCoordinate
var categories: Array[String]
var place_id: String


func _init(id: String, p_name: String, p_coords: GeoCoordinate, p_categories: Array) -> void:
	self.place_id = id
	self.name = p_name
	self.coords = p_coords
	for value in p_categories:
		if value is String:
			categories.append(value)
