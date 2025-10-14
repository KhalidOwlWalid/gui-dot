# @tool
class_name Guidot_Data_Server
extends Guidot_Data_Core

signal connected
signal disconnected

const LOG_DEBUG = Guidot_Log.Log_Level.DEBUG
const LOG_WARNING = Guidot_Log.Log_Level.WARNING
const LOG_INFO = Guidot_Log.Log_Level.INFO
const LOG_ERROR = Guidot_Log.Log_Level.ERROR

# Keeps record of the unique id assigned to each client
@onready var _client_manager: Array[int] = []
@onready var _client_data_manager: Dictionary = {}

@onready var _comp_tag: String = "GUIDOT_DATA_SERVER"

func _ready() -> void:
	self.name = Guidot_Utils.generate_unique_name(self, self._server_group_name)
	self.add_to_group(self._server_group_name)

	# TODO (Khalid): Error handling, if the node does not exist in the group, then server should be responsible in creating one
	var clock_nodes: Array[Node] = self.get_tree().get_nodes_in_group(Guidot_Clock._clock_group_name)
	self._clock_node = clock_nodes[0]

# TODO (Khalid): Error handling to check if it is a duplicate
func register_client(client_unique_id: int) -> bool:
	self._client_manager.append(client_unique_id)
	self._client_data_manager[client_unique_id] = PackedVector2Array()
	return true

func add_data_point(client_unique_id: int, data: float) -> void:
	self._client_data_manager[client_unique_id].append(Vector2(self._clock_node.get_current_time_s(), data))

func _physics_process(delta: float) -> void:
	# print("Test")
	pass

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, self._comp_tag, msg)
