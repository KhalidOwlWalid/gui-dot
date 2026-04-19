class_name Guidot_Axis
extends Guidot_Common

signal axis_limit_changed

var min_val: float
var max_val: float
@onready var n_steps: int = 5
@onready var axis_name: String = "axis_common"
@onready var tick_length: int = 0
@onready var min_width: int = 0
@onready var max_width: int = 50

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
var left_offset
var right_offset
var top_offset
var bottom_offset

var _axis_config_popup: PopupMenu
var _axis_limit_config: Guidot_Axis_Limit_Config

var _mouse_hold_frame_count: int = 5
var _mouse_hold_frame_count_max: int = 5
var _axis_drag_mode_active: bool = false
var _axis_drag_mouse_pos: Vector2 = get_local_mouse_position()
var _drag_active: bool = false

# ── Shared inline-edit infrastructure ────────────────────────────────────────
# Hit-test rects for the two editable limit labels.  Each subclass is
# responsible for computing these inside its _draw_ticks() call so they always
# match the rendered positions.
#
#   Y-axis: _max_label_rect = topmost label    (max_val)
#           _min_label_rect = bottommost label (min_val)
#   X/T-axis: _min_label_rect = leftmost label  (min_val)
#             _max_label_rect = rightmost label (max_val)
var _min_label_rect: Rect2 = Rect2()
var _max_label_rect: Rect2 = Rect2()
var _hover_min: bool = false
var _hover_max: bool = false
var _inline_edit: LineEdit
var _editing_max: bool = true
# Widest tick-label pixel width from the last draw; used to size the edit field.
var _cached_label_width: float = 30.0
# -----------------------------------------------------------------------------

func set_axis_id(ax_id: int) -> void:
	pass

func init_event_handler() -> void:
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)

func setup_axis_node(name: String, color: Color) -> void:
	self.name = name
	self.clip_contents = false
	self.color = color
	self.init_event_handler()

func setup_axis_range(min: float, max: float) -> void:
	self.min_val = min
	self.max_val = max
	axis_limit_changed.emit()
	queue_redraw()

func get_axis_range() -> Vector2:
	return Vector2(self.min_val, self.max_val)

func get_axis_width() -> int:
	return self.axis_width

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

# Override in subclass to translate pixel drag delta into axis range shift.
func _apply_drag_delta(_pixel_delta: Vector2) -> void:
	pass

# Called once when Ctrl+Left-Click drag begins; override to lock per-drag state.
func _on_drag_start() -> void:
	pass

# Override in subclass to clean up per-drag state when drag ends.
func _commit_drag() -> void:
	pass

func _stop_drag() -> void:
	if _drag_active:
		_commit_drag()
	_drag_active = false

func _on_axis_config_menu_index_pressed(index: int) -> void:
	if index == 0:
		var pos: Vector2 = self.get_viewport().get_mouse_position()
		_axis_limit_config.show_for_axis(self.min_val, self.max_val, pos)

func _setup_axis_config_menu() -> void:
	_axis_config_popup = PopupMenu.new()
	add_child(_axis_config_popup)
	_axis_config_popup.name = "Axis Configuration Menu"
	_axis_config_popup.add_item("Axis Limit Settings")
	_axis_config_popup.hide_on_checkable_item_selection = false
	_axis_config_popup.hide_on_item_selection = true
	_axis_config_popup.hide_on_state_item_selection = false
	_axis_config_popup.index_pressed.connect(_on_axis_config_menu_index_pressed)

	_axis_limit_config = Guidot_Axis_Limit_Config.new()
	_axis_limit_config.limits_applied.connect(func(new_min: float, new_max: float): self.setup_axis_range(new_min, new_max))
	add_child(_axis_limit_config)

# Call this from _ready() in every subclass (alongside _setup_axis_config_menu).
func _setup_inline_edit() -> void:
	_inline_edit = LineEdit.new()
	_inline_edit.visible = false
	_inline_edit.add_theme_font_size_override("font_size", int(font_size))
	_inline_edit.text_submitted.connect(_on_inline_edit_submitted)
	_inline_edit.gui_input.connect(_on_inline_edit_gui_input)
	# Clicking anywhere outside discards the edit without applying.
	_inline_edit.focus_exited.connect(func(): _inline_edit.visible = false)
	add_child(_inline_edit)

# Show the inline LineEdit over the chosen limit label.
# The edit always shows/accepts the raw axis value so there is no
# exponent-related confusion (see bug fix in guidot_y_axis.gd for details).
func _start_inline_edit(editing_max: bool) -> void:
	_editing_max = editing_max
	var rect: Rect2 = _max_label_rect if editing_max else _min_label_rect
	var current_val: float = self.max_val if editing_max else self.min_val
	_inline_edit.text     = "%g" % current_val
	_inline_edit.position = rect.position
	_inline_edit.size     = Vector2(_cached_label_width + 24, font_size + 8)
	_inline_edit.visible  = true
	_inline_edit.grab_focus()
	_inline_edit.select_all()

# Enter pressed — apply the raw typed value directly.
func _on_inline_edit_submitted(new_text: String) -> void:
	var new_value: float = new_text.to_float()
	if _editing_max:
		if new_value != self.min_val:
			setup_axis_range(self.min_val, new_value)
	else:
		if new_value != self.max_val:
			setup_axis_range(new_value, self.max_val)
	_inline_edit.visible = false

# Escape pressed — discard without applying.
func _on_inline_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_inline_edit.visible = false
			get_viewport().set_input_as_handled()

func calculate_offset_from_plot_frame(display_frame_node: Node, plot_frame_node: Node) -> void:
	pass

