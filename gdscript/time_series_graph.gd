@tool
extends ColorRect

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

@onready var mavlink_node = get_node('../Mavlink_Node')

@onready var default_window_size: Vector2 = Vector2(600, 450)
@onready var default_window_color: Color = Color.BLACK

# Components used for building the graph 
@onready var plot_node: Guidot_Plot = Guidot_Plot.new()
@onready var y_axis_node: Guidot_Axis = Guidot_Y_Axis.new()
@onready var t_axis_node: Guidot_Axis = Guidot_T_Axis.new()

func setup_plot_node() -> void:
	plot_node.setup_plot(Vector2(self.size.x, self.size.y), 0.9, color_dict["black"])

func init_plot_node():
	setup_plot_node()
	add_child(plot_node)

# X/Y axis rectangle anchor offset calculation depends on the plot node anchor offset maths
# Hence, plot node needs to be ran first before we run the axis node init
func setup_y_axis_node() -> void:
	y_axis_node.setup_axis_node("y_axis", color_dict["black"])
	y_axis_node.setup_axis_limit(0, 15)
	y_axis_node.calculate_offset_from_plot_frame(self, plot_node)

func init_y_axis_node():
	setup_y_axis_node()
	add_child(y_axis_node)

func setup_t_axis_node() -> void:
	t_axis_node.setup_axis_node("y_axis", color_dict["black"])
	t_axis_node.setup_axis_limit(0, 1)
	t_axis_node.calculate_offset_from_plot_frame(self, plot_node)

func init_t_axis_node():
	setup_t_axis_node()
	add_child(t_axis_node)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.clip_contents = true
	self.size = default_window_size
	self.color = default_window_color

	self.resized.connect(_on_display_frame_resized)
	
	# Add child node for the graph
	init_plot_node()
	init_y_axis_node()
	init_t_axis_node()

	queue_redraw()

# TODO: Implement this with error detection
func set_window_color(color_str: String) -> void:
	self.color = color_dict[color_str]

func _draw():
	y_axis_node.draw_axis()
	t_axis_node.draw_axis()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	set_window_color("black")
	# plot_node.plot_data(mavlink_node.data)

func _on_mouse_entered() -> void:
	print("Mouse entered")

func _on_display_frame_resized() -> void:
	setup_plot_node()
	setup_y_axis_node()
	setup_t_axis_node()
	print("Display frame resized")
