class_name Guidot_Axis
extends Guidot_Common

signal axis_limit_changed

var min_val: float
var max_val: float
@onready var n_steps: int = 5
@onready var axis_name: String = "axis_common"
@onready var tick_length: int = 5

# Keep a reference to the plot node, useful for dynamic resizing etc.
var plot_node_ref: Node

# Axis component properties
var last_box_color: Color
var last_line_color: Color
var line_color: Color
var axis_width: int
var axis_height: int

# Helpful for figuring out where to draw the value for each ticks
@onready var ticks_pos: PackedVector2Array = PackedVector2Array()
@onready var tick_values: Array = Array()
@onready var font_size: float = 10

# These values are dependent on the plot frame
# It is the offset of the axis node from the centre anchor
# TODO (Khalid): Allow more anchor options, the calculation would not be as straightforward
# but it will allow the axis to be scaled according to the user needs
var left_offset 
var right_offset
var top_offset
var bottom_offset

func init_event_handler() -> void:
	# Setup signal connection if user hovers above the axis
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)

func setup_axis_node(name: String, color: Color) -> void:
	self.name = name

	# Prevents us from drawing beyond the axis frame
	self.clip_contents = false
	self.color = color
	self.init_event_handler()

func setup_axis_limit(min: float, max: float) -> void:
	self.min_val = min
	self.max_val = max

func set_min(min: float) -> void:
	self.min_val = min
	axis_limit_changed.emit()

func set_max(max: float) -> void:
	self.max_val = max
	axis_limit_changed.emit()

func draw_axis():
	pass

func _ready() -> void:
	# Override this if necessary

	# Since this is inheriting Rect2D, self.color refers to the box and not the lines of the axis!
	self.color = Guidot_Utils.color_dict["gd_black"]
	self.line_color = Guidot_Utils.color_dict["white"]
	self.last_box_color = self.color
	self.last_line_color = self.line_color
	font_size = 10
	
func _draw() -> void:
	pass

# Mouse entered and exit will allow user to hover above the 
func _on_mouse_entered() -> void:
	# Save the current color so we can revert back when user goes out of the axis box
	self.last_box_color = self.color
	self.last_line_color = self.line_color

	# Change the color of the box so user knows they are hovering above it
	self.color = Guidot_Utils.color_dict["gd_dim_blue"]
	self.line_color = Guidot_Utils.color_dict["gd_bright_yellow"]
	
	print("Mouse entered inside ", self.name)
	queue_redraw()

func _on_mouse_exited() -> void:
	self.color = self.last_box_color
	self.line_color = self.last_line_color
	print("Mouse exited inside ", self.name)
	queue_redraw()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		print("Mouse left was pressed")
