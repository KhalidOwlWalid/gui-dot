class_name Guidot_Plot
extends Guidot_Common
# extends ColorRect

@onready var default_color = Color(0.17, 0.17, 0.17, 1)
# Normalized size of the plot with respect to the node frame
@onready var default_norm_size: int = 0.8

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

func _ready() -> void:
	pass

# TODO (Khalid): Parametrize this
