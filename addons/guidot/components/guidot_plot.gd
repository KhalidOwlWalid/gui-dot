class_name Guidot_Plot
extends Guidot_Common

@onready var default_color = Color(0.17, 0.17, 0.17, 1)
# Normalized size of the plot with respect to the node frame
@onready var default_norm_size: int = 0.8
@onready var pixel_data_points: PackedVector2Array = PackedVector2Array()
@onready var _line_color: Color = Color.RED

@onready var _data_channel_pixel_pos: Dictionary = {}
@onready var _cached_data_channel: Dictionary = {}
@onready var _cached_x_range: Vector2 = Vector2(0, 0)
@onready var _cached_y_range: Vector2 = Vector2(0, 0)
# Per-channel y axis range, needed to map interpolated value back to pixel y for label drawing
var _y_axis_ranges: Dictionary = {}

var _curr_cursor_pos: Vector2 = Vector2(0, 0)
var _draw_cursor_flag: bool = false
var _mouse_inside: bool = false
var _curr_graph_mode: Graph_Buffer_Mode

signal mouse_wheel_zoom_requested(mouse_button: MouseButton)

# Zoom-by-drag state
signal zoom_requested(pixel_rect: Rect2)
var _zoom_start_pos: Vector2 = Vector2.ZERO
var _zoom_curr_pos: Vector2 = Vector2.ZERO
var _is_zooming: bool = false

signal plot_drag_requested(delta_pos: Vector2)
var _mouse_drag_start_pos: Vector2 = Vector2.ZERO
var _mouse_drag_curr_pos: Vector2 = Vector2.ZERO
var _drag_plot_mode_active: bool = false
var _is_dragging_plot: bool = false

# Axis properties
var _n_x_ticks: int
var _x_ticks_pos: PackedVector2Array
var _n_y_ticks: int
var _y_ticks_pos: PackedVector2Array
var _n_y_ax_cached: Vector2 = Vector2(1,0)

var test_popup: PopupMenu

var _parent_node: Guidot_T_Series_Graph

# This is an internal flag to check if there is any changed in mode for every process frame
# meant to queue a redraw to remove previous UI text / plot
var _curr_ui_mode_internal: Guidot_Graph.UI_Mode = self._curr_ui_mode
var _prev_ui_mode_internal: Guidot_Graph.UI_Mode = self._curr_ui_mode

var _tmp_debug: Vector2 = Vector2.ZERO
func update_debug_info() -> void:
	self.debug_signals_to_trace = {
		"drag plot mode active": self._drag_plot_mode_active,
		"mouse cursor delta": self._tmp_debug,
	}

func _ready() -> void:
	self.name = "plot_frame"
	self.clip_contents = true
	self.color = Guidot_Utils.get_color("gd_black")

	test_popup = PopupMenu.new()
	add_child(test_popup)
	test_popup.add_check_item("test")
	test_popup.add_radio_check_item("test radio check")
	test_popup.hide_on_checkable_item_selection = false
	test_popup.hide_on_item_selection = false
	test_popup.hide_on_state_item_selection = false

	self.norm_comp_size = Vector2(0.9, 0.9)

	self.set_component_tag_name("PLOT")

	# Use the guidot common mouse entered implementation
	self.mouse_entered.connect(self._on_mouse_entered)
	self.mouse_exited.connect(self._on_mouse_exited)


func _on_ui_action_request(action: Guidot_Common.UI_Action):
	
	match (action):

		Guidot_Common.UI_Action.CURSOR_MODE:
			self._draw_cursor_flag = not self._draw_cursor_flag

		Guidot_Common.UI_Action.EDIT_MODE:
			pass

func register_parent_node(parent_node: Guidot_T_Series_Graph):
	self._parent_node = parent_node
	self._parent_node.action_request.connect(self._on_ui_action_request)

func setup_plot_anchor() -> void:
	pass

func init_plot(color: Color = Guidot_Utils.get_color("gd_grey")) -> void:
	pass

func setup_plot_frame_offset(left: float, right: float, top: float, bottom: float) -> void:

	# Set the offsets of the plot frame
	self.set_offset(SIDE_LEFT, left)
	self.set_offset(SIDE_RIGHT, right)
	self.set_offset(SIDE_TOP, top)
	self.set_offset(SIDE_BOTTOM, bottom)
	
