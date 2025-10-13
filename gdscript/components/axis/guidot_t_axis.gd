class_name Guidot_T_Axis
extends Guidot_X_Axis

# For the t-axis, we have a slightly different tick drawing implementation
# If we are plotting in real-time, then the plot will basically move like a sliding window
# Hence, we override the _draw_ticks function from the Guidot_X_Axis class

@onready var _sliding_window_s: float = 10.0

func _draw_ticks() -> void:

	# Clear up the ticks so we can redraw them
	self.ticks_pos.clear()

	var t_increment: float = 1.0
	# This calculation helps us re-shift the ticks to the correct multiples for the axis
	var t1: float = ceil(self.min_val/t_increment) * t_increment
	var t2: float = floor(self.max_val/t_increment) * t_increment
	self.n_steps = (t2 - t1)/t_increment

	var t_ticks_val: Array
	var tick_label: String
	var tick_label_offset = Vector2(5, 20)
	for i in range(self.n_steps + 1):
		var curr_tick_val: float = i * t_increment + t1
		
		# Find the pixel position of the tick on the x-axis
		var x_tick_pos: float = remap(curr_tick_val, self.min_val, self.max_val, self.top_left().x, self.top_right().x)
		var curr_tick_pixel_pos: Vector2 = Vector2(x_tick_pos, self.top_right().y)
		tick_label = "{val}".format({"val":"%0.2f" % (curr_tick_val)})
		self._draw_single_tick_with_label(curr_tick_pixel_pos, tick_label, self.get_theme_default_font(), self.font_size, self.line_color, tick_label_offset) 

	# First tick position
	var first_tick_pos: Vector2 = self.top_left()
	tick_label = "{val}".format({"val":"%0.2f" % (self.min_val)})
	self._draw_single_tick_with_label(first_tick_pos, tick_label, self.get_theme_default_font(), self.font_size, self.line_color, tick_label_offset) 

	# Last tick position
	var last_tick_pos: Vector2 = self.top_right()
	tick_label = "{val}".format({"val":"%0.2f" % (self.max_val)})
	self._draw_single_tick_with_label(last_tick_pos, tick_label, self.get_theme_default_font(), self.font_size, self.line_color, tick_label_offset) 
