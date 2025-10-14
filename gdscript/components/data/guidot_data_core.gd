@tool
class_name Guidot_Data_Core
extends Node

@onready var frequency: float = 0
@onready var unit: String = ""
@onready var description: String = ""

# WARNING: This should not be changed by the user
@onready var _server_group_name: String = "Guidot_Server"
@onready var _client_group_name: String = "Guidot_Client"
@onready var _clock_group_name: String = "Guidot_Clock"

enum ClockSourceType {
	GUIDOT_CLOCK,
	EXTERNAL_CLOCK,
}

var _clock_node: Node
@onready var _clock_src_type: ClockSourceType = ClockSourceType.GUIDOT_CLOCK

@onready var _metadata: Dictionary = {
	"unique_name": self.name,
	"unique_id": self.get_instance_id(),
	"description": "",
	"unit": "",
	"data_name": "",
}

func get_unique_name() -> String:
	return self._metadata["unique_name"]

func get_unique_id() -> int:
	return self._metadata["unique_id"]

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func set_unit(unit: String) -> void:
	pass

func get_unit() -> String:
	return String()

func set_description(description: String) -> void:
	pass

func get_description() -> String:
	return String()

func set_frequency(freq: float) -> void:
	pass

func get_freqeuncy() -> float:
	return 0

func get_all_guidot_clients() -> Array[Node]:
	return self.get_tree().get_nodes_in_group(self._client_group_name)

func get_all_guidot_server() -> Array[Node]:
	return self.get_tree().get_nodes_in_group(self._server_group_name)
