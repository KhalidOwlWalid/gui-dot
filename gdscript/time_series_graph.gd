@tool
extends ColorRect

var Guidot_Axis := preload("res://gdscript/components/guidot_axis.gd")
var Guidot_Line := preload("res://gdscript/components/guidot_line.gd")
var Guidot_Plot := preload("res://gdscript/components/guidot_plot.gd")

@onready var color_dict: Dictionary = Guidot_Utils.color_dict

# Property of the graph
var window_size: Vector2
var window_color: Color

@onready var mavlink_node = get_node('../Mavlink_Node')

@onready var default_window_size: Vector2 = Vector2(500, 300)
@onready var default_window_color: Color = Color.BLACK

# Components used for building the graph 
@onready var plot_node: ColorRect = ColorRect.new()
@onready var x_axis_node: Guidot_Axis = Guidot_Axis.new()
@onready var y_axis_node: Guidot_Axis = Guidot_Axis.new()

# TODO (Khalid): Parametrize this
func _setup_plot_node() -> void:
	plot_node.name = "Plot"
	plot_node.clip_contents = true
	plot_node.color = color_dict["white"]
	
	# Find the necessary offset relative to the graph area
	var norm_size: float = 0.8
	var plot_size_scaled: Vector2 = norm_size * Vector2(self.size.x, self.size.y)
	var plot_x_size_scaled: int = plot_size_scaled.x/2
	var plot_y_size_scaled: int = plot_size_scaled.y/2

	# Setup anchor with respect to the window display
	plot_node.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER)
	plot_node.set_offset(SIDE_LEFT, -plot_x_size_scaled)
	plot_node.set_offset(SIDE_RIGHT, plot_x_size_scaled)
	plot_node.set_offset(SIDE_TOP, -plot_y_size_scaled)
	plot_node.set_offset(SIDE_BOTTOM, plot_y_size_scaled)

	add_child(plot_node)
	queue_redraw()

func _setup_x_axis_node():
	var axis_width = (self.size.x - plot_node.size.x)/2
	var left = plot_node.offset_left - axis_width
	var right = plot_node.offset_left
	var top = plot_node.offset_top
	var bottom = plot_node.offset_bottom
	x_axis_node._setup_axis_node("X Axis", color_dict["blue"], left, right, top, bottom)
	x_axis_node.setup_axis_limit(0, 15)
	add_child(x_axis_node)

func _setup_y_axis_node():
	var axis_height = (self.size.y - plot_node.size.y)/2
	var left = plot_node.offset_left
	var right = plot_node.offset_right
	var top = plot_node.offset_bottom
	var bottom = plot_node.offset_bottom + axis_height
	y_axis_node._setup_axis_node("Y Axis", color_dict["red"], left, right, top, bottom)
	y_axis_node.setup_axis_limit(0, 1)
	add_child(y_axis_node)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.clip_contents = true
	self.size = default_window_size
	self.color = default_window_color	
	
	# Add child node for the graph
	_setup_plot_node()
	_setup_x_axis_node()
	_setup_y_axis_node()

func _draw():
	pass

# TODO: Implement this with error detection
func set_window_color(color_str: String) -> void:
	self.color = color_dict[color_str]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	set_window_color("black")
