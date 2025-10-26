class_name Guidot_Y_Axis
extends Guidot_Axis

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
	self.norm_comp_size = 0.1


func calculate_offset_from_plot_frame(display_frame_node: Node, plot_frame_node: Node) -> void:
	self.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT)
	self.axis_width = (display_frame_node.size.x - plot_frame_node.size.x)/2
	self.offset_left = plot_frame_node.offset_left - self.axis_width
	self.offset_right = plot_frame_node.offset_left
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
