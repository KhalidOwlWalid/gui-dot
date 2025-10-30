class_name Guidot_Data_Core
extends Node

@onready var frequency: float = 0
@onready var unit: String = ""
@onready var description: String = ""

var _metadata: Dictionary = {
	"unique_name": "",
	"unique_id": self.get_instance_id(),
	"description": "",
	"unit": "",
	"data_name": "",
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
