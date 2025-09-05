class_name Guidot_Plot
extends Guidot_Common

@onready var default_color = Color(0.17, 0.17, 0.17, 1)
# Normalized size of the plot with respect to the node frame
@onready var default_norm_size: int = 0.8
@onready var pixel_data_points: PackedVector2Array = PackedVector2Array()

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
@onready var n_sampling: int = 20
@onready var data_fetching_mode: DataFetchMode = DataFetchMode.BOTH_INSIDE

# Axis properties
var n_x_ticks: int
var x_ticks_pos: PackedVector2Array
var n_y_ticks: int
var y_ticks_pos: PackedVector2Array

func setup_plot_anchor() -> void:
	pass

func init_plot(color: Color = Guidot_Utils.color_dict["gd_black"]) -> void:
	self.name = "plot_frame"
 
	# This helps ensuring that we do not draw anything beyond the plot frame
	self.clip_contents = true
	self.color = color

# Setup the plot relative to the size of the graph display frame
# The plot size 
func setup_plot(frame_size: Vector2, norm_size: float) -> void:
	# Find the necessary offset relative to the graph area
	var plot_size_scaled: Vector2 = norm_size * frame_size
	var plot_x_size_scaled: int = plot_size_scaled.x/2
	var plot_y_size_scaled: int = plot_size_scaled.y/2
	self.setup_center_anchor(plot_x_size_scaled, plot_y_size_scaled)
	
func _map_data_to_pixel(data_points: PackedVector2Array, t_axis_range: Vector2, y_axis_range: Vector2) -> void:
	pixel_data_points = PackedVector2Array()
	var t_axis_min: float = t_axis_range.x
	var t_axis_max: float = t_axis_range.y
	var y_axis_min: float = y_axis_range.x
	var y_axis_max: float = y_axis_range.y
	for i in data_points.size():
		var x_pixel_coords: int = remap(data_points[i].x, t_axis_min, t_axis_max, 0, self.get_component_size().x)
		# Remember that we are drawing from the top left, so in this case y_axis_min is the bottom left, and vice versa!
		var y_pixel_coords: int = remap(data_points[i].y, y_axis_min, y_axis_max, self.get_component_size().y, 0)
		pixel_data_points.append(Vector2(x_pixel_coords, y_pixel_coords))

# Note (Khalid): For now, this data handles relative timestamps. Will need to implement absolute timestamps or time since epoch later on.
# This function obtains the index of t_start and t_end
func _find_data_between(ts_data: PackedVector2Array, t_start: float, t_end: float) -> Vector2:
	return Vector2()

func _handle_data_fetching(ts_data: PackedVector2Array) -> void:
	pass

