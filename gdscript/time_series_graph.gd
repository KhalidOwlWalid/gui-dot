@tool
extends ColorRect

const Guidot_Axis := preload("res://gdscript/components/guidot_axis.gd")
const Guidot_Plot := preload("res://gdscript/components/guidot_plot.gd")
const Guidot_Line := preload("res://gdscript/components/guidot_line.gd")

@onready var color_dict: Dictionary = Guidot_Utils.color_dict

# Property of the graph
var window_size: Vector2
var window_color: Color

@onready var mavlink_node = get_node('../Mavlink_Node')

@onready var default_window_size: Vector2 = Vector2(500, 300)
@onready var default_window_color: Color = Color.BLACK

# Components used for building the graph 
@onready var plot_node: Guidot_Plot = Guidot_Plot.new()
@onready var x_axis_node: Guidot_Axis = Guidot_Axis.new()
@onready var y_axis_node: Guidot_Axis = Guidot_Axis.new()

func setup_plot_node():
	plot_node._setup_plot(Vector2(self.size.x, self.size.y), 0.8, color_dict["white"])
	add_child(plot_node)

func setup_x_axis_node():
	var axis_width = (self.size.x - plot_node.size.x)/2
	var left = plot_node.offset_left - axis_width
	var right = plot_node.offset_left
	var top = plot_node.offset_top
	var bottom = plot_node.offset_bottom
	x_axis_node._setup_axis_node("X Axis", color_dict["blue"], left, right, top, bottom)
	x_axis_node.setup_axis_limit(0, 15)
	add_child(x_axis_node)

func setup_y_axis_node():
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
	setup_plot_node()
	setup_x_axis_node()
	setup_y_axis_node()
	queue_redraw()

func _draw():
	pass

# TODO: Implement this with error detection
func set_window_color(color_str: String) -> void:
	self.color = color_dict[color_str]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	set_window_color("black")
