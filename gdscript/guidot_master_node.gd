class_name Guidot_Master_Node
extends ColorRect

signal graph_buffer_mode_changed

const LOG_DEBUG   = Guidot_Log.Log_Level.DEBUG
const LOG_INFO    = Guidot_Log.Log_Level.INFO
const LOG_WARNING = Guidot_Log.Log_Level.WARNING
const LOG_ERROR   = Guidot_Log.Log_Level.WARNING

const Graph_Buffer_Mode = Guidot_Common.Graph_Buffer_Mode

var _graph_buffer_mode: Graph_Buffer_Mode = Graph_Buffer_Mode.REALTIME

var _component_tag: String = "MASTER_NODE"

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, self._component_tag, msg)

func set_graph_buffer_mode(buf_mode: Graph_Buffer_Mode) -> void:
	_graph_buffer_mode = buf_mode
	graph_buffer_mode_changed.emit()

func get_graph_buffer_mode() -> Graph_Buffer_Mode:
	return _graph_buffer_mode

func _ready() -> void:
	self.log(LOG_INFO, ["Hello from Guidot Master"])

func _process(delta: float) -> void:
	pass
