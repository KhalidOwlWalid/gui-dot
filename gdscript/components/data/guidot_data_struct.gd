class_name Guidot_Data

var _name: String = ""
var _description: String = ""
var _unit: String = ""
var _line_color: Color = Color.RED
var _line_color_str: String = "red"
var _min: float = 0
var _max: float = 1

var _metadata: Dictionary = {
	"unique_name": "",
	"unique_id": self.get_instance_id(),
	"description": "",
	"unit": "",
	"data_name": "",
	"line_color": "red",
	"min": self._min,
	"max": self._max, 
}

# var _color_options: Dictionary = {
# 	"red": Color.RED,
# 	"white": Color.WHITE,
# }

func line_color_options() -> Dictionary:
	return self._color_options

func set_line_color(line_color_str: String) -> void:
	self._line_color = Guidot_Utils.get_color(line_color_str)

func get_line_color() -> Color:
	return self._line_color

func get_min_max() -> Vector2:
	return Vector2(self._min, self._max)

func _set_metadata(name: String, unit: String, description: String, min: float, max: float, line_color: String) -> void:
	self._metadata["unique_name"] = name
	self._metadata["data_name"] = name
	self._metadata["unit"] = unit
	self._metadata["description"] = description
	self._metadata["line_color"] = line_color
	self._metadata["min"] = min
	self._metadata["max"] = max

func setup_properties(name: String, unit: String, description: String, min: float, max: float, line_color: String = "red"):
	self._name = name
	self._unit = unit
	self._description = description
	self._min = min
	self._max = max
	self._line_color_str = line_color
	self.set_line_color(line_color)
	self._set_metadata(self._name, self._unit, self._description, self._min, self._max, self._line_color_str)

func get_name() -> String:
	return self._name

func get_description() -> String:
	return self._description

func get_unit() -> String:
	return self._unit

func get_unique_id() -> int:
	return self._metadata["unique_id"]
