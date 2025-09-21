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

var _axis_config_popup: PopupMenu

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
	axis_limit_changed.emit()
	queue_redraw()

func set_min(min: float) -> void:
	self.min_val = min
	axis_limit_changed.emit()
	queue_redraw()

func set_max(max: float) -> void:
	self.max_val = max
	axis_limit_changed.emit()
	queue_redraw()

func axis_diff() -> float:
	return (self.max_val - self.min_val)

func draw_axis():
	pass

func _setup_axis_config_menu() -> void:
	# Setup the axis configuration popup menu
	_axis_config_popup = PopupMenu.new()
	add_child(_axis_config_popup)
	_axis_config_popup.name = "Axis Configuration Menu"
	_axis_config_popup.add_item("Axis Limit Settings")
	_axis_config_popup.hide_on_checkable_item_selection = false
	_axis_config_popup.hide_on_item_selection = false
	_axis_config_popup.hide_on_state_item_selection = false

# NOTE: If you use this function, please call "self.ticks_pos.clear()" to clear the old axis ticks, so we can draw new ones
func _draw_single_tick_with_label(tick_pos: Vector2, label: String, font_type: Font, font_size: float, color: Color, label_offset: Vector2) -> void:

	# Last tick position
	var tick_label_x_pos: int = tick_pos.x + label_offset.x
	var tick_label_y_pos: int = tick_pos.y + label_offset.y
	
	# This needs to be updated here to make sure that our plot is aware of the number of ticks we have
	# It will use this as reference to draw its grids!
	self.ticks_pos.append(tick_pos)
	draw_line(tick_pos, Vector2(tick_pos.x, tick_pos.y + self.tick_length), color, 1.0, true)
	self.draw_string(font_type, Vector2(tick_label_x_pos, tick_label_y_pos), label, 0, -1, font_size, color)


func _ready() -> void:
	# Override this if necessary

	# Since this is inheriting Rect2D, self.color refers to the box and not the lines of the axis!
	self.color = Guidot_Utils.color_dict["gd_black"]
	self.line_color = Guidot_Utils.color_dict["white"]
	self.last_box_color = self.color
	self.last_line_color = self.line_color
	font_size = 10
	self.set_component_tag_name("AXIS")

	self._setup_axis_config_menu()
	
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

	self._mouse_in = true
	print("Inside ", self.name, " mouse in: ", self._mouse_in)
	
	print("Mouse entered inside ", self.name)
	queue_redraw()

func _on_mouse_exited() -> void:
	self.color = self.last_box_color
	self.line_color = self.last_line_color
	print("Mouse exited inside ", self.name)

	self._mouse_in = false
	print("Inside ", self.name, " mouse in: ", self._mouse_in)

	queue_redraw()

func _input(event):

	# Only allow the axis to be scaled only when mouse hovers on the axis
	if (self._mouse_in):
		var axis_diff: float = abs(self.max_val - self.min_val)
		var zoom_factor: float = 1.1
		var curr_axis_centre: float = (self.min_val + self.max_val)/2
		var current_range: float = self.max_val - self.min_val
		var new_range: float
		var r1: float = 0.5
		var r2: float = 0.5
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				new_range = current_range / zoom_factor
				self.set_min(curr_axis_centre - new_range * r1)
				self.set_max(curr_axis_centre + new_range * r2)

			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				new_range = current_range * zoom_factor
				self.set_min(curr_axis_centre - new_range * r2)
				self.set_max(curr_axis_centre + new_range * r2)

			if event.button_index == MOUSE_BUTTON_RIGHT:
				var curr_mouse_pos: Vector2 = self.get_viewport().get_mouse_position()	
				var popup_size: Vector2 = Vector2(100, 100)
				var popup_rect: Rect2i = Rect2i(curr_mouse_pos, popup_size)
				_axis_config_popup.popup(popup_rect)
				self.log(LOG_DEBUG, ["[", self.name, "]", _axis_config_popup.name, "open at position:", curr_mouse_pos])

			if event.button_index == MOUSE_BUTTON_LEFT:
				self._emit_focus_requested_signal()
				self.log(LOG_INFO, ["Left button pressed, scale the axis here"])
