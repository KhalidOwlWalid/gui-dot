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

@export var _custom_server_name: String = ""

# Stores the respective client name to its instance id for easy access
@onready var _client_id_manager: Dictionary = {}

# Stores all data channels (instance ID) related to the client's instance ID
@onready var _client_data_manager: Dictionary = {}

# Stores the data points for each channel according to its data channel node instance ID
@onready var _data_channel_manager: Dictionary = {}

# Stores the unique name as key and Guidot_Data node as value for ease of reference
# e.g. {"data_channel1": Guidot_Data<unique_id>}
@onready var _data_channel_id_manager: Dictionary = {}
@onready var _guidot_error_popup: Guidot_Error_Popup = Guidot_Error_Popup.new()

const Graph_Buffer_Mode = Guidot_Common.Graph_Buffer_Mode
var _graph_buffer_mode: Graph_Buffer_Mode = Graph_Buffer_Mode.REALTIME

@onready var _comp_tag: String = "GUIDOT_DATA_SERVER"

func _ready() -> void:
	self.name = Guidot_Utils.generate_unique_name(self, Guidot_Common._server_group_name)
	self.set_custom_name(self._custom_server_name)
	self.set_type(Guidot_Common._server_group_name)
	self.add_to_group(Guidot_Common._server_group_name)

	self.get_tree().root.add_child.call_deferred(self._guidot_error_popup)

func set_graph_buffer_mode(buf_mode: Graph_Buffer_Mode) -> void:
	_graph_buffer_mode = buf_mode
	graph_buffer_mode_changed.emit()

func get_graph_buffer_mode() -> Graph_Buffer_Mode:
	return _graph_buffer_mode

func get_all_registered_clients() -> Dictionary:
	return self._client_id_manager

func get_custom_name() -> String:
	return self._metadata["custom_name"]

# TODO (Khalid): Error handling to check if it is a duplicate
func register_client(node: Guidot_Data_Source) -> bool:
	self._client_id_manager[node.name] = node	
	return true

func get_channel_id(channel_name: String) -> Guidot_Data:
	return self._data_channel_id_manager[channel_name]

# Returns the data points for the specified channel name
func query_data_with_channel_name(channel_name: String) -> PackedVector2Array:
	# Use the channel mapping to get the correct node ID
	var has_key: bool = self._data_channel_id_manager.has(channel_name)

	if (has_key):
		return self._data_channel_manager[self.get_channel_id(channel_name)]
	else:
		var gd_error: Guidot_Error = Guidot_Error.new()
		var error_msg: String = "The chosen channel name, [" + channel_name + "] does not exist. Returning empty dataset."
		gd_error.generate_error(Error.ERR_DOES_NOT_EXIST, error_msg, str(self), "query_data_with_channel_name")
		self._guidot_error_popup.generate_popup(gd_error)
		self.log(LOG_WARNING, [error_msg])
	return PackedVector2Array()

func query_data_line_color(channel_name: String) -> Color:
	var channel_id: Guidot_Data = self._data_channel_id_manager[channel_name]
	return channel_id.get_line_color()

func query_data_with_node_id(data_node: Guidot_Data) -> PackedVector2Array:
	var data_channel: PackedVector2Array = self._data_channel_manager[data_node]
	return data_channel

func get_node_id_with_channel_name(channel_name: String) -> Guidot_Data:
	return self._data_channel_id_manager[channel_name] 

# TODO: This needs to be refactored to utilize the client properly
# What I am doing now is simply storing all of the information on the server side completely?
func update_channel_manager(node: Guidot_Data_Source) -> bool:
	for data_node_ptr in node.get_all_data_channels().keys():
		var data_channel_name: String = node.get_data_channel_name(data_node_ptr)
		self._data_channel_manager[data_node_ptr] = PackedVector2Array()
		self._data_channel_id_manager[data_channel_name] = data_node_ptr
	return true

func add_data_point(data_channel_node: Guidot_Data, data_point: float) -> void:
	self._data_channel_manager[data_channel_node].append(Vector2(Guidot_Clock.get_current_time_s(), data_point))
	self.new_data_received.emit()

func _physics_process(delta: float) -> void:
	pass

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, self.name, msg)
