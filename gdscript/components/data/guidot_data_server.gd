# @tool
class_name Guidot_Data_Server
extends Guidot_Data_Core

signal connected
signal disconnected
signal graph_buffer_mode_changed
signal new_data_received

const LOG_DEBUG = Guidot_Log.Log_Level.DEBUG
const LOG_WARNING = Guidot_Log.Log_Level.WARNING
const LOG_INFO = Guidot_Log.Log_Level.INFO
const LOG_ERROR = Guidot_Log.Log_Level.ERROR

# Stores the respective client name to its instance id for easy access
@onready var _client_id_manager: Dictionary = {}

# Stores all data channels (instance ID) related to the client's instance ID
@onready var _client_data_manager: Dictionary = {}

# Stores the data points for each channel according to its data channel node instance ID
@onready var _data_channel_manager: Dictionary = {}

# Stores the unique name as key and Guidot_Data node as value for ease of reference
# e.g. {"data_channel1": Guidot_Data<unique_id>}
@onready var _data_channel_id_manager: Dictionary = {}

const Graph_Buffer_Mode = Guidot_Common.Graph_Buffer_Mode
var _graph_buffer_mode: Graph_Buffer_Mode = Graph_Buffer_Mode.REALTIME

@onready var _comp_tag: String = "GUIDOT_DATA_SERVER"

func _ready() -> void:
	self.name = Guidot_Utils.generate_unique_name(self, Guidot_Common._server_group_name)
	self.add_to_group(Guidot_Common._server_group_name)

	# TODO (Khalid): Error handling, if the node does not exist in the group, then server should be responsible in creating one
	var clock_nodes: Array[Node] = self.get_tree().get_nodes_in_group(Guidot_Common._clock_group_name)
	self._clock_node = clock_nodes[0]

func set_graph_buffer_mode(buf_mode: Graph_Buffer_Mode) -> void:
	_graph_buffer_mode = buf_mode
	graph_buffer_mode_changed.emit()

func get_graph_buffer_mode() -> Graph_Buffer_Mode:
	return _graph_buffer_mode

func get_all_registered_clients() -> Dictionary:
	return self._client_id_manager

# TODO (Khalid): Error handling to check if it is a duplicate
func register_client(node: Guidot_Data_Client) -> bool:
	self._client_id_manager[node.name] = node	
	return true

func get_channel_id(channel_name: String) -> Guidot_Data:
	return self._data_channel_id_manager[channel_name]

# Returns the data points for the specified channel name
func query_data_with_channel_name(channel_name: String) -> PackedVector2Array:
	# Use the channel mapping to get the correct node ID
	for data_channel_name in self._data_channel_id_manager.keys():
		if (data_channel_name == channel_name):
			return self._data_channel_manager[self.get_channel_id(channel_name)]
		else:
			self.log(LOG_WARNING, ["The chosen channel name, [", channel_name, "] does not exist. Returning empty dataset."])
			return PackedVector2Array()
	return PackedVector2Array()

func query_data_line_color(channel_name: String) -> Color:
	var channel_id: Guidot_Data = self._data_channel_id_manager[channel_name]
	return channel_id.get_line_color()

func query_data_with_node_id(data_node: Guidot_Data) -> void:
	var data_channel: Guidot_Data = self._data_channel_manager[data_node]

func get_node_id_with_channel_name(channel_name: String) -> Guidot_Data:
	return self._data_channel_id_manager[channel_name] 

func update_channel_manager(node: Guidot_Data_Client) -> bool:
	for data_node_id in node.get_all_data_channels().keys():
		var data_channel_name: String = node.get_data_channel_name(data_node_id)
		self._data_channel_manager[data_node_id] = PackedVector2Array()
		self._data_channel_id_manager[data_channel_name] = data_node_id
	return true

func add_data_point(data_channel_node: Guidot_Data, data_point: float) -> void:
	self._data_channel_manager[data_channel_node].append(Vector2(self._clock_node.get_current_time_s(), data_point))
	self.new_data_received.emit()

func _physics_process(delta: float) -> void:
	pass

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, self.name, msg)