func _map_data_to_pixel(data_points: PackedVector2Array, t_axis_range: Vector2, y_axis_range: Vector2) -> void:
	pixel_data_points = PackedVector2Array()
	var t_axis_min: float = t_axis_range.x
	var t_axis_max: float = t_axis_range.y
	var y_axis_min: float = y_axis_range.x
	var y_axis_max: float = y_axis_range.y
	var comp_size: Vector2 = self.get_component_size()
	for i in data_points.size():
		var x_pixel_coords: int = remap(data_points[i].x, t_axis_min, t_axis_max, 0, comp_size.x)
		# Remember that we are drawing from the top left, so in this case y_axis_min is the bottom left, and vice versa!
		var y_pixel_coords: int = remap(data_points[i].y, y_axis_min, y_axis_max, comp_size.y, 0)
		pixel_data_points.append(Vector2(x_pixel_coords, y_pixel_coords))

func pixel_remap(data_pts: Vector2, t_axis_lim: Vector2, y_axis_lim: Vector2, comp_size: Vector2) -> Vector2:
	data_pts.x = remap(data_pts.x, t_axis_lim.x, t_axis_lim.y, 0, comp_size.x)	 
	data_pts.y = remap(data_pts.y, y_axis_lim.x, y_axis_lim.y, comp_size.y, 0)	 
	return data_pts

func _map_data_points_to_pixel_pos(gd_data: Guidot_Data, data_points: PackedVector2Array, t_axis_range: Vector2, y_axis_range: Vector2) -> PackedVector2Array:
	var t_axis_min: float = t_axis_range.x
	var t_axis_max: float = t_axis_range.y
	var y_axis_min: float = y_axis_range.x
	var y_axis_max: float = y_axis_range.y

	var mx: float = (self.get_component_size().x - 0)/(t_axis_max - t_axis_min)
	var my: float = (self.get_component_size().y - 0)/(y_axis_min - y_axis_max)
	var comp_size: Vector2 = self.get_component_size()

	# Binary search for the visible window, then expand by one point on each side so
	# the polyline segment extends just past both edges.  clip_contents=true on the
	# plot frame clips the overdraw — this makes the line look continuous even when
	# only a single segment is visible inside the window.
	var processed_data_points: PackedVector2Array
	var t_min_pos: int = maxi(0, data_points.bsearch(Vector2(t_axis_range.x, 0)) - 1)
	var t_max_pos: int = mini(data_points.size(), data_points.bsearch(Vector2(t_axis_range.y, 0)) + 1)
	processed_data_points = data_points.slice(t_min_pos, t_max_pos)
	
	# Stores the cached processed data in order to be post-processed later when used with cursor(s)
	self._cached_data_channel[gd_data] = processed_data_points
	self._cached_x_range = t_axis_range
	self._cached_y_range = y_axis_range

	# Second method of performing pixel remapping
	var pix_data_pos = PackedVector2Array()
	for i in processed_data_points.size():
		var x_pixel_coords: int = remap(processed_data_points[i].x, t_axis_min, t_axis_max, 0, comp_size.x)
		# Remember that we are drawing from the top left, so in this case y_axis_min is the bottom left, and vice versa!
		var y_pixel_coords: int = remap(processed_data_points[i].y, y_axis_min, y_axis_max, comp_size.y, 0)
		pix_data_pos.append(Vector2(x_pixel_coords, y_pixel_coords))
	return pix_data_pos

# datasets = {Guidot_Data Object: <data_points>}
func plot_multiple_data(datasets: Dictionary, y_axis_manager: RefCounted, time_range: Vector2):

	# Clears the dictionary before adding new entries for each data channel
	self._data_channel_pixel_pos.clear()
	var data_axis_map: Dictionary = y_axis_manager.get_data_to_axis_map()
	
	for gd_data in datasets.keys():
		# Update the cached data channel which will be useful for cursor(s)
		var ax_id: Guidot_Y_Axis.AxisPosition =  Guidot_Y_Axis.AxisPosition[data_axis_map[gd_data]]
		var axis_handler: RefCounted = y_axis_manager.get_axis_handler(ax_id)
		var y_axis_limit: Vector2 = axis_handler.get_axis_range()
		var data_channel_pixel_pos: PackedVector2Array = self._map_data_points_to_pixel_pos(gd_data, datasets[gd_data], time_range, y_axis_limit)
		self._data_channel_pixel_pos[gd_data] = data_channel_pixel_pos

	queue_redraw()

func update_x_ticks_properties(n_ticks: int, ticks_pos: PackedVector2Array) -> void:
	_x_ticks_pos = ticks_pos
	_n_x_ticks = n_ticks

func update_y_ticks_properties(n_ticks: int, ticks_pos: PackedVector2Array) -> void:
	_y_ticks_pos = ticks_pos
	_n_y_ticks = n_ticks

