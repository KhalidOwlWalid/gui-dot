# @tool
class_name Guidot_T_Series_Graph
extends Guidot_Common

# Property of the graph
var window_size: Vector2
var window_color: Color

# Note (Khalid): For now, I wish to standardize the font throughout the whole node
# This may bite me in the future, if for some reason, I wish to have different fonts
# for different parts of the graph, but I kinda doubt that would happen
@onready var font_node: SystemFont = SystemFont.new()

# TODO (Khalid): This should only be temporary for prototyping, but the plugin is created
# I need to find a better way to interface this
var _guidot_server: Guidot_Data_Server
var _curr_data_str: String
var _selected_channels_name: Array
@onready var _guidot_clock_node: Guidot_Clock = self.get_tree().get_nodes_in_group(Guidot_Common._clock_group_name)[0]
# TODO: Remove this, since at the moment, without mouse_x being initialized, it breaks
@onready var _graph_manager: Guidot_Graph_Manager = Guidot_Graph_Manager.new()

@onready var default_window_size: Vector2 = Vector2(620, 360)
@onready var default_window_color: Color = Guidot_Utils.get_color("gd_black")
@onready var prev_display_color: Color = default_window_color

# Components used for building the graph 
@onready var plot_node: Guidot_Plot = Guidot_Plot.new()
@onready var t_axis_node: Guidot_T_Axis = Guidot_T_Axis.new()

class AxisHandler:
	var _axis_id: Guidot_Y_Axis.AxisID
	var _axis_node: Guidot_Y_Axis
	var _in_use: bool

	func init_axis(parent: Node, axis_id: Guidot_Y_Axis.AxisID, min_max: Vector2, in_use: bool = false):
		self._axis_node = Guidot_Y_Axis.new()
		self._axis_node.setup_axis_limit(min_max.x, min_max.y)
		self._axis_id = axis_id
		self._in_use = in_use
		parent.add_child(self._axis_node)

	func use_axis(flag: bool) -> void:
		self._in_use = flag

	func set_axis_id(id: Guidot_Y_Axis.AxisID) -> void:
		# TODO (Khalid): Check if the y-axis ID is valid or not
		self._axis_id = id

	func get_axis_range() -> Vector2:
		return self._axis_node.get_axis_range()

	func is_in_use() -> bool:
		return self._in_use

	func get_axis_node() -> Guidot_Y_Axis:
		return self._axis_node

	func get_axis_id() -> Guidot_Y_Axis.AxisID:
		return self._axis_id

@onready var _y_axis1: AxisHandler = AxisHandler.new()
@onready var _y_axis2: AxisHandler = AxisHandler.new()
@onready var _y_axis3: AxisHandler = AxisHandler.new()
@onready var _y_axis_manager: Array[AxisHandler] = [
	self._y_axis1,
	self._y_axis2,
	self._y_axis3,
]

# Toggle switch
@onready var _toggle_nerd_stats: bool = false
@onready var _is_pause: bool = false

@export_group("X-Axis")
@export var t_axis_min: float = 1
@export var t_axis_max: float = 30
@export var x_number_of_ticks: int = 10

@export_group("Y-Axis")
@export var y_axis_min: float = 0
@export var y_axis_max: float = 2000
@export var y_number_of_ticks: int = 10

var _current_buffer_mode: Graph_Buffer_Mode

# Axis count is limited up to Guidot_Y_Axis._max_axis_num
@onready var _curr_y_axis_count: int = 1

@onready var fps_last_update_ms: float = Time.get_ticks_msec()

# Helper tool
var debug_panel: Guidot_Debug_Panel

signal parent_focus_requested

# Final debug trace signals are used to encapsulate all of the debug tace signals of each of our components
@onready var final_debug_trace_signals: Dictionary = {}

#### SIGNAL TRACE #####
@onready var mouse_pressed_flag: bool = false

