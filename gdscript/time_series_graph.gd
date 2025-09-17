# @tool
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

@onready var mavlink_node = get_node('../../Mavlink_Node')
@onready var guidot_master_node = get_node('../../Guidot_Master_Node')

@onready var default_window_size: Vector2 = Vector2(1720, 980)
@onready var default_window_color: Color = color_dict["gd_black"]

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

var test_panel: Guidot_Panel

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
	plot_node.setup_plot(Vector2(self.size.x, self.size.y), 0.9)

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
	
	# Self node signal
	self.resized.connect(_on_display_frame_resized)
	
	# Use the guidot common mouse entered implementation
	self.mouse_entered.connect(self._on_mouse_entered)
	self.mouse_exited.connect(self._on_mouse_exited)

	self._register_hotkeys()
	self._request_buffer_mode()
	
	test_panel = Guidot_Panel.new()
	add_child(test_panel)

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
	print("Display frame resized")

########################################
#    SIGNAL CALLBACK IMPLEMENTATION    #
########################################
func _on_data_received() -> void:
	if (not self._is_pause):
		t_axis_min = t_axis_node.min_val
		t_axis_max = t_axis_node.max_val
		self.log(LOG_DEBUG, ["Inside on data received: ", Vector2(t_axis_min, t_axis_max)])
		plot_node.plot_data(mavlink_node.data, Vector2(t_axis_min, t_axis_max), Vector2(y_axis_min, y_axis_max))
		queue_redraw()

func _on_graph_buffer_mode_changed() -> void:
	pass

func _on_t_axis_changed() -> void:
	t_axis_min = t_axis_node.min_val
	t_axis_max = t_axis_node.max_val
	plot_node.update_x_ticks_properties(t_axis_node.n_steps, t_axis_node.ticks_pos)
	self.log(LOG_DEBUG, ["Inside on t axis changed: ", Vector2(t_axis_min, t_axis_max)])
	plot_node.plot_data(mavlink_node.data, Vector2(t_axis_min, t_axis_max), Vector2(y_axis_min, y_axis_max))

func _on_y_axis_changed() -> void:
	y_axis_min = y_axis_node.min_val
	y_axis_max = y_axis_node.max_val
	plot_node.update_y_ticks_properties(y_axis_node.n_steps, y_axis_node.ticks_pos)
	self.log(LOG_DEBUG, ["Inside on y axis changed: ", Vector2(y_axis_min, y_axis_max)])
	plot_node.plot_data(mavlink_node.data, Vector2(t_axis_min, t_axis_max), Vector2(y_axis_min, y_axis_max))

func _nerd_stats_panel_update():
	if (self._toggle_nerd_stats):
		pass

func _input(event: InputEvent) -> void:

	# For hotkeys
	if (Input.is_action_just_pressed("nerd_stats")):
		self._toggle_nerd_stats = !self._toggle_nerd_stats
		self.log(LOG_DEBUG, ["Toggle for nerd stats: ", self._toggle_nerd_stats])
		test_panel.show_panel(Vector2(100, 100))

	if (Input.is_action_just_pressed("pause")):
		self._is_pause = !self._is_pause
		self.log(LOG_DEBUG, ["Last data value: ", mavlink_node.data[-1].x, ", ", mavlink_node.data[-1].y])
		self.log(LOG_DEBUG, ["Pause button pressed: ", self._is_pause])

	# TODO (Khalid): Move this flag globally, and only allow the window to be moved in design mode
	var moving_mode_flag: bool = true
	self._move_display(event, moving_mode_flag)


func _process(delta: float) -> void:
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
				if (moving_max_tick):
					# The way that I wish to implement this is by having the minimum and maximum t-axis to be always an
					# even number
					t_axis_node.set_max(mavlink_node.data[-1].x)
					t_axis_node.set_min(mavlink_node.data[-1].x - t_axis_node._sliding_window_s)

					# From here onwards, we have to do a lot of checks
