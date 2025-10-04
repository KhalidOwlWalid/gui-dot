class_name Guidot_Graph
extends PanelContainer

const Guidot_T_Series_Graph := preload("res://gdscript/time_series_graph.gd")

const LOG_DEBUG = Guidot_Log.Log_Level.DEBUG
const LOG_WARNING = Guidot_Log.Log_Level.WARNING
const LOG_INFO = Guidot_Log.Log_Level.INFO
const LOG_ERROR = Guidot_Log.Log_Level.ERROR

@onready var guidot_graph = Guidot_T_Series_Graph.new()
@onready var _guidot_stylebox: StyleBoxFlat = StyleBoxFlat.new()
@onready var margin_val: int = 1

@onready var color_dict: Dictionary = Guidot_Utils.color_dict

@onready var _last_mouse_position: Vector2 = Vector2()
@onready var _mouse_in: bool = false

@onready var _new_position: Vector2 = Vector2()
@onready var _drag_direction: Vector2 = Vector2()
@onready var _is_dragging: bool = false
@onready var _dragging_distance: float = 0
@onready var _last_position: Vector2 = Vector2()

@onready var _is_resizing: bool = false

@onready var _is_in_focus: bool = false

enum UI_Mode {
	SELECTED,
	DATA_DISPLAY,
	PREVIEW,
	SETTINGS,
}

enum Resize_Corner {
	NONE,
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT,
}

enum Edit_Mode {
	NONE,
	RESIZE,
	MOVE,
}

@onready var _curr_edit_mode: Edit_Mode = Edit_Mode.NONE

func get_component_size() -> Vector2:
	return self.size

func top_left() -> Vector2:
	# Godot's origin system works from the top left
	# So, we know that the top left should always be (0, 0)
	var _top_left: Vector2 = Vector2(0, 0)
	return _top_left

func top_right() -> Vector2:
	var _top_right: Vector2
	var x_new: float
	var y_new: float
	x_new = self.get_component_size().x
	y_new = 0
	_top_right = Vector2(x_new, y_new)
	return _top_right
	
func bottom_left() -> Vector2:
	var _bot_left: Vector2
	var x_new: float
	var y_new: float
	x_new = 0
	y_new = self.get_component_size().y
	_bot_left = Vector2(x_new, y_new)
	return _bot_left

func bottom_right() -> Vector2:
	var _bot_right: Vector2
	var x_new: float
	var y_new: float
	x_new = self.get_component_size().x
	y_new = self.get_component_size().y
	_bot_right = Vector2(x_new, y_new)
	return _bot_right

@onready var _current_ui_mode: UI_Mode = UI_Mode.DATA_DISPLAY 

func _ready() -> void:
	self.name = "Guidot_Graph"
	var factor: float = 1
	self.size = Vector2(620*factor, 360*factor)
	self.add_child(guidot_graph)

	_guidot_stylebox.bg_color = color_dict["gd_black"]
	set_margin_size(margin_val)
	add_theme_stylebox_override("panel", _guidot_stylebox)
	self._last_position = self.position
	self._last_mouse_position = self.get_viewport().get_mouse_position()

	# Signals connection
	guidot_graph.parent_focus_requested.connect(_on_parent_focused)
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	self._mouse_in = true

func _on_mouse_exited() -> void:
	self._mouse_in = false

func _on_parent_focused() -> void:
	self._is_in_focus = !self._is_in_focus
	self.log(LOG_INFO, ["On parent focused", self._is_in_focus])

	if (self._is_in_focus):
		self.set_stylebox_color(color_dict["red"])
	else:
		# TODO (Khalid): This needs to be able to change back to previous color, not hardcoded color
		self.set_stylebox_color(color_dict["gd_black"])

func set_stylebox_color(color: Color) -> void:
	_guidot_stylebox.bg_color = color

func set_margin_size(val: int) -> void:
	_guidot_stylebox.content_margin_left = val
	_guidot_stylebox.content_margin_right = val
	_guidot_stylebox.content_margin_bottom = val
	_guidot_stylebox.content_margin_top = val

func set_panel_size(new_size: Vector2) -> void:
	pass

var _drag_offset: Vector2

func _is_point_near(from: Vector2, target: Vector2, margin: int) -> bool:
	return from.distance_to(target) <= margin

