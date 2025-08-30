class_name Guidot_Plot
extends Guidot_Common
# extends ColorRect

@onready var default_color = Color(0.17, 0.17, 0.17, 1)
# Normalized size of the plot with respect to the node frame
@onready var default_norm_size: int = 0.8
@onready var pixel_data_pts: PackedVector2Array = PackedVector2Array()

func setup_plot_anchor() -> void:
	pass

# Setup the plot relative to the size of the graph display frame
# The plot size 
func setup_plot(frame_size: Vector2, norm_size: float, color: Color) -> void:
	self.name = "Plot"
 
	# This helps ensuring that we do not draw anything beyond the plot frame
	self.clip_contents = true
	self.color = color
	
	# Find the necessary offset relative to the graph area
	var plot_size_scaled: Vector2 = norm_size * frame_size
	var plot_x_size_scaled: int = plot_size_scaled.x/2
	var plot_y_size_scaled: int = plot_size_scaled.y/2
	self.setup_center_anchor(plot_x_size_scaled, plot_y_size_scaled)
	
func _map_data_to_pixel(data_points: PackedVector2Array) -> PackedVector2Array:
	var pixel_data_points: PackedVector2Array = PackedVector2Array()
	for i in data_points.size():
		var x_pixel_coords: int = remap(data_points[i].x, 0, 10, 0, self.get_component_size().y)
		var y_pixel_coords: int = remap(data_points[i].y, 0.8, -0.8, 0, self.get_component_size().y)
		pixel_data_points.append(Vector2(x_pixel_coords, y_pixel_coords))
	#print(pixel_data_points)
	return pixel_data_points

func plot_data(data_node: Node):
	var data_points: PackedVector2Array = PackedVector2Array()

	for i in range(0, 300):
		var x_val = i * 0.05
		var y_val = sin(x_val)
		data_points.append(Vector2(x_val, y_val))
	pixel_data_pts = self._map_data_to_pixel(data_points)
	queue_redraw()

func _ready() -> void:
	pass
	
func _draw() -> void:
	for i in range(1, pixel_data_pts.size()):
		draw_line(pixel_data_pts[i - 1], pixel_data_pts[i], Color.RED, 0.5, true)

# TODO (Khalid): Parametrize this