func update_debug_info() -> void:
	self.debug_signals_to_trace = {
		"Graph: mouse in": self._mouse_in,
		"Graph: in focus": self._is_in_focus,
		"Graph: mouse filter": self.get_mouse_filter(),
	}

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

### HELPER FUNCTIONS #####
@onready var t_axis_lim_signal: int = 0 
@onready var y_axis_lim_signal: int = 0 
@onready var data_received_signal: int = 0 

func get_last_data_point() -> Vector2:
	var tmp: Vector2 = Vector2()
	if (self._get_data() == null):
		return tmp
	elif (self._get_data().size() == 0):
		return tmp
	else:
		tmp = self._get_data()[-1]
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

func _setup_plot_node() -> void:
	plot_node.init_plot(Guidot_Utils.get_color("gd_black"))
	plot_node.setup_plot_frame_offset(Vector2(self.size.x, self.size.y), \
		Vector2(t_axis_node.norm_comp_size.y, Guidot_Y_Axis.comp_size_norm_fixed), Vector2(self._y_axis_manager.size(), 0))

func _init_plot_node():
	self._setup_plot_node()
	self.add_child(plot_node)

func _setup_axis(axis_node: Guidot_Axis, axis_id: int, axis_name: String, axis_color: Color, axis_min: float, axis_max: float) -> void:
	self._init_axis(axis_node, axis_name, axis_color, axis_min, axis_max)
	axis_node.set_axis_id(axis_id)
	axis_node.setup_axis_limit(axis_min, axis_max)
	axis_node.calculate_offset_from_plot_frame(self, plot_node)

func _init_axis(axis_node: Guidot_Axis, axis_name: String, axis_color: Color, axis_min: float, axis_max: float) -> void:
	axis_node.setup_axis_node(axis_name, axis_color)
	axis_node.setup_axis_limit(axis_min, axis_max)

func _init_t_axis_node():
	self._init_axis(t_axis_node, "t_axis", Guidot_Utils.get_color("gd_black"), t_axis_min, t_axis_max)
	self.add_child(t_axis_node)

func setup_font() -> void:
	pass

func _init_font() -> void:
	setup_font()

func _register_hotkeys() -> void:
	# Input action mapping
	Guidot_Utils.add_action_with_keycode("help", KEY_H)
	Guidot_Utils.add_action_with_keycode("nerd_stats", KEY_TAB)
	Guidot_Utils.add_action_with_keycode("pause", KEY_SPACE)

func _request_buffer_mode() -> void:
	if (self._guidot_server == null):
		self.log(LOG_WARNING, ["No server has been selected. Please"])
	else:
		self._current_buffer_mode = self._guidot_server.get_graph_buffer_mode()
		self.log(LOG_INFO, ["Current buffer mode: ", self.get_buffer_mode_str(self._current_buffer_mode)])

# TODO (Khalid): Make this more fool proof, add checks, or even potentially allow the user to be able to user their own server
# Check if any server actually exist
func init_server() -> void:
	# _guidot_server = self.get_tree().get_nodes_in_group(Guidot_Common._server_group_name)[0]
	pass

func _setup_graph_client() -> void:
	self.clip_contents = true
	self.size = default_window_size
	self.color = default_window_color
	self._component_tag = "DISPLAY"

func _register_graph_client() -> void:
	self.name = Guidot_Utils.generate_unique_name(self, Guidot_Common._graph_group_name)
	self.add_to_group(self._graph_group_name)

func _get_data() -> PackedVector2Array:

	if (self._curr_data_str == null):
		return PackedVector2Array()
	else:
		return self._guidot_server.query_data_with_channel_name(self._curr_data_str)

func _get_line_color() -> Color:
	return self._guidot_server.query_data_line_color(self._curr_data_str)

