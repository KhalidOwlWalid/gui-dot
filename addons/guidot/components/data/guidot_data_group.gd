class_name Guidot_Data_Group

var _name: String = ""
var _description: String = ""
var _channels: Array[Guidot_Data] = []

func setup(group_name: String, description: String = "") -> Guidot_Data_Group:
	_name = group_name
	_description = description
	return self

func add_channel(channel: Guidot_Data) -> Guidot_Data_Group:
	_channels.append(channel)
	return self

func get_channels() -> Array[Guidot_Data]:
	return _channels

func get_name() -> String:
	return _name

func get_description() -> String:
	return _description
