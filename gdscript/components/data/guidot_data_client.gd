# @tool
class_name Guidot_Data_Client
extends Guidot_Data_Core

const LOG_DEBUG = Guidot_Log.Log_Level.DEBUG
const LOG_WARNING = Guidot_Log.Log_Level.WARNING
const LOG_INFO = Guidot_Log.Log_Level.INFO
const LOG_ERROR = Guidot_Log.Log_Level.ERROR

var _server_nodepath: NodePath
var _server_node: Node
var _update_rate_hz: float
@onready var _unique_id: int = self.get_instance_id()

@onready var _is_connected_to_server: bool = false
@onready var _comp_tag: String = "GUIDOT_DATA_CLIENT"

func _ready() -> void:
	self.init_client()
	self.scan_for_server()
	
func scan_for_server() -> void:
	var server_nodes: Array[Node] = self.get_all_guidot_server()

	if (server_nodes.is_empty()):
		self.log(LOG_WARNING, ["No available guidot server to attach the client to."])
	else:
		self.log(LOG_INFO, [server_nodes.size(), "instance(s) of Guidot Server found."])
		
		# For now, we are going to grab the first server we see.
		# In the future, we may want to allow the user to be able to select servers that they wish to listen to.
		self._server_node = server_nodes[0]
		self.log(LOG_INFO, ["Connected to server", self._server_node])

		if (self._server_node.register_client(self.get_unique_id())):
			self.log(LOG_INFO, ["Successfully registered", self.name, "to", self._server_node.name])

func init_client() -> void:
	self.name = Guidot_Utils.generate_unique_name(self, Guidot_Common._client_group_name)
	self.add_to_group(Guidot_Common._client_group_name)

func _on_server_connected() -> void:
	self.log(LOG_INFO, ["Server connected"])

func set_path_to_server(server_nodepath: NodePath):
	self._server_nodepath = server_nodepath

func set_update_rate_hz(freq: float) -> void:

	# Guidot Data Client is meant for the usage of Godot's node where the data is usually updated within the
	# process loop. The process loop runs at a maximum of 60 Hz by default.
	# This however, can be changed in the settings by going to
	# Project > Project Settings > General > Common > Physics ticks per second
	# TODO (Khalid): Allow the user to configure this before runtime
	if (freq > 60):
		self._update_rate_hz = 60
		self.log(LOG_WARNING, ["Guidot Data Client only supports up to 60 Hz. Update rate now clamped at 60 Hz."])
	else:
		self._update_rate_hz = freq

func _physics_process(delta: float) -> void:
	pass

# TODO (Khalid): Error handling if data point is not compatible (e.g string)
func add_data_point(data_point) -> void:
	self._server_node.add_data_point(self.get_instance_id(), data_point)

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, self._comp_tag, msg)