func _on_setting_pressed() -> void:
	var graph_manager_pos: Vector2 = Vector2()
	graph_manager_pos.x = DisplayServer.screen_get_size().x/2 - self._graph_manager.size.x/2
	graph_manager_pos.y = DisplayServer.screen_get_size().y/2 - self._graph_manager.size.y/2
	self.log(LOG_DEBUG, ["Guidot graph manager position: ", self._graph_manager.position, graph_manager_pos])
	self._graph_manager.show_panel_at_pos(graph_manager_pos)

func _on_changes_applied(server_config_array: Array[Guidot_Server_Config]):

	if (server_config_array.is_empty()):
		self.log(LOG_WARNING, ["No server has been selected. Please use the Add Server button to subscribe to any available server."])
	else:
		
		# TODO (Khalid): At the moment, I am only using the first server that is selected
		for i in len(server_config_array):
			self._guidot_server = server_config_array[0].get_selected_server()
			self._request_buffer_mode()
			
			if (server_config_array[0].get_selected_data().is_empty()):
				self.log(LOG_WARNING, ["Please select data that you wish to subscribe to: ", server_config_array[0].get_all_data_options()])
			else:
				self._selected_channels_name = server_config_array[0].get_selected_data()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	self._setup_graph_client()
	self._register_graph_client()
	
	# Add child node for the graph
	self._init_plot_node()
	# X/Y axis rectangle anchor offset calculation depends on the plot node anchor offset maths
	# Hence, plot node needs to be ran first before we run the axis node init
	self._init_t_axis_node()
	
	self._y_axis1.init_axis(self, Guidot_Y_Axis.AxisID.PRIMARY, Vector2(0, 1), true)
	self._y_axis2.init_axis(self, Guidot_Y_Axis.AxisID.SECONDARY, Vector2(0, 1), true)
	self._y_axis3.init_axis(self, Guidot_Y_Axis.AxisID.TERTIARY, Vector2(0, 1), true)

	self._init_font()

	var setting_button: Button = Button.new()
	setting_button.size = Vector2(30, 30)
	setting_button.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT)
	setting_button.position = Vector2(self.size.x - setting_button.size.x, 0)
	setting_button.pressed.connect(self._on_setting_pressed)
	self.add_child(setting_button)

	# call_deferred is required as the parent is actually busy handling the child node (self, in particular)
	# will need to be deferred
	self.get_node("/root").add_child.call_deferred(self._graph_manager)

	plot_node.update_x_ticks_properties(t_axis_node.n_steps, t_axis_node.ticks_pos)

	##########################
	#         SIGNAL         #
	##########################

	# Axis node signal
	t_axis_node.axis_limit_changed.connect(_on_t_axis_changed)

	plot_node.focus_requested.connect(_on_focus_requested)
	
	# Self node signal
	self.resized.connect(_on_display_frame_resized)
	
	# Use the guidot common mouse entered implementation
	self.mouse_entered.connect(self._on_mouse_entered)
	self.mouse_exited.connect(self._on_mouse_exited)

	self._register_hotkeys()
	
	debug_panel = Guidot_Debug_Panel.new()
	add_child(debug_panel)

	# This needs to be overriden after the debug panel is added as a child to the graph
	self._update_final_debug_trace()
	debug_panel.override_guidot_debug_info(self.final_debug_trace_signals)

	self._graph_manager.changes_applied.connect(self._on_changes_applied)

	self.log(LOG_INFO, ["Time series graph initialized"])

	queue_redraw()

# TODO: Implement this with error detection
func set_window_color(color: Color) -> void:
	self.color = color

func _draw():
	# Data line drawing is handled inside the _draw function of plot_node
	t_axis_node.draw_axis()

func plot_data() -> void:
	
	if (self._guidot_server != null):

		var selected_gd_data: Dictionary = {}

		for channel_name in self._selected_channels_name:
			var gd_data: Guidot_Data = self._guidot_server.get_node_id_with_channel_name(channel_name)
			var channel_data_points: PackedVector2Array = self._guidot_server.query_data_with_channel_name(channel_name)
			selected_gd_data[gd_data] = channel_data_points

		self.plot_node.plot_multiple_data(selected_gd_data, Vector2(t_axis_min, t_axis_max))

