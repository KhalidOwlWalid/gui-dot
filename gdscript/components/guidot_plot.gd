class_name Guidot_Plot
extends Guidot_Common

@onready var default_color = Color(0.17, 0.17, 0.17, 1)
# Normalized size of the plot with respect to the node frame
@onready var default_norm_size: int = 0.8
@onready var pixel_data_points: PackedVector2Array = PackedVector2Array()
@onready var _line_color: Color = Color.RED

@onready var _data_channel_pixel_pos: Dictionary = {}

# Data specific properties
# Visualize the data as if it is a snake
enum DataFetchMode {
	BOTH_INSIDE,   		# Starting data and end of data is within the boundary of the plot
	BOTH_OUTSIDE,   	# Both starting and end of data is outside the boundary of the plot (can be either left or right)
	HEAD_OUT_TAIL_IN, 	# Starting data is outside the boundary, but the end of data is still within the boundary of the time frame
	HEAD_IN_TAIL_OUT,	# Starting data is inside the boundary, but the end of data is outside the boundary (will need to truncate any excess data)
	OVERFLOW_BOTH_ENDS, # Starting and end of data is outside the boundary, hence there are data within the boundaries, truncation needed
	NOT_IMPLEMENTED,
}

var approx_sample_t: float
@onready var n_sampling: int = 100
@onready var data_fetching_mode: DataFetchMode = DataFetchMode.BOTH_INSIDE

@onready var data_fetching_mode_str: Dictionary = {
	DataFetchMode.BOTH_INSIDE: "Both Inside",
	DataFetchMode.BOTH_OUTSIDE: "Both Outside",
	DataFetchMode.HEAD_OUT_TAIL_IN: "Head Out, Tail In",
	DataFetchMode.HEAD_IN_TAIL_OUT: "Head In, Tail Out",
	DataFetchMode.OVERFLOW_BOTH_ENDS: "Overflow Both Ends",
	DataFetchMode.NOT_IMPLEMENTED: "Not Implemented",
}

##### HELPER FUNCTION FOR DEBUG SIGNALS ######
@onready var ds_k = 0
@onready var ds_cmp_t_diff = 0
@onready var ds_approx_sample_t = 0
@onready var ds_cmp_t = 0
@onready var ds_offset = 0

# Used for debugging signals
@onready var n_preprocessed_data: int = 0
@onready var n_postprocessed_data: int = 0
@onready var head_vec2: Vector2 = Vector2()
@onready var tail_vec2: Vector2 = Vector2()
@onready var t_draw: float = float()

func update_debug_info() -> void:
	self.debug_signals_to_trace = {
		"t_draw": str(self.t_draw, 3)
		# "ds_offset": str(ds_offset),
		# "plot: mouse_in": self._mouse_in,
		# "Plot: in focus": self._is_in_focus,
		# "Pre-processed data size": self.n_preprocessed_data,
		# "Post-processed data size": self.n_postprocessed_data,
		# "Approximated sample time": self.approx_sample_t,
	}

##############################################

# Axis properties
var n_x_ticks: int
var x_ticks_pos: PackedVector2Array
var n_y_ticks: int
var y_ticks_pos: PackedVector2Array

var test_popup: PopupMenu

func _ready() -> void:
	test_popup = PopupMenu.new()
	add_child(test_popup)
	test_popup.add_check_item("test")
	test_popup.add_radio_check_item("test radio check")
	test_popup.hide_on_checkable_item_selection = false
	test_popup.hide_on_item_selection = false
	test_popup.hide_on_state_item_selection = false

	self.norm_comp_size = Vector2(0.95, 0.95)

	self.set_component_tag_name("PLOT")

	# Use the guidot common mouse entered implementation
	self.mouse_entered.connect(self._on_mouse_entered)
	self.mouse_exited.connect(self._on_mouse_exited)

func setup_plot_anchor() -> void:
	pass

func init_plot(color: Color = Guidot_Utils.get_color("gd_black")) -> void:
	self.name = "plot_frame"
 
	# This helps ensuring that we do not draw anything beyond the plot frame
	self.clip_contents = true
	self.color = color

