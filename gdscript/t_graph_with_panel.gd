# @tool
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


@onready var _last_mouse_position: Vector2 = Vector2()
@onready var _mouse_in: bool = false

@onready var _new_position: Vector2 = Vector2()
@onready var _drag_direction: Vector2 = Vector2()
@onready var _is_dragging: bool = false
@onready var _dragging_distance: float = 0
@onready var _last_position: Vector2 = Vector2()
var _drag_offset: Vector2

@onready var _is_resizing: bool = false

@onready var _is_in_focus: bool = false
@onready var _is_holding_left_click: bool = false

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
	POSSIBLE_RESIZING,
	RESIZE,
	POSSIBLE_MOVING,
	MOVE,
}

@onready var edit_mode_str: Dictionary = {
	Edit_Mode.NONE: "NONE",
	Edit_Mode.POSSIBLE_RESIZING: "POSSIBLE_RESIZING",
	Edit_Mode.RESIZE: "RESIZE",
	Edit_Mode.POSSIBLE_MOVING: "POSSIBLE_MOVING",
	Edit_Mode.MOVE: "MOVE",
}

@onready var _current_ui_mode: UI_Mode = UI_Mode.DATA_DISPLAY 

@onready var _curr_edit_mode: Edit_Mode = Edit_Mode.NONE
@onready var _last_edit_mode: Edit_Mode = self._curr_edit_mode

@onready var _active_resize_corner: Resize_Corner = Resize_Corner.NONE
@onready var _last_active_resize_corner: Resize_Corner = Resize_Corner.NONE

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

func _register_hotkeys() -> void:
	Guidot_Utils.add_action_with_keycode("escape", KEY_ESCAPE) 

func _ready() -> void:
	self.name = "Guidot_Graph"
	var factor: float = 1
	self.size = Vector2(620*factor, 360*factor)
	self.add_child(guidot_graph)

	_guidot_stylebox.bg_color = Guidot_Utils.get_color("gd_black")
	set_margin_size(margin_val)
	add_theme_stylebox_override("panel", _guidot_stylebox)
	self._last_position = self.position
	self._last_mouse_position = self.get_viewport().get_mouse_position()

	# Signals connection
	guidot_graph.parent_focus_requested.connect(_on_parent_focused)
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)

	# Hotkeys
	self._register_hotkeys()

func _on_mouse_entered() -> void:
	self._mouse_in = true

func _on_mouse_exited() -> void:
	self._mouse_in = false

func _on_parent_focused() -> void:
	self._is_in_focus = true
	self.log(LOG_INFO, ["On parent focused", self._is_in_focus])

func set_stylebox_color(color: Color) -> void:
	_guidot_stylebox.bg_color = color

func set_margin_size(val: int) -> void:
	_guidot_stylebox.content_margin_left = val
	_guidot_stylebox.content_margin_right = val
	_guidot_stylebox.content_margin_bottom = val
	_guidot_stylebox.content_margin_top = val

func set_panel_size(new_size: Vector2) -> void:
	pass

func _is_point_near(from: Vector2, target: Vector2, margin: int) -> bool:
	return from.distance_to(target) <= margin

func _get_hovered_resize_corner(hover_margin: int) -> Resize_Corner:
	var curr_local_mouse_pos: Vector2 = self.get_local_mouse_position()
	var curr_resize_corner: Resize_Corner

	if (self._is_holding_left_click and self._curr_edit_mode == Edit_Mode.RESIZE):
		# If we are currently resizing that corner, then let the user finish the resizing process first
		# before we allow them to perform it for other corners
		self._last_active_resize_corner = self._active_resize_corner
		curr_resize_corner = _last_active_resize_corner
	else:
		if (self._is_point_near(curr_local_mouse_pos, self.top_left(), hover_margin)):
			curr_resize_corner =  Resize_Corner.TOP_LEFT
		elif (self._is_point_near(curr_local_mouse_pos, self.top_right(), hover_margin)):
			curr_resize_corner =  Resize_Corner.TOP_RIGHT
		elif (self._is_point_near(curr_local_mouse_pos, self.bottom_left(), hover_margin)):
			curr_resize_corner =  Resize_Corner.BOTTOM_LEFT
		elif (self._is_point_near(curr_local_mouse_pos, self.bottom_right(), hover_margin)):
			curr_resize_corner =  Resize_Corner.BOTTOM_RIGHT
		else:
			curr_resize_corner = Resize_Corner.NONE
	# Return this only if we cant detect the mouse hovering on top of any of those points
	return curr_resize_corner