func _on_display_frame_resized() -> void:

	self._setup_plot_node()
	# for axis_enum in self._y_axis_manager.keys():
	# 	var curr_y_axis: Guidot_Y_Axis = self._y_axis_manager[axis_enum]
	# 	self._setup_axis(curr_y_axis, axis_enum, "y_axis", curr_y_axis.color, curr_y_axis.min_val, curr_y_axis.max_val)
	for axis_handler in self._y_axis_manager:
		self._setup_axis(axis_handler.get_axis_node(), axis_handler.get_axis_id(), "y_axis1", Guidot_Utils.get_color("gd_black"), 0, 1) 

	self._setup_axis(t_axis_node, 0, "t_axis", t_axis_node.color, t_axis_min, t_axis_max)

	self.log(LOG_DEBUG, ["Display frame resized"])

########################################
#    SIGNAL CALLBACK IMPLEMENTATION    #
########################################
func _on_data_received() -> void:
	if (not self._is_pause):
		self.data_received_signal += 1
		t_axis_min = t_axis_node.min_val
		t_axis_max = t_axis_node.max_val
		self.plot_data()
		queue_redraw()

func _on_focus_requested() -> void:
	self._is_in_focus = !self._is_in_focus
	self.parent_focus_requested.emit()

func _on_t_axis_changed() -> void:
	self.t_axis_lim_signal += 1
	t_axis_min = t_axis_node.min_val
	t_axis_max = t_axis_node.max_val
	plot_node.update_x_ticks_properties(t_axis_node.n_steps, t_axis_node.ticks_pos)
	self.plot_data()

func _on_y_axis_changed() -> void:
	self.y_axis_lim_signal += 1
	self.plot_data()

func _input(event: InputEvent) -> void:

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
		self.log(LOG_DEBUG, ["Toggle for nerd stats:", self._toggle_nerd_stats])
		self.log(LOG_INFO, ["Displaying nerd stats"])

		if (self._toggle_nerd_stats):
			var curr_mouse_pos: Vector2 = self.get_viewport().get_mouse_position()
			debug_panel.set_position(curr_mouse_pos)
			debug_panel.show()
		else:
			debug_panel.hide()

	if (Input.is_action_just_pressed("pause")):
		self._is_pause = !self._is_pause
		self.log(LOG_DEBUG, ["Pause button pressed: ", self._is_pause])
		self.log(LOG_INFO, ["Graph paused"])

# Please note that if physics_process is used here, this will caused a lot of lag as the physics process
# will be consistent at the 60 Hz frame rate (or loop rate configured through the physics setting)
# If the physics_process is used here, the setup_axis_limit() function in the realtime mode
# gets called consistently even when the fps is dropping. This causes the process function to get
# overloaded as it could not keep up with the constant update
func _process(delta: float) -> void:
	self._move_display_process()

	var frame_update_rate_hz: float = 1.0
	var curr_ms: int = Time.get_ticks_msec()

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

			if (float(curr_ms - self.fps_last_update_ms) > 1/frame_update_rate_hz):
				# If there is no data present at the moment, then we ignore it
				if (self._guidot_server != null):
					if true:
						if (not self._is_pause):
							# The way that I wish to implement this is by having the minimum and maximum t-axis to be always an
							# even number
							# TODO (Khalid): Allow the user to use external clock source, the way that this is currently implemented
							# is that the time series graph itself generates the clock, so if the user wish to plot and visualize
							# their data in realtime, they will have to use Time.get_ticks_msec() function to have the correct
							# scale. The external clock source would allow the time axis to be a lot more flexble in a sense that it can be
							# simply an increasing integer, or absolute or relative time etc.
							var curr_s: float = self._guidot_clock_node.get_current_time_s()
							t_axis_node.setup_axis_limit(curr_s- t_axis_node._sliding_window_s, curr_s)

				self.fps_last_update_ms = curr_ms

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