func _draw_vertical_grids(n_ticks: int, ticks_pos: PackedVector2Array, grid_color: Color) -> void:
	for i in range(ticks_pos.size()):
		draw_line(Vector2(ticks_pos[i].x, self.bottom_right().y), Vector2(ticks_pos[i].x, self.top_right().y), grid_color, -1, true)

func _draw_horizontal_grids(n_ticks: int, ticks_pos: PackedVector2Array, grid_color: Color) -> void:
	for i in range(ticks_pos.size()):
		draw_line(Vector2(self.top_left().x, ticks_pos[i].y), Vector2(self.top_right().x, ticks_pos[i].y), grid_color, -1, true)

func _draw_plots() -> void:
	for gd_data in self._data_channel_pixel_pos.keys():
		var data_points: PackedVector2Array = self._data_channel_pixel_pos[gd_data]
		# TODO (Khalid): Please do a write up of why draw_polyline is optimized better
		# Using anti-aliasing is more computationally expensive
		# However, the user should be able to have that option enabled if they simply want to
		# have their graph looks more sharp. With anti-aliasing disabled, it should still be alright
		# for realtime plots
		var use_anti_aliasing: bool = false
		# Draw circles on the graph if the number of sampling points are less than 25
		if (data_points.size() > 25):
			draw_polyline(data_points, gd_data.get_line_color(), 1.0, use_anti_aliasing)
		else:	
			for i in range(1, data_points.size()):
				draw_line(data_points[i - 1], data_points[i], gd_data.get_line_color(), 0.5, true)
				draw_circle(data_points[i], 2.0, gd_data.get_line_color(), -1, true)
	
func _draw_cursor(cursor_pos: Vector2, color: Color):
	draw_line(Vector2(cursor_pos.x, self.top_left().y), Vector2(cursor_pos.x, self.bottom_left().y), color, -1, true)

func _draw_cursor_values(cursor_pos: Vector2):
	var mouse_x: float = cursor_pos.x
	var font: Font = get_theme_default_font()

	for gd_data in self._cached_data_channel.keys():
		var pixel_pts: PackedVector2Array = self._data_channel_pixel_pos[gd_data]
		var data_pts: PackedVector2Array = self._cached_data_channel[gd_data]

		if pixel_pts.size() < 2:
			continue

		# Find the closest index to the cursor point, we are actually performing a reverse look up
		# where we use the pixel location (in this case the mouse position), and then based on this,
		# with the cached data points calculated in 'plot_multiple_data()', the index is then used to find the
		# exact value. Then, we perform linear interpolations to get the interpolated data for the position of the cursor
		var idx: int = clamp(pixel_pts.bsearch(Vector2(mouse_x, 0)) - 1, 0, pixel_pts.size() - 2)
		var px1: Vector2 = pixel_pts[idx]
		var px2: Vector2 = pixel_pts[idx + 1]

		var interp_pixel: Vector2
		var interp_data: Vector2
		if is_equal_approx(px1.x, px2.x):
			interp_pixel = px1
			interp_data = data_pts[idx]
		else:
			var t: float = inverse_lerp(px1.x, px2.x, mouse_x)
			interp_pixel = lerp(px1, px2, t)
			interp_data = lerp(data_pts[idx], data_pts[idx + 1], t)

		# Draw a dot exactly on the line at the cursor x
		draw_circle(interp_pixel, 3.0, gd_data.get_line_color())

		# Draw the interpolated data value label next to the dot
		var label: String = "%.3f, %.3f" % [interp_data.x, interp_data.y]
		var label_font_size: int = 14
		var label_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size)
		var box_pos: Vector2 = interp_pixel + Vector2(10, -label_font_size)
		var str_box: Rect2 = Rect2(box_pos, Vector2(label_size.x + 12, label_size.y + 5))
		# TODO: Leaving the box drawing here, just in case I need it
		# draw_rect(str_box, Color.WHITE, true)
		
		var str_draw_pix_pos: Vector2
		if (mouse_x < self.size.x / 2):
			str_draw_pix_pos = interp_pixel + Vector2(15, label_font_size/2)
		else:
			str_draw_pix_pos = interp_pixel - Vector2(label_size.x + 15, -label_font_size/2)

		draw_string(font, str_draw_pix_pos, label, 0, -1, label_font_size, gd_data.get_line_color())

func _draw_zoom_box() -> void:
	var rect: Rect2 = Rect2(self._zoom_start_pos, self._zoom_curr_pos - self._zoom_start_pos).abs()
	draw_rect(rect, Color(1, 1, 0, 0.08), true)
	draw_rect(rect, Color(1, 1, 0, 0.9), false, 2.0)