func _get_hovered_resize_corner() -> Resize_Corner:
	var curr_local_mouse_pos: Vector2 = self.get_local_mouse_position()
	var hover_margin: int = 10

	if (self._is_point_near(curr_local_mouse_pos, self.top_left(), hover_margin)):
		return Resize_Corner.TOP_LEFT
	elif (self._is_point_near(curr_local_mouse_pos, self.top_right(), hover_margin)):
		return Resize_Corner.TOP_RIGHT
	elif (self._is_point_near(curr_local_mouse_pos, self.bottom_left(), hover_margin)):
		return Resize_Corner.BOTTOM_LEFT
	elif (self._is_point_near(curr_local_mouse_pos, self.bottom_right(), hover_margin)):
		return Resize_Corner.BOTTOM_RIGHT
	else:
		pass
	# Return this only if we cant detect the mouse hovering on top of any of those points
	return Resize_Corner.NONE

func _is_trying_to_resize(corner_pos: Vector2, margin_size: int) -> void:
	var within_horizontal_boundaries: bool = self.get_local_mouse_position().x < corner_pos.x + margin_size \
		and self.get_local_mouse_position().x > corner_pos.x - margin_size

	var within_vertical_boundaries: bool = self.get_local_mouse_position().y < corner_pos.y + margin_size \
		and self.get_local_mouse_position().y > corner_pos.y - margin_size

	if (within_horizontal_boundaries and within_vertical_boundaries):
		self._is_resizing = true
	else:
		self._is_resizing = false

	print("is resizing: ", self._is_resizing)

func _input(event: InputEvent) -> void:

	if (self._current_ui_mode == UI_Mode.SELECTED):	
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:	

				if event.is_pressed() and self._current_ui_mode == UI_Mode.SELECTED:
					# Start dragging - calculate the offset from mouse to panel position
					_is_dragging = true
					# This allows the user to grab the panel anywhere within the panel and drag it
					# anywhere
					_drag_offset = get_global_mouse_position() - self.global_position
					self._last_position = self.position
				else:
					_is_dragging = false

		if event is InputEventMouseMotion:

			# Only allow the user to drag when the mouse is inside the panel
			if self._is_dragging and self._mouse_in:
				self.set_default_cursor_shape(Control.CURSOR_DRAG)
				var curr_mouse_pos: Vector2 = get_global_mouse_position()
		
				# Move panel while maintaining the original mouse offset
				var new_pos = curr_mouse_pos - _drag_offset
				self.global_position = new_pos
				self.log(Guidot_Log.Log_Level.DEBUG, ["Dragging panel from", self._last_position, "to", self.global_position])
				self._last_mouse_position = curr_mouse_pos
				self._last_position = self.position
			elif not self._is_dragging:
				self.set_default_cursor_shape(Control.CURSOR_ARROW)

func _draw() -> void:
	if (self._current_ui_mode == UI_Mode.SELECTED):
		var resizing_circle_size: int  = 4
		self.draw_circle(self.top_left(), resizing_circle_size, Color.RED)
		self.draw_circle(self.top_right(), resizing_circle_size, Color.RED)
		self.draw_circle(self.bottom_left(), resizing_circle_size, Color.RED)
		self.draw_circle(self.bottom_right(), resizing_circle_size, Color.RED)

		var resize_corner: Resize_Corner = self._get_hovered_resize_corner()

		match (resize_corner):
			Resize_Corner.NONE:
				self.set_default_cursor_shape(Control.CURSOR_ARROW)

			Resize_Corner.TOP_LEFT:
				self.draw_circle(self.top_left(), 10, Color.RED, false)
				self._curr_edit_mode = Edit_Mode.RESIZE

			Resize_Corner.TOP_RIGHT:
				self.draw_circle(self.top_right(), 10, Color.RED, false)
				self._curr_edit_mode = Edit_Mode.RESIZE

			Resize_Corner.TOP_LEFT:
				pass
	
func _process(delta: float) -> void:
	
	if (self._is_in_focus):
		self._current_ui_mode = UI_Mode.SELECTED
		self.queue_redraw()

		self._is_trying_to_resize(self.top_left(), 10)
		# self._is_trying_to_resize(self.top_right(), 10)

		match (self._curr_edit_mode):
			Edit_Mode.RESIZE:
				self.set_default_cursor_shape(Control.CURSOR_HSIZE)
			
			Edit_Mode.NONE:
				self.set_default_cursor_shape(Control.CURSOR_ARROW)


func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, "MASTER_PANEL", msg)
