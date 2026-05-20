class_name Guidot_T_Axis_Canvas
extends Guidot_X_Axis_Canvas

# For the t-axis, we have a slightly different tick drawing implementation
# If we are plotting in real-time, then the plot will basically move like a sliding window
# Hence, we override the _draw_ticks function from the Guidot_X_Axis_Canvas class

enum TAxisMode {
	# User sets min/max directly via inline edit or context menu.
	# The axis will NOT auto-update when new data arrives.
	FIXED,
	# Axis automatically tracks the latest data point:
	#   min = x_last - window_size_s,  max = x_last
	# Call update_to_latest(x_last) each frame to advance the window.
	SLIDING_WINDOW,
}

var _mode: TAxisMode = TAxisMode.FIXED

# Width of the sliding window in the same units as the x-axis.  Only used
# when _mode == SLIDING_WINDOW.  Configurable via the right-click menu.
var window_size_s: float = 10.0

var _window_config_popup: PopupPanel
var _window_size_input: LineEdit

func _ready() -> void:
	super._ready()
	# Add a second right-click menu item for sliding window configuration.
	_axis_config_popup.add_item("Sliding Window Settings")
	_setup_window_config_popup()

func change_graph_mode(new_mode: TAxisMode):
	self._mode = new_mode

func set_window_size_s(time_window_s: float) -> void:
	if (time_window_s < 0):
		self.log(LOG_DEBUG, ["Invalid time window of", time_window_s, "s"])
		return
	else:
		window_size_s = time_window_s

# Override so that any user-initiated range change (inline edit, Axis Limit
# Settings apply) switches the axis to FIXED mode.  The internal sliding-
# window update bypasses this by calling _advance_window() instead.
func setup_axis_range(min_v: float, max_v: float, trigger_redraw: bool = true) -> void:
	super.setup_axis_range(min_v, max_v, trigger_redraw)

# Called by the graph every frame with the latest x value.
# Only advances the window when in SLIDING_WINDOW mode.
func update_to_latest(x_last: float) -> void:
	if _mode == TAxisMode.SLIDING_WINDOW:
		# Update range directly — does NOT switch mode to FIXED.
		self.min_val = x_last - window_size_s
		self.max_val = x_last
		axis_limit_changed.emit()
		queue_redraw()

func get_current_t_axis_mode() -> TAxisMode:
	return self._mode

func _setup_window_config_popup() -> void:
	_window_config_popup = PopupPanel.new()
	add_child(_window_config_popup)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_window_config_popup.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var hbox: HBoxContainer = HBoxContainer.new()
	var lbl: Label = Label.new()
	lbl.text = "Window size:"
	lbl.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(lbl)

	_window_size_input = LineEdit.new()
	_window_size_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_window_size_input.text_submitted.connect(func(_s): _on_window_apply_pressed())
	hbox.add_child(_window_size_input)
	vbox.add_child(hbox)

	var apply_btn: Button = Button.new()
	apply_btn.text = "Apply"
	apply_btn.pressed.connect(_on_window_apply_pressed)
	vbox.add_child(apply_btn)

func _on_window_apply_pressed() -> void:
	var new_size: float = _window_size_input.text.to_float()
	if new_size > 0.0:
		window_size_s = new_size
		_mode = TAxisMode.SLIDING_WINDOW
	_window_config_popup.hide()

# Override the base-class handler to support the extra menu item.
func _on_axis_config_menu_index_pressed(index: int) -> void:
	var pos: Vector2 = self.get_viewport().get_mouse_position()
	if index == 0:
		# "Axis Limit Settings" — let the user set a fixed range.
		# Applying limits switches the axis to FIXED mode.
		_axis_limit_config.show_for_axis(self.min_val, self.max_val, pos)
		_mode = TAxisMode.FIXED
	elif index == 1:
		# "Sliding Window Settings" — configure the window size.
		_window_size_input.text = "%g" % window_size_s
		_window_config_popup.popup(Rect2i(Vector2i(pos), Vector2i(220, 80)))
		_mode = TAxisMode.SLIDING_WINDOW

func _draw_ticks() -> void:
	self.ticks_pos.clear()

	var range_span: float = abs(self.max_val - self.min_val)

	# Auto-calculate tick spacing to give roughly 5 ticks with a clean interval
	# (nearest 1, 2, or 5 × 10^N), so labels always snap to round numbers
	# regardless of the window size.
	var t_increment: float = _nice_increment(range_span / 5.0)

	var t1: float = ceil(self.min_val / t_increment) * t_increment
	var t2: float = floor(self.max_val / t_increment) * t_increment
	self.n_steps = int(round((t2 - t1) / t_increment))
	if self.n_steps <= 0:
		self.n_steps = 1

	var font: Font = self.get_theme_default_font()
	var tick_label_offset: Vector2 = Vector2(5, 20)

	var tick_label: String
	for i in range(self.n_steps + 1):
		var curr_tick_val: float = i * t_increment + t1
		var x_tick_pos: float = remap(curr_tick_val, self.min_val, self.max_val, self.top_left().x, self.top_right().x)
		var curr_tick_pixel_pos: Vector2 = Vector2(x_tick_pos, self.top_right().y)
		tick_label = "%0.2f" % curr_tick_val
		self._draw_single_tick_with_label(curr_tick_pixel_pos, tick_label, font, self.font_size, self.line_color, tick_label_offset)

	# Measure label width for inline editor sizing.
	var first_label: String = "%0.2f" % self.min_val
	var last_label: String  = "%0.2f" % self.max_val
	var w1: float = font.get_string_size(first_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var w2: float = font.get_string_size(last_label,  HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_cached_label_width = max(w1, w2)

	# First tick — represents min_val (leftmost, editable inline).
	var first_tick_pos: Vector2 = self.top_left()
	var first_color: Color = Guidot_Utils.get_color("gd_bright_yellow") if _hover_min else self.line_color
	self._draw_single_tick_with_label(first_tick_pos, first_label, font, self.font_size, first_color, tick_label_offset)

	# Last tick — represents max_val (rightmost, editable inline).
	var last_tick_pos: Vector2 = self.top_right()
	var last_color: Color = Guidot_Utils.get_color("gd_bright_yellow") if _hover_max else self.line_color
	self._draw_single_tick_with_label(last_tick_pos, last_label, font, self.font_size, last_color, tick_label_offset)

	# Hit-test rects for inline editing.  Labels are drawn below the tick:
	# baseline at tick_y + 20, body spans (20 - font_size) to (20 + ~4px).
	var tick_y: float = self.top_left().y
	_min_label_rect = Rect2(first_tick_pos.x + tick_label_offset.x - 2,
							tick_y + tick_label_offset.y - font_size,
							_cached_label_width + 8, font_size + 6)
	_max_label_rect = Rect2(last_tick_pos.x  + tick_label_offset.x - 2,
							tick_y + tick_label_offset.y - font_size,
							_cached_label_width + 8, font_size + 6)
