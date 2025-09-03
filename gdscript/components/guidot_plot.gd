class_name Guidot_Plot
extends Guidot_Common

@onready var default_color = Color(0.17, 0.17, 0.17, 1)
# Normalized size of the plot with respect to the node frame
@onready var default_norm_size: int = 0.8
@onready var pixel_data_points: PackedVector2Array = PackedVector2Array()

# Axis properties
var n_x_ticks: int
var x_ticks_pos: PackedVector2Array
var n_y_ticks: int
var y_ticks_pos: PackedVector2Array

func setup_plot_anchor() -> void:
	pass

func init_plot(color: Color) -> void:
	self.name = "plot_frame"
 
	# This helps ensuring that we do not draw anything beyond the plot frame
	self.clip_contents = true
	self.color = color

# Setup the plot relative to the size of the graph display frame
# The plot size 
func setup_plot(frame_size: Vector2, norm_size: float, color: Color) -> void:
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

# TODO (Khalid): Currently, this creates a copy of the data, which is not great. Will need to optimize this implementation
func plot_data(data_points: PackedVector2Array, t_axis_range: Vector2, y_axis_range: Vector2):
	self._map_data_to_pixel(data_points, t_axis_range, y_axis_range)
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
	_draw_vertical_grids(n_x_ticks, x_ticks_pos, Guidot_Utils.color_dict["grey"])
	_draw_horizontal_grids(n_y_ticks, y_ticks_pos, Guidot_Utils.color_dict["grey"])
	for i in range(1, pixel_data_points.size()):
		draw_line(pixel_data_points[i - 1], pixel_data_points[i], Color.RED, 0.5, true)
