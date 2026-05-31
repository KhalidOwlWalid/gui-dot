class_name Guidot_Data_Core
extends Node

@onready var frequency: float = 0
@onready var unit: String = ""
@onready var description: String = ""

var _metadata: Dictionary = {
	# Unique names are internally used by the backend to determine the correct use of node
	# along with its unique ID
	"unique_name": "",
	"unique_id": self.get_instance_id(),
	"description": "",
	"unit": "",
	# Customized name are metadata for the user of the user to get more personalized naming
	# options that make sense to them
	"custom_name": "",
	"type": "",
}

enum ClockSourceType {
	GUIDOT_CLOCK,
	EXTERNAL_CLOCK,
}

var _clock_node: Node
@onready var _clock_src_type: ClockSourceType = ClockSourceType.GUIDOT_CLOCK

func get_metadata() -> Dictionary:
	return self._metadata

func set_unique_name(unique_name: String) -> void:
	self.name = unique_name
	self._metadata["unique_name"] = unique_name

func set_type(type: String) -> void:
	self._metadata["type"] = type

func set_custom_name(new_name: String) -> void:
	self._metadata["custom_name"] = new_name

func get_custom_name() -> String:
	return self._metadata["custom_name"]

func get_unique_name() -> String:
	return self._metadata["unique_name"]

func set_unique_id() -> void:
	self._metadata["unique_id"] = self.get_instance_id()

func get_unique_id() -> int:
	return self._metadata["unique_id"]

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func set_unit(unit: String) -> void:
	self._metadata["unit"] = unit

func get_unit() -> String:
	return self._metadata["unit"]

func set_description(description: String) -> void:
	self._metadata["description"] = description

func get_description() -> String:
	return self._metadata["description"]

func set_frequency(freq: float) -> void:
	pass

func get_freqeuncy() -> float:
	return 0

func get_all_guidot_clients() -> Array[Node]:
	return self.get_tree().get_nodes_in_group(Guidot_Common._client_group_name)

func get_all_guidot_server() -> Array[Node]:
	return self.get_tree().get_nodes_in_group(Guidot_Common._server_group_name)

func _process(delta: float) -> void:
	pass
