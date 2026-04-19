class_name Guidot_Y_Axis
extends Guidot_Axis

signal axis_removed

const comp_size_norm_fixed: float = 0.05
# This needs to be updated in parallel to the number of AxisPosition
# Left and right is counted as 1
# e.g. Primary Left and Right is considered as 1
const _max_axis_num: int = 6

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

# Cached frame node references so we can reposition when axis width changes
var _display_frame_node: Node = null
var _plot_frame_node: Node = null

var _drag_tick_increment_cached: float = 0.0

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
	self._setup_inline_edit()
	self.set_component_tag_name("Y-AXIS")
	self.norm_comp_size = Vector2(0.05, 0.05)

func set_axis_id(ax_id: int) -> void:
	self._axis_id = ax_id

# Returns the power-of-10 exponent to use as a common scale factor for the
# current min/max range.  Returns 0 when no scaling is needed.
#
#   >= 1000  or  < 0.001  ->  scale so mantissa values sit in [1, 1000)
#   everything else       -> no scaling (return 0)
func _get_scale_exponent() -> int:
	var scale: float = max(abs(self.min_val), abs(self.max_val))
	if scale == 0.0:
		return 0
	# log(1000.0)/log(10.0) can return 2.9999... due to floating point imprecision,
	# causing floor() to round down to 2 instead of 3 (off by a factor of 10).
	# Adding a small epsilon before flooring corrects this without affecting
	# genuinely non-integer exponents (e.g. log10(500) ≈ 2.699 stays 2).
	var exp: int = int(floor(log(scale) / log(10.0) + 1e-9))
	if exp >= 3 or exp <= -3:
		return exp
	return 0

# Format a single tick value given a pre-computed scale exponent.
# The value is divided by 10^exponent before formatting so the result is
# always a short, human-readable mantissa string.
func _format_tick_label(value: float, exponent: int) -> String:
	var divisor: float = pow(10.0, exponent)
	var scaled: float = value / divisor if divisor != 0.0 else value

	# Decide decimal places: use 3dp for small differences, 2dp otherwise
	var tick_interval: float = abs(self.max_val - self.min_val) / self.n_steps
	var scaled_interval: float = tick_interval / divisor if divisor != 0.0 else tick_interval
	var decimals: int = 3 if scaled_interval < 0.1 else 2

	if scaled == floorf(scaled):
		return "%d" % int(scaled)

	var fmt: String = "%." + str(decimals) + "f"
	var s: String = fmt % scaled
	s = s.rstrip("0").rstrip(".")
	return s

# Returns the pixel width of the widest tick label under the current range.
# Used to size the axis frame so labels never overflow.
func _get_max_label_width() -> float:
	if not is_inside_tree():
		return 40.0  # safe fallback before the node is in the tree
	var font: Font = get_theme_default_font()
	var tick_interval: float = (self.max_val - self.min_val) / self.n_steps
	var exponent: int = _get_scale_exponent()
	var max_w: float = 0.0
	for i in range(n_steps + 1):
		var label: String = _format_tick_label(self.max_val - i * tick_interval, exponent)
		var w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if w > max_w:
			max_w = w
	return max_w

func calculate_offset_from_plot_frame(display_frame_node: Node, plot_frame_node: Node) -> void:
	_display_frame_node = display_frame_node
	_plot_frame_node = plot_frame_node

	self.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT)

	# Axis must be at least wide enough to contain the widest tick label plus
	# a small margin for the tick mark itself.
	var label_padding: int = 8
	var required_width: int = int(_get_max_label_width()) + label_padding
	var base_width: int = int(self.norm_comp_size.x * display_frame_node.size.x)
	self.axis_width = max(clamp(base_width, self.min_width, self.max_width), required_width)

	# If less than zero, then the graph is placed on the left side
	if (self._axis_id < 0):
		self.offset_right = plot_frame_node.offset_left - (abs(self._axis_id) - 1) * self.axis_width
		self.offset_left = self.offset_right - self.axis_width
	# The axis is placed on the right
	elif (self._axis_id > 0):
		self.offset_left = plot_frame_node.offset_right + (abs(self._axis_id) - 1) * self.axis_width
		self.offset_right = self.offset_left + self.axis_width
	else:
		self.log(LOG_ERROR, ["Invalid ID has been passed to ", self.name, "[", self.get_instance_id(), "] with axis ID of ", self._axis_id])

	self.offset_top = plot_frame_node.offset_top
	self.offset_bottom = plot_frame_node.offset_bottom