# Setup the plot relative to the size of the graph display frame and the existing axis
# @param	frame_size 			(Vector2):	Frame size of the graph display
# @param	axis_comp_norm_size (Vector2):	Axis component normalized size (the summation in the x and y should be 1.0)
# @param	n_y_axis 			(Vector2):	Number of y-axis in the left(x) and right(y). Again, the summation of all
#											axis components including offset should be 1.0.
#											Example: Vector2(2, 2) means that there are 2 y-axis on the left and right side
func setup_plot_frame_offset(frame_size: Vector2, axis_norm_comp_size: Vector2, n_y_axis: Vector2 = Vector2(1, 0)) -> void:

	# n_y_axis = Vector2(1, 0)
	var n_left_comp: float = n_y_axis.x
	var n_right_comp: float = n_y_axis.y
	# Temporary to handle margin
	var header_margin: float = 0.075

	# Find the necessary offset relative to the graph area
	var plot_size_scaled: Vector2 = self.norm_comp_size * frame_size
	# self.setup_center_anchor(plot_x_size_scaled, plot_y_size_scaled)
	self.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT)
	var y_axis_width: float = clamp(axis_norm_comp_size.y * frame_size.x, 0, 50)
	var left_offset: float = n_left_comp * y_axis_width
	var top_offset: int = int(header_margin * frame_size.y)
	self.set_offset(SIDE_LEFT, left_offset)
	self.set_offset(SIDE_RIGHT, plot_size_scaled.x - n_right_comp * y_axis_width)
	self.set_offset(SIDE_TOP, top_offset)
	self.set_offset(SIDE_BOTTOM, frame_size.y - axis_norm_comp_size.x * frame_size.y)
	
func _map_data_to_pixel(data_points: PackedVector2Array, t_axis_range: Vector2, y_axis_range: Vector2) -> void:
	pixel_data_points = PackedVector2Array()
	var t_axis_min: float = t_axis_range.x
	var t_axis_max: float = t_axis_range.y
	var y_axis_min: float = y_axis_range.x
	var y_axis_max: float = y_axis_range.y
	var comp_size: Vector2 = self.get_component_size()
	for i in data_points.size():
		var x_pixel_coords: int = remap(data_points[i].x, t_axis_min, t_axis_max, 0, comp_size.x)
		# Remember that we are drawing from the top left, so in this case y_axis_min is the bottom left, and vice versa!
		var y_pixel_coords: int = remap(data_points[i].y, y_axis_min, y_axis_max, comp_size.y, 0)
		pixel_data_points.append(Vector2(x_pixel_coords, y_pixel_coords))

func pixel_remap(data_pts: Vector2, t_axis_lim: Vector2, y_axis_lim: Vector2, comp_size: Vector2) -> Vector2:
	data_pts.x = remap(data_pts.x, t_axis_lim.x, t_axis_lim.y, 0, comp_size.x)	 
	data_pts.y = remap(data_pts.y, y_axis_lim.x, y_axis_lim.y, comp_size.y, 0)	 
	return data_pts

func _map_data_points_to_pixel_pos(data_points: PackedVector2Array, t_axis_range: Vector2, y_axis_range: Vector2) -> PackedVector2Array:
	var t_axis_min: float = t_axis_range.x
	var t_axis_max: float = t_axis_range.y
	var y_axis_min: float = y_axis_range.x
	var y_axis_max: float = y_axis_range.y

	var mx: float = (self.get_component_size().x - 0)/(t_axis_max - t_axis_min)
	var my: float = (self.get_component_size().y - 0)/(y_axis_min - y_axis_max)
	var comp_size: Vector2 = self.get_component_size()
	
	# First method of performing pixel remapping
	# TODO (Khalid): Leaving this implementation here for now, as I am not sure if the first or second method is better
	# var pix_data_pos: Array = Array(data_points).map(pixel_remap.bind(t_axis_range, y_axis_range, self.get_component_size()))
	# pix_data_pos = PackedVector2Array(pix_data_pos)

	# Using binary search to find the nth element where t_min and t_max starts, so we don't have to remap and draw
	# every single data points
	var processed_data_points: PackedVector2Array
	var t_min_pos: int = data_points.bsearch(Vector2(t_axis_range.x, 0))
	var t_max_pos: int = data_points.bsearch(Vector2(t_axis_range.y, 0))
	processed_data_points = data_points.slice(t_min_pos, t_max_pos)

	# Second method of performing pixel remapping
	var pix_data_pos = PackedVector2Array()
	for i in processed_data_points.size():
		var x_pixel_coords: int = remap(processed_data_points[i].x, t_axis_min, t_axis_max, 0, comp_size.x)
		# Remember that we are drawing from the top left, so in this case y_axis_min is the bottom left, and vice versa!
		var y_pixel_coords: int = remap(processed_data_points[i].y, y_axis_min, y_axis_max, comp_size.y, 0)
		pix_data_pos.append(Vector2(x_pixel_coords, y_pixel_coords))
	return pix_data_pos

