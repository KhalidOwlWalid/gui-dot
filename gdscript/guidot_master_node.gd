class_name Guidot_Master_Node
extends ColorRect

signal graph_buffer_mode_changed

enum Graph_Buffer_Mode {
	FIXED,      # If user wants to display a set window span. User will have to manually reset the time axes
	SNAPSHOT,   # Alias of fixed (thats the plan for now)
	REALTIME,  # Usually use for real-time DAQ. (aka sliding window). Will use a lot of memory since new data will be pushed back.
	MOVING_PAGE, # Opens up a new "page" everytime the data passes the max axis limit
}

const LOG_DEBUG   = Guidot_Log.Log_Level.DEBUG
const LOG_INFO    = Guidot_Log.Log_Level.INFO
const LOG_WARNING = Guidot_Log.Log_Level.WARNING
const LOG_ERROR   = Guidot_Log.Log_Level.WARNING

@onready var _graph_buffer_mode: Graph_Buffer_Mode = Graph_Buffer_Mode.FIXED

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, msg)

func set_graph_buffer_mode(buf_mode: Graph_Buffer_Mode) -> void:
	_graph_buffer_mode = buf_mode
	graph_buffer_mode_changed.emit()

func get_graph_buffer_mode() -> Graph_Buffer_Mode:
	return _graph_buffer_mode

func _ready() -> void:
	self.log(LOG_INFO, ["Hello from Guidot Master"])

func _process(delta: float) -> void:
	# Guidot_Log.gd_log(LOG_INFO, ["Hello from Guidot Master"])
	pass