# Override so that changing limits also resizes and repositions the axis.
func setup_axis_range(min: float, max: float) -> void:
	super.setup_axis_range(min, max)
	if _display_frame_node != null and _plot_frame_node != null:
		calculate_offset_from_plot_frame(_display_frame_node, _plot_frame_node)

func _draw_ticks() -> void:
	self.ticks_pos.clear()

	var font: Font = get_theme_default_font()
	var tick_x_pos: int = self.top_right().x
	var top_y: float = self.top_right().y
	var pixel_height: float = size.y
	if pixel_height <= 0.0:
		return

	var range_span: float = self.max_val - self.min_val
	if range_span == 0.0:
		return

	var pixels_per_unit: float = pixel_height / range_span
	var exponent: int = _get_scale_exponent()

	# Lock the tick increment for the whole drag so ticks slide smoothly
	# instead of snapping when the nice-number boundary changes.
	var y_increment: float
	if _drag_active and _drag_tick_increment_cached > 0.0:
		y_increment = _drag_tick_increment_cached
	else:
		y_increment = _nice_increment(abs(range_span) / 5.0)

	var y1: float = ceil(self.min_val / y_increment) * y_increment
	var y2: float = floor(self.max_val / y_increment) * y_increment
	self.n_steps = int(round((y2 - y1) / y_increment))
	if self.n_steps <= 0:
		self.n_steps = 1

	# Pre-compute labels; also measure the endpoint labels for max width.
	var tick_vals: Array[float] = []
	var labels: Array[String] = []
	var max_label_width: float = 0.0
	var tick_count: int = self.n_steps + 1
	for i in range(tick_count):
		var v: float = y2 - i * y_increment
		tick_vals.append(v)
		var label: String = _format_tick_label(v, exponent)
		labels.append(label)
		var w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if w > max_label_width:
			max_label_width = w

	var max_endpoint_label: String = _format_tick_label(self.max_val, exponent)
	var min_endpoint_label: String = _format_tick_label(self.min_val, exponent)
	for lbl in [max_endpoint_label, min_endpoint_label]:
		var w: float = font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if w > max_label_width:
			max_label_width = w

	_cached_label_width = max_label_width
	var label_x: float = tick_x_pos - (max_label_width + 3)
	var tick_label_offset: Vector2 = Vector2(-(max_label_width + 3), 5)
	# Keep a margin around axis edges so interior ticks never overlap the endpoint labels.
	var edge_margin: float = font_size * 2.0

	_max_label_rect = Rect2(label_x - 2, top_y + 5 - font_size,                   max_label_width + 8, font_size + 6)
	_min_label_rect = Rect2(label_x - 2, top_y + pixel_height + 5 - font_size,    max_label_width + 8, font_size + 6)

	# Interior sliding ticks — skip any that fall within the edge margin so they
	# don't visually clash with the always-visible endpoint labels.
	for i in range(tick_count):
		var tick_y: float = top_y + (self.max_val - tick_vals[i]) * pixels_per_unit
		if tick_y < top_y + edge_margin or tick_y > top_y + pixel_height - edge_margin:
			continue

		var color: Color = self.line_color
		if not _drag_active:
			if i == 0 and _hover_max:
				color = Guidot_Utils.get_color("gd_bright_yellow")
			elif i == tick_count - 1 and _hover_min:
				color = Guidot_Utils.get_color("gd_bright_yellow")

		self._draw_single_tick_with_label(
			Vector2(tick_x_pos, int(tick_y)),
			labels[i],
			font,
			self.font_size,
			color,
			tick_label_offset
		)

	# Always-visible endpoint labels at the axis edges, showing the live min/max.
	# These remain at fixed pixel positions so the user always sees the axis limits,
	# even as the interior ticks slide during a drag.
	self._draw_single_tick_with_label(
		Vector2(tick_x_pos, int(top_y)),
		max_endpoint_label, font, self.font_size, self.line_color, tick_label_offset
	)
	self._draw_single_tick_with_label(
		Vector2(tick_x_pos, int(top_y + pixel_height)),
		min_endpoint_label, font, self.font_size, self.line_color, tick_label_offset
	)

	if exponent != 0:
		var scale_str: String = "x10^%d" % exponent
		var scale_w: float = font.get_string_size(scale_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var scale_x: float = tick_x_pos - scale_w
		var scale_y: float = top_y - font_size - 4.0
		draw_string(font, Vector2(scale_x, scale_y), scale_str,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
				Guidot_Utils.get_color("gd_bright_yellow"))

	if _display_frame_node != null:
		var chan_on_this_axis: Array[Array] = _display_frame_node.get_y_axis_manager().get_chan_name_and_color_on_axis(self._axis_id)
		if not chan_on_this_axis.is_empty():
			_draw_channel_labels(chan_on_this_axis, font, top_y, pixel_height, label_x)

func _draw_channel_labels(chan_name_and_color: Array[Array], font: Font, top_y: float, pixel_height: float, label_x: float) -> void:
	var gap: float = 8.0
	var center_y: float = top_y + pixel_height / 2.0

	# Measure each label — when rotated 90°, text width becomes the vertical span on screen.
	var text_widths: Array = []
	for ch_properties: Array in chan_name_and_color:
		var ch_name: String = ch_properties[0]
		text_widths.append(font.get_string_size(ch_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)

	var total_span: float = 0.0
	for w: float in text_widths:
		total_span += w
	total_span += (chan_name_and_color.size() - 1) * gap

	# Start y so the whole group is centred on the axis midpoint.
	var y_cursor: float = center_y - total_span / 2.0

	# With –PI/2 rotation, text appears at screen x = col_x + font_size.
	# Place the column just to the left of the tick labels.
	var col_x: float = label_x - 4.0 - font_size

	for i in range(chan_name_and_color.size()):
		var text: String = chan_name_and_color[i][0]
		var color: Color = chan_name_and_color[i][1]

		if (i != (chan_name_and_color.size() - 1)):
			print(text)
			text += ", "

		var text_width: float = text_widths[i]

		# Skip labels entirely outside the axis bounds.
		if y_cursor > top_y + pixel_height or y_cursor + text_width < top_y:
			y_cursor += text_width + gap
			continue

		# Pivot calculation for –PI/2 rotation:
		# local (lx, font_size) → screen (col_x + font_size, pivot_y - lx)
		# so the string centre in screen y lands at y_cursor + text_width / 2.
		var pivot_y: float = y_cursor + text_width
		draw_set_transform(Vector2(col_x, pivot_y), -PI / 2.0)
		draw_string(font, Vector2(0.0, font_size), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
		draw_set_transform(Vector2.ZERO, 0.0)

		y_cursor += text_width + gap

func _on_drag_start() -> void:
	_drag_tick_increment_cached = _nice_increment(abs(self.max_val - self.min_val) / 5.0)

func _apply_drag_delta(pixel_delta: Vector2) -> void:
	var pixel_height: float = size.y
	if pixel_height <= 0.0:
		return
	var value_delta: float = pixel_delta.y * (self.max_val - self.min_val) / pixel_height
	setup_axis_range(self.min_val + value_delta, self.max_val + value_delta)

func _commit_drag() -> void:
	_drag_tick_increment_cached = 0.0

func draw_y_axis() -> void:
	draw_line(self.top_right(), self.bottom_right(), self.line_color, 1.0, true)
	_draw_ticks()

func _draw() -> void:
	self.draw_y_axis()
