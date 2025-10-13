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
	self.generate_unique_name("Guidot_Data_Client")
	self.add_to_group(self._client_group_name)
	self.log(LOG_INFO, [self.get_tree().get_nodes_in_group(self._client_group_name)])
	self.log(LOG_INFO, [self.get_tree().get_nodes_in_group(self._server_group_name)])

func _on_server_connected() -> void:
	self.log(LOG_INFO, ["Server connected"])

func _physics_process(delta: float) -> void:
	pass

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

func scan_for_data_server() -> void:
	pass

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, self._comp_tag, msg)
