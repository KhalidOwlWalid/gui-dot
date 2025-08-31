class_name Guidot_Y_Axis
extends Guidot_Axis

func calculate_offset_from_plot_frame(display_frame_node: Node, plot_frame_node: Node) -> void:
	self.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER)
	self.axis_height = (display_frame_node.size.y - plot_frame_node.size.y)/2
	self.offset_left = plot_frame_node.offset_left
	self.offset_right = plot_frame_node.offset_right
	self.offset_top = plot_frame_node.offset_bottom
	self.offset_bottom = plot_frame_node.offset_bottom + self.axis_height

func draw_y_axis() -> void:
	# Draw the vertical line of the x-axis 
	draw_line(self.top_left(), self.top_right(), Color.WHITE, 1.0, true)
	_draw_ticks()

func _draw_ticks() -> void:
	var tick_y_pos: int = self.top_left().y
	var axis_frame_size: Vector2 = self.get_component_size()
	var increments: int  = axis_frame_size.x / n_steps
	for i in range(n_steps):
		var tick_x_pos: int = self.top_left().x + i * increments
		draw_line(Vector2(tick_x_pos, tick_y_pos), Vector2(tick_x_pos, tick_y_pos + self.tick_length), Color.WHITE, 1.0, true)

func _draw() -> void:
	self.draw_y_axis()

func _process(delta: float) -> void:
	pass