func _draw_current_mode_txt():
	var font: Font = get_theme_default_font()
	var label: String = Guidot_Graph.ui_mode_str[self._curr_ui_mode]
	var label_font_size: int = 30
	var label_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size)
	var str_draw_pix_pos: Vector2 = self.size / 2.0 - Vector2(label_size.x / 2.0, -label_size.y / 2.0)
	draw_string(font, str_draw_pix_pos, label, 0, -1, label_font_size, Guidot_Utils.get_color("white"))

# Handle data line drawing here
func _draw() -> void:
	self._draw_vertical_grids(_n_x_ticks, _x_ticks_pos, Guidot_Utils.get_color("gd_grey"))
	self._draw_horizontal_grids(_n_y_ticks, _y_ticks_pos, Guidot_Utils.get_color("gd_grey"))

	match (self._curr_ui_mode):
		Guidot_Graph.UI_Mode.DATA_DISPLAY:

			self._draw_plots()
			if (self._curr_graph_mode == Graph_Buffer_Mode.FIXED):
				if self._drag_plot_mode_active:
					return
				elif self._is_zooming:
					_draw_zoom_box()
				else:
					if (self._draw_cursor_flag):
						var cursor_pos: Vector2 = get_local_mouse_position()
						self._draw_cursor(cursor_pos, Guidot_Utils.get_color("red"))
						self._draw_cursor_values(cursor_pos)

		Guidot_Graph.UI_Mode.EDIT:
			self._draw_current_mode_txt()

		Guidot_Graph.UI_Mode.SELECTED:
			self._draw_current_mode_txt()
			
func _input(event: InputEvent) -> void:

	if (self._curr_graph_mode == Graph_Buffer_Mode.FIXED):
		if (not Input.is_key_pressed(KEY_CTRL) or not self._mouse_in):
			self._drag_plot_mode_active = false
		elif (Input.is_key_pressed(KEY_CTRL) and self._mouse_in):
			self._drag_plot_mode_active = true

			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				self._is_dragging_plot = true
				self._mouse_drag_curr_pos = get_local_mouse_position()
				return

			if event is InputEventMouseMotion and self._is_dragging_plot:
				var local_mouse: Vector2 = get_local_mouse_position()
				var delta: Vector2 = local_mouse - self._mouse_drag_curr_pos
				self._tmp_debug = delta
				self.plot_drag_requested.emit(delta)
				self._mouse_drag_curr_pos = local_mouse
				return
			return

		if (Input.is_key_pressed(KEY_I)):
			self._draw_cursor_flag = not self._draw_cursor_flag

		if event is InputEventMouseButton:

			self._is_dragging_plot = false

			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				self.log(LOG_INFO, ["Right button pressed"])

			if event.button_index == MOUSE_BUTTON_LEFT:
				
				if event.pressed and self._mouse_in:
					self._zoom_start_pos = get_local_mouse_position()
					self._zoom_curr_pos = _zoom_start_pos
					self._is_zooming = true
					queue_redraw()
				elif not event.pressed and _is_zooming:
					self._is_zooming = false
					var rect: Rect2 = Rect2(self._zoom_start_pos, self._zoom_curr_pos - self._zoom_start_pos).abs()
					if rect.size.x > 5 and rect.size.y > 5:
						zoom_requested.emit(rect)
					queue_redraw()

			# Ensure that only when the mouse is in the plotting area, should we emit the zoom signal
			if (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN) and self._mouse_in:
				var curr_mouse_pos: Vector2 = get_local_mouse_position()
				var plot_frame_size: Vector2 = self.size
				var mouse_ratio_pos: Vector2 = (curr_mouse_pos / plot_frame_size)
				# self.log(LOG_DEBUG, ["Current mouse pos: ", curr_mouse_pos, ", plot_frame_size: ", plot_frame_size, ", Ratio: ", y_mous])
				self.mouse_wheel_zoom_requested.emit(event.button_index, mouse_ratio_pos)

		if event is InputEventMouseMotion:

			var global_mouse_pos: Vector2 = get_global_mouse_position()

			if _is_zooming:
				_zoom_curr_pos = get_local_mouse_position()
				queue_redraw()
			elif get_global_rect().has_point(global_mouse_pos):
				if _curr_cursor_pos != get_local_mouse_position():
					_curr_cursor_pos = get_local_mouse_position()
					queue_redraw()
			
func _process(delta: float) -> void:

	# If the mode has changed, queue a redraw to ensure that any leftover texts from the previous mode are cleared
	self._curr_ui_mode_internal = self._curr_ui_mode
	if (self._curr_ui_mode_internal != self._prev_ui_mode_internal):
		queue_redraw()
	self._prev_ui_mode_internal = self._curr_ui_mode_internal
	
