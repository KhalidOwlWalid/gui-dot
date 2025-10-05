@tool
class_name Guidot_T_Series_Graph
extends Guidot_Common

const Guidot_Axis := preload("res://gdscript/components/axis/guidot_axis.gd")
const Guidot_Y_Axis := preload("res://gdscript/components/axis/guidot_y_axis.gd")
const Guidot_T_Axis := preload("res://gdscript/components/axis/guidot_t_axis.gd")
const Guidot_Plot := preload("res://gdscript/components/guidot_plot.gd")
const Guidot_Line := preload("res://gdscript/components/guidot_line.gd")
const Guidot_Data_Core := preload("res://gdscript/components/guidot_data.gd")

@onready var color_dict: Dictionary = Guidot_Utils.color_dict

# Property of the graph
var window_size: Vector2
var window_color: Color

# Note (Khalid): For now, I wish to standardize the font throughout the whole node
# This may bite me in the future, if for some reason, I wish to have different fonts
# for different parts of the graph, but I kinda doubt that would happen
@onready var font_node: SystemFont = SystemFont.new()

# TODO (Khalid): This should only be temporary for prototyping, but the plugin is created
# I need to find a better way to interface this
@onready var mavlink_node = get_node('/root/Control/Mavlink_Node')
@onready var guidot_master_node = get_node('/root/Control/Guidot_Master_Node')

@onready var default_window_size: Vector2 = Vector2(620, 360)
@onready var default_window_color: Color = color_dict["gd_black"]
@onready var prev_display_color: Color = default_window_color

# Components used for building the graph 
@onready var plot_node: Guidot_Plot = Guidot_Plot.new()
@onready var y_axis_node: Guidot_Axis = Guidot_Y_Axis.new()
@onready var t_axis_node: Guidot_Axis = Guidot_T_Axis.new()

# Toggle switch
@onready var _toggle_nerd_stats: bool = false
@onready var _is_pause: bool = false

@export_group("X-Axis")
@export var t_axis_min: float = 1
@export var t_axis_max: float = 30
@export var x_number_of_ticks: int = 10

@export_group("Y-Axis")
@export var y_axis_min: float = 0
@export var y_axis_max: float = 1
@export var y_number_of_ticks: int = 10

var _current_buffer_mode: Graph_Buffer_Mode

# Helper tool
var debug_panel: Guidot_Debug_Panel

signal parent_focus_requested

# Final debug trace signals are used to encapsulate all of the debug tace signals of each of our components
@onready var final_debug_trace_signals: Dictionary = {}

#### SIGNAL TRACE #####
@onready var mouse_pressed_flag: bool = false

func update_debug_info() -> void:
	self.debug_signals_to_trace = {
		# "Current buffer Mode": self.get_buffer_mode_str(self._current_buffer_mode),
		# "t_axis": str(Vector2(t_axis_min, t_axis_max)),
		# "y_axis": str(Vector2(y_axis_min, y_axis_max)),
		# "Last Data": str(get_last_data_point()),
		# "Current Fetch Mode": get_current_data_fetch_mode_str(),
		# "Preprocess data size": str(plot_node.n_preprocessed_data),
		# "Postprocess data size": str(plot_node.n_postprocessed_data),
		# "Head Position": str(plot_node.head_vec2),
		# "Tail Position": str(plot_node.tail_vec2),
		# "mouse pressed": str(mouse_pressed_flag),
		"Graph: mouse in": self._mouse_in,
		"Graph: in focus": self._is_in_focus,
		"Graph: mouse filter": self.get_mouse_filter()
	}
	# self.debug_signals_to_trace = self.debug_signals_to_trace

func _update_final_debug_trace() -> void:
	self.update_debug_info()
	plot_node.update_debug_info()
	t_axis_node.update_debug_info()
	self.final_debug_trace_signals.clear()

	# TODO (Khalid): At the moment, I am leaving this hard-coded because this isn't really a user feature
	# Only developer should be using this
	var child_array: Array[Guidot_Common] = [self, plot_node, t_axis_node] 

	for child in child_array:
		for debug_signal in child.debug_signals_to_trace:
			self.final_debug_trace_signals[debug_signal] = child.debug_signals_to_trace[debug_signal]

# WARNING: This is temporary for testing the debug info

### HELPER FUNCTIONS #####
func get_last_data_point() -> Vector2:
	var tmp: Vector2 = Vector2()
	if (mavlink_node.data == null):
		return tmp
	elif (mavlink_node.data.size() == 0):
		return tmp
	else:
		tmp = mavlink_node.data[-1]
	return tmp

func get_current_data_fetch_mode_str() -> String:
	return plot_node.data_fetching_mode_str[plot_node.data_fetching_mode]

##########################

