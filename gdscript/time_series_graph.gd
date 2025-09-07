# @tool
extends Guidot_Common

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

# Note (Khalid): For now, I wish to standardize the font throughout the whole node
# This may bite me in the future, if for some reason, I wish to have different fonts
# for different parts of the graph, but I kinda doubt that would happen
@onready var font_node: SystemFont = SystemFont.new()

@onready var mavlink_node = get_node('../Mavlink_Node')

@onready var default_window_size: Vector2 = Vector2(1720, 980)
@onready var default_window_color: Color = color_dict["gd_black"]

# Components used for building the graph 
@onready var plot_node: Guidot_Plot = Guidot_Plot.new()
@onready var y_axis_node: Guidot_Axis = Guidot_Y_Axis.new()
@onready var t_axis_node: Guidot_Axis = Guidot_T_Axis.new()

@export_group("X-Axis")
@export var t_axis_min: float = 0
@export var t_axis_max: float = 30
@export var x_number_of_ticks: int = 10

@export_group("Y-Axis")
@export var y_axis_min: float = 0
@export var y_axis_max: float = 1
@export var y_number_of_ticks: int = 10

func setup_plot_node() -> void:
	plot_node.init_plot(color_dict["gd_black"])
	plot_node.setup_plot(Vector2(self.size.x, self.size.y), 0.9)

func init_plot_node():
	setup_plot_node()
	add_child(plot_node)

func setup_axis(axis_node: Guidot_Axis, axis_name: String, axis_color: Color, axis_min: float, axis_max: float) -> void:
	axis_node.setup_axis_limit(axis_min, axis_max)
	axis_node.calculate_offset_from_plot_frame(self, plot_node)

func init_axis(axis_node: Guidot_Axis, axis_name: String, axis_color: Color, axis_min: float, axis_max: float) -> void:
	axis_node.setup_axis_node(axis_name, axis_color)
	axis_node.setup_axis_limit(axis_min, axis_max)
	axis_node.calculate_offset_from_plot_frame(self, plot_node)

func init_t_axis_node():
	init_axis(t_axis_node, "t_axis", color_dict["gd_black"], t_axis_min, t_axis_max)
	add_child(t_axis_node)

func init_y_axis_node():
	init_axis(y_axis_node, "y_axis", color_dict["gd_black"], y_axis_min, y_axis_max)
	add_child(y_axis_node)

func setup_font() -> void:
	pass

func init_font() -> void:
	setup_font()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.clip_contents = true
	self.size = default_window_size
	self.color = default_window_color
	
	# Add child node for the graph
	init_plot_node()
	# X/Y axis rectangle anchor offset calculation depends on the plot node anchor offset maths
	# Hence, plot node needs to be ran first before we run the axis node init
	init_t_axis_node()
	init_y_axis_node()
	init_font()

	plot_node.update_x_ticks_properties(t_axis_node.n_steps, t_axis_node.ticks_pos)
	plot_node.update_y_ticks_properties(y_axis_node.n_steps, y_axis_node.ticks_pos)

	##########################
	#         SIGNAL         #
	##########################

	# Data oriented signal
	mavlink_node.data_received.connect(_on_data_received)

	# Axis node signal
	t_axis_node.axis_limit_changed.connect(_on_t_axis_changed)
	y_axis_node.axis_limit_changed.connect(_on_y_axis_changed)
	
	# Self node signal
	self.resized.connect(_on_display_frame_resized)
	
	# Use the guidot common mouse entered implementation
	self.mouse_entered.connect(self._on_mouse_entered)
	self.mouse_exited.connect(self._on_mouse_exited)

	queue_redraw()

# TODO: Implement this with error detection
func set_window_color(color: Color) -> void:
	self.color = color

func _draw():
	# Data line drawing is handled inside the _draw function of plot_node
	y_axis_node.draw_axis()
	t_axis_node.draw_axis()

func _on_display_frame_resized() -> void:
	setup_plot_node()
	setup_axis(y_axis_node, "y_axis", y_axis_node.color, y_axis_min, y_axis_max)
	setup_axis(t_axis_node, "t_axis", t_axis_node.color, t_axis_min, t_axis_max)
	print("Display frame resized")

########################################
#    SIGNAL CALLBACK IMPLEMENTATION    #
########################################
func _on_data_received() -> void:
	plot_node.plot_data(mavlink_node.data, Vector2(t_axis_min, t_axis_max), Vector2(y_axis_min, y_axis_max))
	queue_redraw()

func _on_t_axis_changed() -> void:
	plot_node.update_x_ticks_properties(t_axis_node.n_steps, t_axis_node.ticks_pos)

func _on_y_axis_changed() -> void:
	plot_node.update_y_ticks_properties(y_axis_node.n_steps, y_axis_node.ticks_pos)

func _input(event: InputEvent) -> void:
	
	# For hotkeys
	if (event is InputEventKey):
		pass

	# Simple implementation of moving the window during runtime
	if (event is InputEventMouseButton):
		
		if (event.is_pressed() and _mouse_in):
			_dragging_distance = self.position.distance_to(self.get_viewport().get_mouse_position())
			_drag_direction = (self.get_viewport().get_mouse_position() - self.position).normalized()
			_is_dragging = true
			_new_position = self.get_viewport().get_mouse_position() - self._dragging_distance * _drag_direction
			print("Mouse pressed and inside the window")

		else:
			_is_dragging = false
			print("Mouse stopped pressing")

	elif (event is InputEventMouseMotion):
		if _is_dragging:
			_new_position = self.get_viewport().get_mouse_position() - self._dragging_distance * _drag_direction

func _process(delta: float) -> void:
	if _is_dragging:
		self.position = _new_position