# NOTE: If you use this function, please call "self.ticks_pos.clear()" to clear the old axis ticks, so we can draw new ones
func _draw_single_tick_with_label(tick_pos: Vector2, label: String, font_type: Font, font_size: float, color: Color, label_offset: Vector2) -> void:

	var tick_label_x_pos: int = tick_pos.x + label_offset.x
	var tick_label_y_pos: int = tick_pos.y + label_offset.y

	self.ticks_pos.append(tick_pos)
	draw_line(tick_pos, Vector2(tick_pos.x, tick_pos.y + self.tick_length), color, 1.0, true)
	self.draw_string(font_type, Vector2(tick_label_x_pos, tick_label_y_pos), label, 0, -1, font_size, color)


func _ready() -> void:
	self.color = Guidot_Utils.get_color("gd_black")
	self.line_color = Guidot_Utils.get_color("white")
	self.last_box_color = self.color
	self.last_line_color = self.line_color
	font_size = 10
	self.set_component_tag_name("AXIS")

	self._setup_axis_config_menu()

	norm_comp_size = Vector2(0.2, 0.2)

func _draw() -> void:
	pass

# Track hover state for the two editable limit labels so _draw() can
# highlight them.  Runs on every frame; only triggers a redraw when state
# actually changes.
func _process(_delta: float) -> void:
	if _inline_edit == null or _inline_edit.visible:
		return
	# var local_mouse: Vector2 = get_local_mouse_position()
	# var new_hover_min: bool = _mouse_in and _min_label_rect.has_point(local_mouse)
	# var new_hover_max: bool = _mouse_in and _max_label_rect.has_point(local_mouse)
	# if new_hover_min != _hover_min or new_hover_max != _hover_max:
	# 	_hover_min = new_hover_min
	# 	_hover_max = new_hover_max

	if self._axis_drag_mode_active:
		var local_mouse: Vector2 = get_local_mouse_position()

	queue_redraw()

func _on_mouse_entered() -> void:
	self.last_box_color = self.color
	self.last_line_color = self.line_color
	self.color = Guidot_Utils.get_color("gd_dim_blue")
	self.line_color = Guidot_Utils.get_color("gd_bright_yellow")
	self._mouse_in = true
	queue_redraw()

func _on_mouse_exited() -> void:
	self.color = self.last_box_color
	self.line_color = self.last_line_color
	self._mouse_in = false
	_stop_drag()
	_axis_drag_mode_active = false
	queue_redraw()

# Returns the nearest 'nice' increment (1, 2, or 5 × 10^N) at or below raw.
# This keeps tick labels at round numbers regardless of window size.
# Resource: http://vis.stanford.edu/files/2010-TickLabels-InfoVis.pdf
static func _nice_increment(raw: float) -> float:
	if raw <= 0.0:
		return 1.0
	var exp: int = int(floor(log(raw) / log(10.0)))
	var base: float = pow(10.0, exp)
	var frac: float = raw / base
	var nice: float
	if frac < 1.5:
		nice = 1.0
	elif frac < 3.5:
		nice = 2.0
	elif frac < 7.5:
		nice = 5.0
	else:
		nice = 10.0
	return nice * base

func _input(event):
	# While the inline editor is open suppress all other axis interactions.
	if _inline_edit != null and _inline_edit.visible:
		return

	# Release drag if Ctrl is lifted anywhere.
	if event is InputEventKey and not event.pressed and event.keycode == KEY_CTRL:
		_stop_drag()
		_axis_drag_mode_active = false

	# Release drag if left button released anywhere.
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_stop_drag()

	if not self._mouse_in:
		return

	var zoom_factor: float = 1.1
	var curr_axis_centre: float = (self.min_val + self.max_val) / 2
	var current_range: float = self.max_val - self.min_val
	var new_range: float
	var r1: float = 0.5
	var r2: float = 0.5

	if Input.is_key_pressed(KEY_CTRL):
		_axis_drag_mode_active = true

		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_drag_active = true
			_axis_drag_mouse_pos = get_local_mouse_position()
			_on_drag_start()
			return

		if event is InputEventMouseMotion and _drag_active:
			var local_mouse: Vector2 = get_local_mouse_position()
			var delta: Vector2 = local_mouse - _axis_drag_mouse_pos
			_apply_drag_delta(delta)
			_axis_drag_mouse_pos = local_mouse
			return
	else:
		_stop_drag()
		_axis_drag_mode_active = false

		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				new_range = current_range / zoom_factor
				self.setup_axis_range(curr_axis_centre - new_range * r1, curr_axis_centre + new_range * r2)

			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				new_range = current_range * zoom_factor
				self.setup_axis_range(curr_axis_centre - new_range * r2, curr_axis_centre + new_range * r2)

			if event.button_index == MOUSE_BUTTON_RIGHT:
				var curr_mouse_pos: Vector2 = self.get_viewport().get_mouse_position()
				var popup_size: Vector2 = Vector2(200, 200)
				var popup_rect: Rect2i = Rect2i(curr_mouse_pos, popup_size)
				_axis_config_popup.popup(popup_rect)
				self.log(LOG_DEBUG, ["[", self.name, "]", _axis_config_popup.name, "open at position:", curr_mouse_pos])

			if event.button_index == MOUSE_BUTTON_LEFT:
				# Double-click anywhere on the axis opens the full limit settings panel.
				if event.double_click:
					_axis_limit_config.show_for_axis(self.min_val, self.max_val, get_viewport().get_mouse_position())
					return
				# Single-click on a limit label opens the inline editor for that limit.
				if _inline_edit != null:
					var local_mouse: Vector2 = get_local_mouse_position()
					if _max_label_rect.has_point(local_mouse):
						_start_inline_edit(true)
						return
					elif _min_label_rect.has_point(local_mouse):
						_start_inline_edit(false)
						return

				self._emit_focus_requested_signal()