func _input(event: InputEvent) -> void:

	if (Input.is_action_just_pressed("escape")):
		self.log(LOG_INFO, ["Escape key just pressed"])
		self._is_in_focus = false
		guidot_graph.set_focus_flag(self._is_in_focus)

	if (self._curr_edit_mode == UI_Mode.DATA_DISPLAY):
		pass

	if (self._current_ui_mode == UI_Mode.SELECTED):	
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:	
				# Allow the user to be able to start resizing the graph
				if event.is_pressed() and self._active_resize_corner != Resize_Corner.NONE and self._curr_edit_mode == Edit_Mode.POSSIBLE_RESIZING:
					self.log(LOG_DEBUG, ["Graph panel ready to be resize"])
					self._last_edit_mode = self._curr_edit_mode
					self._is_holding_left_click = true
				# Go back to possible resizing if the user releases the left mouse
				elif not event.is_pressed() \
					and (self._last_edit_mode == Edit_Mode.POSSIBLE_RESIZING and self._curr_edit_mode == Edit_Mode.RESIZE):
					self._last_edit_mode = self._curr_edit_mode
					self._is_holding_left_click = false
					self.log(LOG_DEBUG, ["Left click resizing released"])
				elif event.is_pressed():
					# Start dragging - calculate the offset from mouse to panel position
					_is_dragging = true
					self._curr_edit_mode == Edit_Mode.MOVE
					# This allows the user to grab the panel anywhere within the panel and drag it
					# anywhere
					_drag_offset = get_global_mouse_position() - self.global_position
					self._last_position = self.position
				else:
					_is_dragging = false

				if event.is_pressed():
					self.log(LOG_DEBUG, ["I am pressing my left button"])
					self._is_holding_left_click = true
				else:
					self.log(LOG_DEBUG, ["I am releasing my left button"])
					self._is_holding_left_click = false

		if event is InputEventMouseMotion:

			var curr_mouse_pos_global: Vector2 = get_global_mouse_position()
			var curr_mouse_pos_local: Vector2 = get_local_mouse_position()
			# var mouse_delta = self._last_mouse_position - curr_mouse_pos_global
			var new_size: Vector2
			var new_pos: Vector2
			var mouse_offset: Vector2
			# Only allow the user to drag when the mouse is inside the panel
			if self._curr_edit_mode == Edit_Mode.RESIZE and self._is_holding_left_click:
				self._last_position = self.global_position
	
				match (self._active_resize_corner):
					Resize_Corner.TOP_LEFT:
						new_pos = self._last_position + curr_mouse_pos_local
						# new_size = self.size - (new_pos - self._last_position)
						new_size = self.size - curr_mouse_pos_local
					Resize_Corner.TOP_RIGHT:
						mouse_offset = Vector2(curr_mouse_pos_local.x - self.size.x, curr_mouse_pos_local.y)
						new_pos = Vector2(self._last_position.x, self._last_position.y + mouse_offset.y)
						
						# This helps handle the negative offset when the user is trying to scale down the graph with the top right corner
						if (mouse_offset.y < 0):
							new_size = Vector2(self.size.x + mouse_offset.x, self.size.y + abs(mouse_offset.y))
						else:
							new_size = Vector2(self.size.x + mouse_offset.x, self.size.y - abs(mouse_offset.y))

					Resize_Corner.BOTTOM_LEFT:
						mouse_offset = Vector2(curr_mouse_pos_local.x, curr_mouse_pos_local.y - self.size.y)
						new_pos = Vector2(self._last_position.x + mouse_offset.x, self._last_position.y)

						if (mouse_offset.x < 0):
							new_size.x = self.size.x + abs(mouse_offset.x)
						else:
							new_size.x = self.size.x - abs(mouse_offset.x)

						if (mouse_offset.y < 0):
							new_size.y = self.size.y - abs(mouse_offset.y)
						else:
							new_size.y = self.size.y + abs(mouse_offset.y)

					Resize_Corner.BOTTOM_RIGHT:
						mouse_offset = curr_mouse_pos_local - self.size
						new_size = self.size + mouse_offset
						new_pos = self.global_position
					Resize_Corner.NONE:
						new_size = self.size
						new_pos = self.global_position

				self.log(LOG_DEBUG, ["Corner: ", self._active_resize_corner])
				self.log(LOG_DEBUG, ["Current size: ", self.size, "| New size: ", new_size, "| Current pos: ", self.global_position, "| New pos: ", new_pos, " | Mouse delta: ", curr_mouse_pos_global])
				self.global_position = new_pos
				self.size = new_size
				self._last_mouse_position = curr_mouse_pos_global

			if self._is_dragging and self._mouse_in:
				self.set_default_cursor_shape(Control.CURSOR_DRAG)
		
				# Move panel while maintaining the original mouse offset
				new_pos = curr_mouse_pos_global - _drag_offset
				self.global_position = new_pos
				self.log(Guidot_Log.Log_Level.DEBUG, ["Dragging panel from", self._last_position, "to", self.global_position])
				self._last_mouse_position = curr_mouse_pos_global
				self._last_position = self.position
			elif not self._is_dragging:
				self.set_default_cursor_shape(Control.CURSOR_ARROW)