func get_buffer_mode_str(buf_mode: Graph_Buffer_Mode) -> String:
	match buf_mode:
		Graph_Buffer_Mode.FIXED:
			return "Fixed"
		Graph_Buffer_Mode.REALTIME:
			return "Realtime"
		_:
			return "Not Implemented"

func setup_plot_node() -> void:
	plot_node.init_plot(color_dict["gd_black"])
	plot_node.setup_plot(Vector2(self.size.x, self.size.y), Vector2(t_axis_node.norm_comp_size, y_axis_node.norm_comp_size))

func init_plot_node():
	setup_plot_node()
	add_child(plot_node)

func setup_axis(axis_node: Guidot_Axis, axis_name: String, axis_color: Color, axis_min: float, axis_max: float) -> void:
	axis_node.setup_axis_limit(axis_min, axis_max)
	axis_node.calculate_offset_from_plot_frame(self, plot_node)

func init_axis(axis_node: Guidot_Axis, axis_name: String, axis_color: Color, axis_min: float, axis_max: float) -> void:
	axis_node.setup_axis_node(axis_name, axis_color)
	axis_node.setup_axis_limit(axis_min, axis_max)
	axis_node.calculate_offset_from_plot_frame(self, plot_node)

func init_t_axis_node():
	init_axis(t_axis_node, "t_axis", color_dict["gd_black"], t_axis_min, t_axis_max)
	add_child(t_axis_node)

func init_y_axis_node():
	init_axis(y_axis_node, "y_axis", color_dict["gd_black"], y_axis_min, y_axis_max)
	add_child(y_axis_node)

func setup_font() -> void:
	pass

func init_font() -> void:
	setup_font()

func _register_hotkeys() -> void:
	# Input action mapping
	Guidot_Utils.add_action_with_keycode("help", KEY_H)
	Guidot_Utils.add_action_with_keycode("nerd_stats", KEY_TAB)
	Guidot_Utils.add_action_with_keycode("pause", KEY_SPACE)

func _request_buffer_mode() -> void:
	self._current_buffer_mode = guidot_master_node.get_graph_buffer_mode()
	self.log(LOG_INFO, ["Current buffer mode: ", self.get_buffer_mode_str(self._current_buffer_mode)])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.name = "Graph_Display"
	self.log(LOG_INFO, [mavlink_node])
	self.clip_contents = true
	self.size = default_window_size
	self.color = default_window_color
	self._component_tag = "DISPLAY"
	
	# Add child node for the graph
	init_plot_node()
	# X/Y axis rectangle anchor offset calculation depends on the plot node anchor offset maths
	# Hence, plot node needs to be ran first before we run the axis node init
	init_t_axis_node()
	init_y_axis_node()
	init_font()

	plot_node.update_x_ticks_properties(t_axis_node.n_steps, t_axis_node.ticks_pos)
	plot_node.update_y_ticks_properties(y_axis_node.n_steps, y_axis_node.ticks_pos)

	##########################
	#         SIGNAL         #
	##########################

	# Data oriented signal
	# TODO (Khalid): Remove the use of mavlink node. Data server node should not be internally handled here but should be handled by the master
	mavlink_node.data_received.connect(_on_data_received)
	guidot_master_node.graph_buffer_mode_changed.connect(_on_graph_buffer_mode_changed)

	# Axis node signal
	t_axis_node.axis_limit_changed.connect(_on_t_axis_changed)
	y_axis_node.axis_limit_changed.connect(_on_y_axis_changed)

	plot_node.focus_requested.connect(_on_focus_requested)
	# self.focus_requested.connect(_on_focus_requested)
	
	# Self node signal
	self.resized.connect(_on_display_frame_resized)
	
	# Use the guidot common mouse entered implementation
	self.mouse_entered.connect(self._on_mouse_entered)
	self.mouse_exited.connect(self._on_mouse_exited)

	self._register_hotkeys()
	self._request_buffer_mode()
	
	debug_panel = Guidot_Debug_Panel.new()
	add_child(debug_panel)

	# This needs to be overriden after the debug panel is added as a child to the graph
	self._update_final_debug_trace()
	debug_panel.override_guidot_debug_info(self.final_debug_trace_signals)

	self.log(LOG_INFO, ["Time series graph initialized"])

	queue_redraw()

# TODO: Implement this with error detection
func set_window_color(color: Color) -> void:
	self.color = color

func _draw():
	# Data line drawing is handled inside the _draw function of plot_node
	y_axis_node.draw_axis()
	t_axis_node.draw_axis()

func _on_display_frame_resized() -> void:
	setup_plot_node()
	setup_axis(y_axis_node, "y_axis", y_axis_node.color, y_axis_min, y_axis_max)
	setup_axis(t_axis_node, "t_axis", t_axis_node.color, t_axis_min, t_axis_max)
	self.log(LOG_DEBUG, ["Display frame resized"])

