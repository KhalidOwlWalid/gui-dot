class_name Guidot_Data

var _name: String = ""
var _description: String = ""
var _unit: String = ""
var _line_color: Color = Color.RED
var _line_color_str: String = "red"
var _min: float = 0
var _max: float = 1
var _freq: float = 60.0
var _last_update_ms: int = Time.get_ticks_msec()

var _metadata: Dictionary = {
	"unique_name": "",
	"unique_id": self.get_instance_id(),
	"description": "",
	"unit": "",
	"data_name": "",
	"line_color": "red",
	"min": self._min,
	"max": self._max, 
	"expected_frequency": self._freq,
}

# Setters
func set_line_color(line_color_str: String) -> void:
	self._line_color = Guidot_Utils.get_color(line_color_str)

func set_min(min_val: float) -> void:
	self._min = min_val
	self._metadata["min"] = self._min

func set_max(max_val: float) -> void:
	self._max = max_val
	self._metadata["max"] = self._max

func set_line_color_str(color_str: String) -> void:
	self._line_color_str = color_str
	self._metadata["line_color"] = self._line_color_str

func set_unique_name(unique_name_str: String) -> void:
	self._name = unique_name_str
	self._metadata["unique_name"] = self._name
	self._metadata["data_name"] = self._name

func set_unit(unit: String) -> void:
	self._unit = unit
	self._metadata["unit"] = self._unit

func set_description(descr: String) -> void:
	self._description = descr
	self._metadata["description"] = self._description

func set_frequency(freq: float) -> void:
	self._freq = freq
	self._metadata["expected_frequency"] = self._freq

func line_color_options() -> Dictionary:
	return self._color_options

# Getters
func get_line_color() -> Color:
	return self._line_color

func get_min_max() -> Vector2:
	return Vector2(self._min, self._max)

func get_name() -> String:
	return self._name

func get_description() -> String:
	return self._description

func get_unit() -> String:
	return self._unit

func get_unique_id() -> int:
	return self._metadata["unique_id"]

func get_expected_freq() -> float:
	return self._freq

func _set_metadata(name: String, unit: String, description: String, min: float, max: float, line_color: String) -> void:
	# self.set_unique_name(name)
	self._metadata["data_name"] = name
	self._metadata["unit"] = unit
	self._metadata["description"] = description
	self._metadata["line_color"] = line_color
	self._metadata["min"] = min
	self._metadata["max"] = max

func setup_properties(name: String, unit: String, description: String, min: float, max: float, exp_freq: float, line_color: String = "red"):
	self.set_unique_name(name)
	self.set_unit(unit)
	self.set_description(description)
	self.set_min(min)
	self.set_max(max)
	self.set_line_color_str(line_color)
	self.set_line_color(line_color)
	self.set_frequency(exp_freq)
