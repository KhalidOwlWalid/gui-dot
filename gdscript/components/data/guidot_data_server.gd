# @tool
class_name Guidot_Data_Server
extends Guidot_Data_Core

signal connected
signal disconnected

@onready var _data_clients: Array[int] = []
@onready var _data_clients_dict: Dictionary = {}

func _ready() -> void:
	self.name = Guidot_Utils.generate_unique_name(self, self._server_group_name)
	self.add_to_group(self._server_group_name)

	# TODO (Khalid): Error handling, if the node does not exist in the group, then server should be responsible in creating one
	var clock_nodes: Array[Node] = self.get_tree().get_nodes_in_group(Guidot_Clock._clock_group_name)
	self._clock_node = clock_nodes[0]
	print(self._clock_node.get_current_time_ms())

# TODO (Khalid): Error handling to check if it is a duplicate
func register_client(client_unique_id: int) -> bool:
	self._data_clients.append(client_unique_id)
	self._data_clients_dict[client_unique_id] = PackedVector2Array()
	return true

func add_data_point(client_unique_id: int, data: float) -> void:
	self._data_clients_dict[client_unique_id].append(Vector2(self._clock_node.get_current_time_s(), data))
	print(self._data_clients_dict[client_unique_id])

func _physics_process(delta: float) -> void:
	# print("Test")
	pass