########################################
#    SIGNAL CALLBACK IMPLEMENTATION    #
########################################
func _on_data_received() -> void:
	if (not self._is_pause):
		t_axis_min = t_axis_node.min_val
		t_axis_max = t_axis_node.max_val
		plot_node.plot_data(mavlink_node.data, Vector2(t_axis_min, t_axis_max), Vector2(y_axis_min, y_axis_max))
		queue_redraw()

func _on_graph_buffer_mode_changed() -> void:
	pass

func _on_focus_requested() -> void:
	self._is_in_focus = !self._is_in_focus
	self.parent_focus_requested.emit()

func _on_t_axis_changed() -> void:
	t_axis_min = t_axis_node.min_val
	t_axis_max = t_axis_node.max_val
	plot_node.update_x_ticks_properties(t_axis_node.n_steps, t_axis_node.ticks_pos)
	plot_node.plot_data(mavlink_node.data, Vector2(t_axis_min, t_axis_max), Vector2(y_axis_min, y_axis_max))

func _on_y_axis_changed() -> void:
	y_axis_min = y_axis_node.min_val
	y_axis_max = y_axis_node.max_val
	plot_node.update_y_ticks_properties(y_axis_node.n_steps, y_axis_node.ticks_pos)
	plot_node.plot_data(mavlink_node.data, Vector2(t_axis_min, t_axis_max), Vector2(y_axis_min, y_axis_max))

func _nerd_stats_panel_update():
	if (self._toggle_nerd_stats):
		pass

func _input(event: InputEvent) -> void:

	# if (self._mouse_in):
	if event is InputEventMouseButton:
		
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				# TODO (Khalid): At the moment, this does not work because if we click on the plot,
				# the display also captures this signal, resulting in "double emit focus" signal generated
				# self._emit_focus_requested_signal()
				if (self._is_in_focus):
					plot_node._is_in_focus = false
				pass
	
	# For hotkeys
	if (Input.is_action_just_pressed("nerd_stats")):
		self._toggle_nerd_stats = !self._toggle_nerd_stats
		self.log(LOG_INFO, ["Toggle for nerd stats:", self._toggle_nerd_stats])

		if (self._toggle_nerd_stats):
			var curr_mouse_pos: Vector2 = self.get_viewport().get_mouse_position()
			debug_panel.set_position(curr_mouse_pos)
			debug_panel.show()
		else:
			debug_panel.hide()

	if (Input.is_action_just_pressed("pause")):
		self._is_pause = !self._is_pause
		self.log(LOG_DEBUG, ["Last data value: ", mavlink_node.data[-1].x, ", ", mavlink_node.data[-1].y])
		self.log(LOG_INFO, ["Pause button pressed: ", self._is_pause])

func _physics_process(delta: float) -> void:
	self._move_display_process()

	# If the current buffer mode is fixed, then only update when the user changes the axis limits
	match (self._current_buffer_mode):

		Graph_Buffer_Mode.FIXED:
			pass
	
		# When handling real-time data, we want to be able to update the last tick to always be incrementing
		# based on the last value data it receives, but to make a smooth sliding window, we will have to
		# smoothly shift the ticks in between the min and max value
		# In principle, the min val should stay constant unless the user specifies any desired min axis value,
		# and the max axis value will keep moving
		Graph_Buffer_Mode.REALTIME:
			# If there is no data present at the moment, then we ignore it
			if (mavlink_node.data.is_empty()):
				pass
			else:
				var moving_max_tick: bool = mavlink_node.data[-1].x > t_axis_node.max_val
				if (not self._is_pause):
					# The way that I wish to implement this is by having the minimum and maximum t-axis to be always an
					# even number
					# TODO (Khalid): Allow the user to use external clock source, the way that this is currently implemented
					# is that the time series graph itself generates the clock, so if the user wish to plot and visualize
					# their data in realtime, they will have to use Time.get_ticks_msec() function to have the correct
					# scale. The external clock source would allow the time axis to be a lot more flexble in a sense that it can be
					# simply an increasing integer, or absolute or relative time etc.
					var curr_s: float = float(Time.get_ticks_msec())/1000
					t_axis_node.setup_axis_limit(curr_s - t_axis_node._sliding_window_s, curr_s)

	if (not self._is_pause):
		self._update_final_debug_trace()
		self.debug_panel._guidot_debug_info = self.final_debug_trace_signals	

	if (self._is_in_focus):
		# Allow the master panel to be able to see the entire mouse movement within the whole node
		self.set_mouse_filter(MOUSE_FILTER_IGNORE)
		plot_node.set_mouse_filter(MOUSE_FILTER_IGNORE)
	else:
		self.set_mouse_filter(MOUSE_FILTER_STOP)
		plot_node.set_mouse_filter(MOUSE_FILTER_STOP)