func _draw_resizing_hover_circle(circle_size: int) -> void:
	var circle_pos_to_draw: Vector2 = Vector2()
	match (self._active_resize_corner):
		Resize_Corner.NONE:
			pass

		Resize_Corner.TOP_LEFT:
			circle_pos_to_draw = self.top_left()

		Resize_Corner.TOP_RIGHT:
			circle_pos_to_draw = self.top_right()

		Resize_Corner.BOTTOM_LEFT:
			circle_pos_to_draw = self.bottom_left()

		Resize_Corner.BOTTOM_RIGHT:
			circle_pos_to_draw = self.bottom_right()

	if (self._active_resize_corner != Resize_Corner.NONE):
		self.draw_circle(circle_pos_to_draw, circle_size, Color.RED, false)
	else:
		pass


func _draw() -> void:
	var resizing_circle_size: int  = 4
	var resizing_hover_circle_size: int = 10
	if (self._current_ui_mode == UI_Mode.SELECTED):
		
		# Draw 4 circle points for user reference where to resize
		self.draw_circle(self.top_left(), resizing_circle_size, Color.RED)
		self.draw_circle(self.top_right(), resizing_circle_size, Color.RED)
		self.draw_circle(self.bottom_left(), resizing_circle_size, Color.RED)
		self.draw_circle(self.bottom_right(), resizing_circle_size, Color.RED)

		# Show active corner the user is hovering above to enable resizing
		self._draw_resizing_hover_circle(resizing_hover_circle_size)
	
func _process(delta: float) -> void:

	if (self._is_in_focus):
		self.set_stylebox_color(Guidot_Utils.get_color("red"))
	else:
		# TODO (Khalid): This needs to be able to change back to previous color, not hardcoded color
		self.set_stylebox_color(Guidot_Utils.get_color("gd_black"))
	
	if (self._is_in_focus):
		self._current_ui_mode = UI_Mode.SELECTED
		self._active_resize_corner = self._get_hovered_resize_corner(10)

		# Possible resizing when user is hovering above the resizing corners but have yet click the left button
		if (self._active_resize_corner != Resize_Corner.NONE and not self._is_holding_left_click):
			self._last_edit_mode = self._curr_edit_mode
			self._curr_edit_mode = Edit_Mode.POSSIBLE_RESIZING
		# User is currently holding the left click to resize the graph display
		elif (self._active_resize_corner != Resize_Corner.NONE and self._is_holding_left_click):
			self._last_edit_mode = self._curr_edit_mode
			self._curr_edit_mode = Edit_Mode.RESIZE
		elif (self._last_edit_mode == Edit_Mode.RESIZE and self._is_holding_left_click):
			self._curr_edit_mode = Edit_Mode.RESIZE
		else:
			self._last_edit_mode = self._curr_edit_mode
			self._curr_edit_mode = Edit_Mode.NONE

		self.queue_redraw()

		match (self._curr_edit_mode):
			Edit_Mode.POSSIBLE_RESIZING:
				self.set_default_cursor_shape(Control.CURSOR_HSIZE)

			Edit_Mode.RESIZE:
				self.set_default_cursor_shape(Control.CURSOR_HSIZE)

			Edit_Mode.MOVE:
				self.set_default_cursor_shape(Control.CURSOR_DRAG)
			
			Edit_Mode.NONE:
				self.set_default_cursor_shape(Control.CURSOR_ARROW)
	else:
		self._current_ui_mode = UI_Mode.DATA_DISPLAY

	if (self._is_holding_left_click):
		self.log(LOG_DEBUG, ["I am holding my left click still"])
		pass
	else:
		self.log(LOG_DEBUG, ["I have released my left click"])
		pass

	self.log(LOG_DEBUG, ["Mouse pos local: ", self.get_local_mouse_position()])


func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, "MASTER_PANEL", msg)
