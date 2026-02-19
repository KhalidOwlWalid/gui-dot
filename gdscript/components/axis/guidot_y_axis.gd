class_name Guidot_Y_Axis
extends Guidot_Axis

signal axis_removed

const comp_size_norm_fixed: float = 0.05
# This needs to be updated in parallel to the number of AxisPosition
# Left and right is counted as 1
# e.g. Primary Left and Right is considered as 1
const _max_axis_num: int = 6

# enum AxisPosition {
# 	LEFT = -1,
# 	RIGHT = 1,
# }

enum AxisPosition {
	# This allows for ease of calculations on grid spacing when drawing the y-axis
	PRIMARY_LEFT    = -1,
	SECONDARY_LEFT  = -2,
	TERTIARY_LEFT   = -3,
	QUATERNARY_LEFT = -4,
	QUINARY_LEFT    = -5,
	SENARY_LEFT     = -6,

	PRIMARY_RIGHT    = 1,
	SECONDARY_RIGHT  = 2,
	TERTIARY_RIGHT   = 3,
	QUATERNARY_RIGHT = 4,
	QUINARY_RIGHT    = 5,
	SENARY_RIGHT     = 6,

	AXIS_UNKNOWN = 0,
}

static func get_axis_id_str_from_value(axis_val: int) -> String:
	var axis_values: Array = AxisPosition.values()
	var axis_enum: Array = AxisPosition.keys()
	var n: int = axis_values.find(axis_val)
	assert(axis_values.size() == axis_enum.size(), "Axis values and Axis enums are not of the same size.")
	return axis_enum[n]	

# Axis ID, up to _max_axis_num
@onready var _axis_id: int = 0

func _ready() -> void:
	self.line_color = Guidot_Utils.get_color("white")
	self.last_line_color = self.line_color
	self.ticks_pos = PackedVector2Array()
	var tick_x_pos: int = self.top_right().x
	var axis_frame_size: Vector2 = self.get_component_size()
	var increments: int  = axis_frame_size.y / n_steps
	var tick_interval: float = (self.max_val - self.min_val) / n_steps
	for i in range(n_steps + 1):
		var tick_y_pos: int = self.top_right().y + i * increments
		self.ticks_pos.append(Vector2(tick_x_pos, tick_y_pos))

	self._setup_axis_config_menu()
	self.set_component_tag_name("Y-AXIS")
	self.norm_comp_size = Vector2(0.05, 0.05)

func set_axis_id(ax_id: int) -> void:
	self._axis_id = ax_id
	
func calculate_offset_from_plot_frame(display_frame_node: Node, plot_frame_node: Node) -> void:
	self.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT)
	self.axis_width = clamp(self.norm_comp_size.x * display_frame_node.size.x, self.min_width, self.max_width)

	# If less than zero, then the graph is placed on the left side
	if (self._axis_id < 0):
		# This needs to be an absolute value and substracted by 1 since the axis id count starts from 1
		self.offset_right = plot_frame_node.offset_left - (abs(self._axis_id) - 1) * self.axis_width
		self.offset_left = self.offset_right - self.axis_width
	# The axis is placed on the right
	elif (self._axis_id > 0):
		self.offset_left = plot_frame_node.offset_right + (abs(self._axis_id) - 1) * self.axis_width
		self.offset_right = self.offset_left + self.axis_width
	# Invalid ID has been passed (e.g. a value of 0 is invalid)
	else:
		self.log(LOG_ERROR, ["Invalid ID has been passed to ", self.name, "[", self.get_instance_id(), "] with axis ID of ", self._axis_id])
		
	self.offset_top = plot_frame_node.offset_top
	self.offset_bottom = plot_frame_node.offset_bottom

func _draw_ticks() -> void:
	
	# Clear the axis to draw new ones
	self.ticks_pos.clear()

	var tick_x_pos: int = self.top_right().x
	var axis_frame_size: Vector2 = self.get_component_size()
	var increments: int  = axis_frame_size.y / n_steps
	var tick_interval: float = (self.max_val - self.min_val) / self.n_steps

	var tick_label_offset: Vector2 = Vector2(-25, 5)
	for i in range(n_steps + 1):
		var tick_y_pos: int = self.top_right().y + i * increments
		var curr_tick_pixel_pos: Vector2 = Vector2(tick_x_pos, tick_y_pos)
		
		var tick_label: String = "{val}".format({"val":"%0.2f" % (self.max_val - i * tick_interval)})
		self._draw_single_tick_with_label(curr_tick_pixel_pos, tick_label, self.get_theme_default_font(), self.font_size, self.line_color, tick_label_offset)

func draw_y_axis() -> void:
	# Draw the vertical line of the x-axis 
	draw_line(self.top_right(), self.bottom_right(), self.line_color, 1.0, true)
	_draw_ticks()

func _draw() -> void:
	self.draw_y_axis()

func _process(delta: float) -> void:
	pass
