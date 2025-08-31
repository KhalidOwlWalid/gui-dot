class_name Guidot_X_Axis
extends Guidot_Axis

func calculate_offset_from_plot_frame(display_frame_node: Node, plot_frame_node: Node) -> void:
	self.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER)
	self.axis_width = (display_frame_node.size.x - plot_frame_node.size.x)/2
	self.offset_left = plot_frame_node.offset_left - self.axis_width
	self.offset_right = plot_frame_node.offset_left
	self.offset_top = plot_frame_node.offset_top
	self.offset_bottom = plot_frame_node.offset_bottom

func draw_x_axis() -> void:
	# Draw the vertical line of the x-axis 
	draw_line(self.top_right(), self.bottom_right(), Color.WHITE, 1.0, true)
	_draw_ticks()

func _draw_ticks() -> void:
	var tick_x_pos: int = self.top_right().x
	var axis_frame_size: Vector2 = self.get_component_size()
	var increments: int  = axis_frame_size.y / n_steps
	for i in range(n_steps):
		var tick_y_pos: int = self.top_right().y + i * increments
		draw_line(Vector2(tick_x_pos, tick_y_pos), Vector2(tick_x_pos - self.tick_length, tick_y_pos), Color.WHITE, 1.0, true)

func _draw() -> void:
	self.draw_x_axis()

func _process(delta: float) -> void:
	pass
