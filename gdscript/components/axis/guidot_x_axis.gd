class_name Guidot_X_Axis
extends Guidot_Axis

func update_debug_info() -> void:
	self.debug_signals_to_trace = {
		"t axis: mouse_in": self._mouse_in,
	}

func _ready() -> void:
	self.line_color = Guidot_Utils.color_dict["white"]
	self.last_line_color = self.line_color
	self.ticks_pos = PackedVector2Array()
	var tick_y_pos: int = self.top_left().y
	var axis_frame_size: Vector2 = self.get_component_size()
	var increments: int  = axis_frame_size.x / n_steps
	for i in range(n_steps + 1):
		var tick_x_pos: int = self.top_left().x + i * increments
		self.ticks_pos.append(Vector2(tick_x_pos, tick_y_pos))

	self._setup_axis_config_menu()
	self.set_component_tag_name("X-AXIS")

	self.norm_comp_size = 0.05

func calculate_offset_from_plot_frame(display_frame_node: Node, plot_frame_node: Node) -> void:
	self.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT)
	
	self.axis_height = (display_frame_node.size.y - plot_frame_node.size.y)/2

	# Set the position of the edges of the axis position from the center anchor of the parent
	self.offset_left = plot_frame_node.offset_left
	self.offset_right = plot_frame_node.offset_right
	self.offset_top = plot_frame_node.offset_bottom
	self.offset_bottom = plot_frame_node.offset_bottom + self.axis_height

func _draw_ticks() -> void:
	
	# This implementation is for a fixed grid
	# self.ticks_pos = PackedVector2Array()
	# var tick_y_pos: int = self.top_left().y
	# var axis_frame_size: Vector2 = self.get_component_size()
	# self.n_steps = 5
	# var increments: int  = axis_frame_size.x / n_steps
	# var tick_interval: float = (self.max_val - self.min_val) / n_steps

	# for i in range(n_steps + 1):
	# 	var tick_x_pos: int = self.top_left().x + i * increments
	# 	draw_line(Vector2(tick_x_pos, tick_y_pos), Vector2(tick_x_pos, tick_y_pos + self.tick_length), self.line_color, 1.0, true)
	# 	self.ticks_pos.append(Vector2(tick_x_pos, tick_y_pos))

	# 	# Bugfix (Khalid): Idk why tf I cant define this as a @onready var, everytime I do, the system complains "bad address index"???
	# 	# This error causes the axis to not build, but y axis is fine, although it is the same implementation
	# 	# However, if you run the scene, it draws the axis fine?
	# 	# n count of me crashing out from this error: 20 WATAFAK
	# 	var tick_label_x_offset = 5
	# 	var tick_label_y_offset = 20
	# 	var tick_label_x_pos: int = tick_x_pos - tick_label_x_offset
	# 	var tick_label_y_pos: int = tick_y_pos + tick_label_y_offset
	# 	var tick_label: String = "{val}".format({"val":"%0.2f" % (self.min_val + i * tick_interval)})
	# 	self.draw_string(self.get_theme_default_font(), Vector2(tick_label_x_pos, tick_label_y_pos), tick_label, 0, -1, self.font_size, self.line_color)
	pass

func draw_x_axis() -> void:
	# Draw the vertical line of the x-axis 
	draw_line(self.top_left(), self.top_right(), self.line_color, 1.0, true)
	_draw_ticks()

func _draw() -> void:
	self.draw_x_axis()

func _process(delta: float) -> void:
	pass
