@tool
extends ColorRect

# Property of the graph
var window_size: Vector2
var window_color: Color

@onready var default_window_size: Vector2 = Vector2(500, 300)
@onready var default_window_color: Color = Color.BLACK

@onready var plot_node: ColorRect = ColorRect.new()
@onready var x_axis_node: ColorRect = ColorRect.new()
@onready var y_axis_node: ColorRect = ColorRect.new()

@onready var color_dict: Dictionary = {
	"white": Color.WHITE,
	"black": Color(0.1, 0.1, 0.1, 1),
	"grey": Color(0.12, 0.12, 0.12, 1),
	"red": Color.RED,
	"blue": Color.BLUE,
	"gd_black": Color.BLACK
}

@onready var axis: Dictionary = {
	"x": 0,
	"y": 1
}

@onready var test_dict: Dictionary = {
	1: "Black"
}

@export_group("Test")
@export var test: Vector2 = Vector2(100, 100)

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

func _setup_axis_node(node: ColorRect, name: String, color: Color, left: int, right: int, top: int, bottom: int) -> void:

	node.name = name
	node.clip_contents = true
	node.color = color
	
	node.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER)
	node.set_offset(SIDE_LEFT, left)
	node.set_offset(SIDE_RIGHT, right)
	node.set_offset(SIDE_TOP, top)
	node.set_offset(SIDE_BOTTOM, bottom)

	add_child(node)

func _setup_x_axis_node():
	var axis_width = (self.size.x - plot_node.size.x)/2
	var left = plot_node.offset_left - axis_width
	var right = plot_node.offset_left
	var top = plot_node.offset_top
	var bottom = plot_node.offset_bottom
	_setup_axis_node(x_axis_node, "X Axis", color_dict["black"], left, right, top, bottom)

func _setup_y_axis_node():
	var axis_height = (self.size.y - plot_node.size.y)/2
	print(axis_height)
	var left = plot_node.offset_left
	var right = plot_node.offset_right
	var top = plot_node.offset_bottom
	var bottom = plot_node.offset_bottom + axis_height
	_setup_axis_node(y_axis_node, "Y Axis", color_dict["black"], left, right, top, bottom)

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