# datasets = {Guidot_Data Object: <data_points>}
func plot_multiple_data(datasets: Dictionary, y_axis_manager: RefCounted, time_range: Vector2):

	# Clears the dictionary before adding new entries for each data channel
	self._data_channel_pixel_pos.clear()
	
	for gd_data in datasets.keys():
		var axis_handler: RefCounted = y_axis_manager.get_axis_handler(-1)
		var y_axis_limit: Vector2 = axis_handler.get_axis_range()
		var data_channel_pixel_pos: PackedVector2Array = self._map_data_points_to_pixel_pos(datasets[gd_data], time_range, y_axis_limit)
		self._data_channel_pixel_pos[gd_data] = data_channel_pixel_pos

	# for axis_enum in y_axis_manager.get_axis_manager_dict().keys():
	# 	# Get the 
	# 	var axis_handler = y_axis_manager.get_axis_handler(-1)
	# 	# var axis_node: RefCounted = y_axis_manager.get_axis_manager_dict()[axis_enum]
	# 	var y_axis_limit: Vector2 = axis_handler.get_axis_range()
	# 	var data_channel_pixel_pos: PackedVector2Array = self._map_data_points_to_pixel_pos(datasets[gd_data], time_range, y_axis_limit)
	# 	self._data_channel_pixel_pos[gd_data] = data_channel_pixel_pos

	queue_redraw()

func test_func(data_node: Node):
	print(data_node.data)

func update_x_ticks_properties(n_ticks: int, ticks_pos: PackedVector2Array) -> void:
	x_ticks_pos = ticks_pos
	n_x_ticks = n_ticks

func update_y_ticks_properties(n_ticks: int, ticks_pos: PackedVector2Array) -> void:
	y_ticks_pos = ticks_pos
	n_y_ticks = n_ticks

func _draw_vertical_grids(n_ticks: int, ticks_pos: PackedVector2Array, grid_color: Color) -> void:
	for i in range(ticks_pos.size()):
		draw_line(Vector2(ticks_pos[i].x, self.bottom_right().y), Vector2(ticks_pos[i].x, self.top_right().y), grid_color, -1, true)

func _draw_horizontal_grids(n_ticks: int, ticks_pos: PackedVector2Array, grid_color: Color) -> void:
	for i in range(ticks_pos.size()):
		draw_line(Vector2(self.top_left().x, ticks_pos[i].y), Vector2(self.top_right().x, ticks_pos[i].y), grid_color, -1, true)

func _draw_plots() -> void:
	for gd_data in self._data_channel_pixel_pos.keys():
		var data_points: PackedVector2Array = self._data_channel_pixel_pos[gd_data]
		# TODO (Khalid): Please do a write up of why draw_polyline is optimized better
		# Using anti-aliasing is more computationally expensive
		# However, the user should be able to have that option enabled if they simply want to
		# have their graph looks more sharp. With anti-aliasing disabled, it should still be alright
		# for realtime plots
		var use_anti_aliasing: bool = false
		# Draw circles on the graph if the number of sampling points are less than 25
		if (data_points.size() > 25):
			draw_polyline(data_points, gd_data.get_line_color(), 1.0, use_anti_aliasing)
		else:	
			for i in range(1, data_points.size()):
				draw_line(data_points[i - 1], data_points[i], gd_data.get_line_color(), 0.5, true)
				draw_circle(data_points[i], 2.0, gd_data.get_line_color(), -1, true)
	
# Handle data line drawing here
func _draw() -> void:
	_draw_vertical_grids(n_x_ticks, x_ticks_pos, Guidot_Utils.get_color("gd_grey"))
	_draw_horizontal_grids(n_y_ticks, y_ticks_pos, Guidot_Utils.get_color("gd_grey"))
	t_draw = Guidot_Utils.profiler(self._draw_plots) * 1e3

func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton and event.pressed:

		if event.button_index == MOUSE_BUTTON_RIGHT:
			self.log(LOG_INFO, ["Right button pressed"])
		
		if (self._mouse_in):
			if event.button_index == MOUSE_BUTTON_LEFT:
				
				if (not self._is_in_focus):
					self._emit_focus_requested_signal()
					self.log(LOG_INFO, ["Emit focus requested signal"])
