class_name Guidot_X_Axis
extends Guidot_Axis

func update_debug_info() -> void:
	self.debug_signals_to_trace = {
		"t axis: mouse_in": self._mouse_in,
	}

func _ready() -> void:
	self.line_color = Guidot_Utils.get_color("white")
	self.last_line_color = self.line_color
	self.ticks_pos = PackedVector2Array()
	var tick_y_pos: int = self.top_left().y
	var axis_frame_size: Vector2 = self.get_component_size()
	var increments: int  = axis_frame_size.x / n_steps
	for i in range(n_steps + 1):
		var tick_x_pos: int = self.top_left().x + i * increments
		self.ticks_pos.append(Vector2(tick_x_pos, tick_y_pos))

	self._setup_axis_config_menu()
	self._setup_inline_edit()
	self.set_component_tag_name("X-AXIS")

	self.norm_comp_size = Vector2(0.1, 0.1)

func calculate_offset_from_plot_frame(display_frame_node: Node, plot_frame_node: Node) -> void:
	self.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT)
	
	self.axis_height = (display_frame_node.size.y - plot_frame_node.size.y)/2

	# Set the position of the edges of the axis position from the center anchor of the parent
	self.offset_left = plot_frame_node.offset_left
	self.offset_right = plot_frame_node.offset_right
	self.offset_top = plot_frame_node.offset_bottom
	self.offset_bottom = plot_frame_node.offset_bottom + self.axis_height

func _draw_ticks() -> void:
	pass

func _apply_drag_delta(pixel_delta: Vector2) -> void:
	var pixel_width: float = size.x
	if pixel_width == 0.0:
		return
	var value_delta: float = -pixel_delta.x / pixel_width * (self.max_val - self.min_val)
	setup_axis_range(self.min_val + value_delta, self.max_val + value_delta)

func draw_x_axis() -> void:
	# Draw the vertical line of the x-axis 
	draw_line(self.top_left(), self.top_right(), self.line_color, 1.0, true)
	_draw_ticks()

func _draw() -> void:
	self.draw_x_axis()
