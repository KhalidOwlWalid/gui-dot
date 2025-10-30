class_name Guidot_Data

var _name: String = ""
var _description: String = ""
var _unit: String = ""

var _metadata: Dictionary = {
	"unique_name": "",
	"unique_id": self.get_instance_id(),
	"description": "",
	"unit": "",
	"data_name": "",
}

func _set_metadata(name: String, unit: String, description: String) -> void:
	self._metadata["unique_name"] = name
	self._metadata["data_name"] = name
	self._metadata["unit"] = unit
	self._metadata["description"] = description

func setup_properties(name: String, unit: String, description: String):
	self._name = name
	self._unit = unit
	self._description = description
	self._set_metadata(self._name, self._unit, self._description)

func get_name() -> String:
	return self._name

func get_description() -> String:
	return self._description

func get_unit() -> String:
	return self._unit

func get_unique_id() -> int:
	return self._metadata["unique_id"]
