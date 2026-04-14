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

# ── Inline label editing ──────────────────────────────────────────────────────
# Hit-test rects for the topmost (max_val) and bottommost (min_val) tick labels.
# Recomputed every _draw_ticks() call so they always match the rendered position.
var _top_label_rect: Rect2 = Rect2()
var _bottom_label_rect: Rect2 = Rect2()

var _hover_top: bool = false
var _hover_bottom: bool = false

# Single reusable LineEdit overlay; repositioned for whichever label is active.
var _inline_edit: LineEdit

# true  → user is editing max_val (top label)
# false → user is editing min_val (bottom label)
var _editing_max: bool = true

# Cached from the last _draw_ticks() so _start_inline_edit() can size the widget.
var _cached_label_width: float = 30.0
# -----------------------------------------------------------------------------

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

	# Inline edit widget — hidden until the user clicks a label
	_inline_edit = LineEdit.new()
	_inline_edit.visible = false
	_inline_edit.add_theme_font_size_override("font_size", int(font_size))
	_inline_edit.text_submitted.connect(_on_inline_edit_submitted)
	_inline_edit.gui_input.connect(_on_inline_edit_gui_input)
	# Clicking anywhere else discards the edit
	_inline_edit.focus_exited.connect(func(): _inline_edit.visible = false)
	add_child(_inline_edit)

func set_axis_id(ax_id: int) -> void:
	self._axis_id = ax_id

# Returns the power-of-10 exponent to use as a common scale factor for the
# current min/max range.  Returns 0 when no scaling is needed.
#
#   >= 1000  or  < 0.001  →  scale so mantissa values sit in [1, 1000)
#   everything else       →  no scaling (return 0)
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
	var axis_frame_size: Vector2 = self.get_component_size()
	var increments: int = axis_frame_size.y / n_steps
	var tick_interval: float = (self.max_val - self.min_val) / self.n_steps
	var exponent: int = _get_scale_exponent()

	# Pre-compute all labels so we can measure the widest before drawing any.
	var labels: Array[String] = []
	var max_label_width: float = 0.0
	for i in range(n_steps + 1):
		var label: String = _format_tick_label(self.max_val - i * tick_interval, exponent)
		labels.append(label)
		var w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if w > max_label_width:
			max_label_width = w

	_cached_label_width = max_label_width

	# Right-align every label against the tick mark with a 3 px gap.
	var label_x: float = tick_x_pos - (max_label_width + 3)
	var tick_label_offset: Vector2 = Vector2(-(max_label_width + 3), 5)

	# Update hit-test rects for the top (max_val) and bottom (min_val) labels.
	# draw_string baseline is at tick_y + 5, so the text body spans
	# (baseline - font_size) to (baseline + ~4px).
	var top_tick_y: int    = self.top_right().y
	var bottom_tick_y: int = self.top_right().y + n_steps * increments
	_top_label_rect    = Rect2(label_x - 2, top_tick_y    + 5 - font_size, max_label_width + 8, font_size + 6)
	_bottom_label_rect = Rect2(label_x - 2, bottom_tick_y + 5 - font_size, max_label_width + 8, font_size + 6)

	for i in range(n_steps + 1):
		var tick_y_pos: int = self.top_right().y + i * increments
		# Highlight the top or bottom label when the mouse hovers over it
		var color: Color = self.line_color
		if i == 0 and _hover_top:
			color = Guidot_Utils.get_color("gd_bright_yellow")
		elif i == n_steps and _hover_bottom:
			color = Guidot_Utils.get_color("gd_bright_yellow")
		self._draw_single_tick_with_label(
			Vector2(tick_x_pos, tick_y_pos),
			labels[i],
			font,
			self.font_size,
			color,
			tick_label_offset
		)

	# When a scale exponent is active, draw "x10^N" at the top of the axis so
	# the user can always see what scale the mantissa values refer to.
	if exponent != 0:
		var scale_str: String = "x10^%d" % exponent
		var scale_w: float = font.get_string_size(scale_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		# Right-align it to the tick line.
		# scale_y uses top_right().y (which reflects the live axis size) so the
		# label automatically follows whenever the graph is resized.
		var scale_x: float = tick_x_pos - scale_w
		var scale_y: float = self.top_right().y - font_size - 4.0
		draw_string(font, Vector2(scale_x, scale_y), scale_str,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
				Guidot_Utils.get_color("gd_bright_yellow"))

func draw_y_axis() -> void:
	draw_line(self.top_right(), self.bottom_right(), self.line_color, 1.0, true)
	_draw_ticks()

func _draw() -> void:
	self.draw_y_axis()

func _process(_delta: float) -> void:
	# Track whether the mouse is hovering over either editable label so _draw()
	# knows which one to highlight.  Only runs when the inline edit is closed to
	# avoid fighting with the LineEdit for hover state.
	if _inline_edit.visible:
		return

	var local_mouse: Vector2 = get_local_mouse_position()
	var new_hover_top:    bool = _mouse_in and _top_label_rect.has_point(local_mouse)
	var new_hover_bottom: bool = _mouse_in and _bottom_label_rect.has_point(local_mouse)

	if new_hover_top != _hover_top or new_hover_bottom != _hover_bottom:
		_hover_top    = new_hover_top
		_hover_bottom = new_hover_bottom
		queue_redraw()

func _input(event: InputEvent) -> void:
	# While the inline editor is open, suppress all axis interactions so wheel
	# zoom and right-click menus don't interfere.
	if _inline_edit.visible:
		return

	# Check for a left-click on the top or bottom tick label BEFORE calling
	# super, so we don't also emit the generic focus-request signal.
	if _mouse_in and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Double-click anywhere on the axis opens the full limit settings panel.
			if event.double_click:
				_axis_limit_config.show_for_axis(self.min_val, self.max_val, get_viewport().get_mouse_position())
				return
			var local_mouse: Vector2 = get_local_mouse_position()
			if _top_label_rect.has_point(local_mouse):
				_start_inline_edit(true)
				return
			elif _bottom_label_rect.has_point(local_mouse):
				_start_inline_edit(false)
				return

	super._input(event)

# Show the inline LineEdit positioned over the chosen label.
# We always display and accept the raw axis value here — the "x10^N" label on
# the axis is purely a cosmetic scale indicator and must NOT be folded into the
# edit field.  Showing the mantissa caused a compounding-exponent bug: if the
# user typed the raw value instead of the mantissa (easy mistake), the result
# was raw_value × 10^N instead of raw_value, which then raised the exponent for
# the next edit, creating an exponential runaway.
func _start_inline_edit(editing_max: bool) -> void:
	_editing_max = editing_max
	var rect: Rect2    = _top_label_rect if editing_max else _bottom_label_rect
	var current_val: float = self.max_val if editing_max else self.min_val

	_inline_edit.text     = "%g" % current_val
	_inline_edit.position = rect.position
	_inline_edit.size     = Vector2(_cached_label_width + 24, font_size + 8)
	_inline_edit.visible  = true
	_inline_edit.grab_focus()
	_inline_edit.select_all()

# Enter pressed — the text is the raw limit value, no exponent involved.
func _on_inline_edit_submitted(new_text: String) -> void:
	var new_value: float = new_text.to_float()

	if _editing_max:
		if new_value != self.min_val:
			setup_axis_range(self.min_val, new_value)
	else:
		if new_value != self.max_val:
			setup_axis_range(new_value, self.max_val)

	_inline_edit.visible = false

# Escape pressed — discard and close without changing anything.
func _on_inline_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_inline_edit.visible = false
			get_viewport().set_input_as_handled()