func _data_processing(ts_data: PackedVector2Array, t_range: Vector2) -> PackedVector2Array:

	# This calculation should be done at least once when new time series data comes in
	# The time series graph makes an assumption that the data have a constant frequency rate to avoid
	# performing expensive calculations every single time
	# As for current implementation, this assumption would fail if the server does not provide a constant update
	# rate, potentially due to latency of the communication (e.g. via telemetry) whereby at certain point of time,
	# you may get a burst of data at once, if the timestamp is handled by the server, will throw off the
	# below calculations
	if (approx_sample_t == null or approx_sample_t == 0):
		for i in range(n_sampling - 1):
			approx_sample_t += (ts_data[i + 1].x - ts_data[i].x)
		approx_sample_t = approx_sample_t / n_sampling

	var t_min: float = t_range.x
	var t_max: float = t_range.y
	var t_diff: float = t_max - t_min
	var t_start: float = ts_data[0].x
	var t_end: float = ts_data[-1].x

	var n_slice_length: int = int(t_diff / approx_sample_t)

	# # TODO (Khalid): Figure out a clean way to do this
	if (t_start >= t_min and t_end <= t_max):
		self.data_fetching_mode = DataFetchMode.BOTH_INSIDE
	elif (t_start >= t_min and t_end >= t_max):
		self.data_fetching_mode = DataFetchMode.HEAD_IN_TAIL_OUT
	elif (t_start <= t_min and t_end <= t_max):
		self.data_fetching_mode = DataFetchMode.HEAD_OUT_TAIL_IN
	elif (t_start <= t_min and t_end >= t_max):
		self.data_fetching_mode = DataFetchMode.OVERFLOW_BOTH_ENDS
	else:
		# In the case that there are conditions I did not capture
		self.data_fetching_mode = DataFetchMode.NOT_IMPLEMENTED

	"""
	Based on approximated time stamp, and the size of the array, we can get a rough idea which part of the data to slice
	This allows us to render only what is necessary (Level of Detail - LOD)
	For example, if the array contains data from (0 to 30s), and we only need to plot data between 20s to 30s, then:
		# approx_sample_time = 0.1
		# time_diff = 10s 
		# n_lod_size = 10 / 0.1 = 100

	If first element is 0s, then we can safely assume that starting at (n, t) where (200, 20s) and (300, 30s)
	To avoid miscalculation, we can simply grab slightly more data (e.g. n=150 to n=350)
	When rendered, data that is not within the time frame will be clipped, so we do not have to worry about discontinuity in our plot
	if there is any miscalculations!
	"""	
	match self.data_fetching_mode:

		DataFetchMode.BOTH_INSIDE:
			# Just draw the current dataset
			print("Both inside")
			pass

		DataFetchMode.HEAD_IN_TAIL_OUT:
			var k: int = int((t_max - t_start)/approx_sample_t)
			ts_data = ts_data.slice(0, k + n_slice_length)
			print("Head in, Tail out")
		
		DataFetchMode.HEAD_OUT_TAIL_IN:
			# How much is the difference between t_start and t_min, just slice the starting point of t_min
			var k: int = int((t_min - t_start)/approx_sample_t)
			# k/2 is to grabbed a few elements so that we do not have any discontinuity
			# We do not return data that is out of screen, only render what is necessary to avoid drawing clipped data
			ts_data = ts_data.slice(k - int(k/2), k + n_slice_length)
			print("Head out, Tail in")

		DataFetchMode.OVERFLOW_BOTH_ENDS:
			ts_data = PackedVector2Array()
			print("Overflow")

		DataFetchMode.NOT_IMPLEMENTED:
			print("Not implemented")
	
	return ts_data

# TODO (Khalid): Currently, this creates a copy of the data, which is not great. This uses a lot of memory so Will need to optimize this implementation
func plot_data(data_points: PackedVector2Array, t_axis_range: Vector2, y_axis_range: Vector2):

	var data: PackedVector2Array = data_points

	# Pre-process the data that should be visible on the graph
	if !(data_points.size() < n_sampling):
		# We need at least 5 sets of data to be able to perform calculations for approximating the index of data we wish to plot
		data = _data_processing(data, t_axis_range)

	self._map_data_to_pixel(data, t_axis_range, y_axis_range)
	queue_redraw()

func test_func(data_node: Node):
	print(data_node.data)

func update_x_ticks_properties(n_ticks: int, ticks_pos: PackedVector2Array) -> void:
	x_ticks_pos = ticks_pos
	n_x_ticks = n_ticks

func update_y_ticks_properties(n_ticks: int, ticks_pos: PackedVector2Array) -> void:
	y_ticks_pos = ticks_pos
	n_y_ticks = n_ticks

func _ready() -> void:
	pass

func _draw_vertical_grids(n_ticks: int, ticks_pos: PackedVector2Array, color: Color) -> void:
	for i in range(n_ticks + 1):
		draw_line(Vector2(ticks_pos[i].x, self.bottom_right().y), Vector2(ticks_pos[i].x, self.top_right().y), color, -1, true)

func _draw_horizontal_grids(n_ticks: int, ticks_pos: PackedVector2Array, color: Color) -> void:
	for i in range(n_ticks):
		draw_line(Vector2(self.top_left().x, ticks_pos[i].y), Vector2(self.top_right().x, ticks_pos[i].y), color, -1, true)
	
# Handle data line drawing here
func _draw() -> void:
	_draw_vertical_grids(n_x_ticks, x_ticks_pos, Guidot_Utils.color_dict["gd_grey"])
	_draw_horizontal_grids(n_y_ticks, y_ticks_pos, Guidot_Utils.color_dict["gd_grey"])
	for i in range(1, pixel_data_points.size()):
		draw_line(pixel_data_points[i - 1], pixel_data_points[i], Color.RED, 0.5, true)
		# TODO (Khalid): Circle should only be drawn when it is at a certain window size
		# I am not sure why but drawing a circle is very taxing, maybe due to how it is implemeted
		draw_circle(pixel_data_points[i], 1, Color.RED)
