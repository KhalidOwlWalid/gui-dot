class_name Guidot_Data

# Name of the channel
# TODO (Khalid): At the moment, the channel name is used for both unique name and data name
# Data name is supposed to be editable, but not unique name
var _name: String = ""
# Description of what the data is meant for
var _description: String = ""
# Unit of the data
var _unit: String = ""
# Color of the line on the plot
var _line_color: Color = Color.RED
var _line_color_str: String = "red"
# Minimum expected value from this data
var _min: float = 0
# Maximum expected value from this data
var _max: float = 1
# Frequency/update rate of the data
var _freq: float = 60.0
# # Axis can be either left or right on the plot
# var _axis_pos: Guidot_Y_Axis.AxisPosition = Guidot_Y_Axis.AxisPosition.LEFT
var _axis_n: int = 1
# Which axis it should be plotted on
var _axis_id: Guidot_Y_Axis.AxisPosition = Guidot_Y_Axis.AxisPosition.PRIMARY_LEFT


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
	# "axis_pos": self._axis_pos,
	"axis_n": self._axis_n,
	"axis_id": self._axis_id,
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
	self._line_color = Guidot_Utils.get_color(self._line_color_str)
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

func set_axis_id(ax_id: Guidot_Y_Axis.AxisPosition) -> void:
	self._axis_id = ax_id
	self._metadata["axis_id"] = self._axis_id

# func set_axis_pos(ax_pos: Guidot_Y_Axis.AxisPosition) -> void:
# 	self._axis_pos = ax_pos
# 	self._metadata["axis_pos"] = self._axis_pos
# 	# For now, I am making the assumption that this will correctly cast it to an existing enum
# 	self._axis_id = self._axis_pos * self._axis_n

# func set_axis_number(ax_n: int) -> void:
# 	self._axis_n = ax_n
# 	self._metadata["axis_n"] = self._axis_n
# 	# For now, I am making the assumption that this will correctly cast it to an existing enum
# 	self._axis_id = self._axis_pos * self._axis_n

func line_color_options() -> Dictionary:
	return self._color_options

# Getters
func get_line_color() -> Color:
	return self._line_color

func get_line_color_str() -> String:
	return self._line_color_str

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

func get_axis_id() -> Guidot_Y_Axis.AxisPosition:
	return self._axis_id

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
