class_name Guidot_Common
extends ColorRect

enum Origin {
	PARENT = 0,
	SELF = 1 # wrt to the child (inherited node) itself
}

enum Graph_Buffer_Mode {
	FIXED,      # If user wants to display a set window span. User will have to manually reset the time axes
	SNAPSHOT,   # Alias of fixed (thats the plan for now)
	REALTIME,  # Usually use for real-time DAQ. (aka sliding window). Will use a lot of memory since new data will be pushed back.
	MOVING_PAGE,
}

@onready var _mouse_in: bool = false
@onready var _new_position: Vector2 = Vector2()
@onready var _drag_direction: Vector2 = Vector2()
@onready var _is_dragging: bool = false
@onready var _dragging_distance: float = 0

func _on_mouse_entered() -> void:
	self._mouse_in = true
	print("Inside guidot common, mouse_in: ", self._mouse_in)

func _on_mouse_exited() -> void:
	self._mouse_in = false
	print("Inside guidot common, mouse_in: ", self._mouse_in)

func get_component_size() -> Vector2:
	return self.size

# TODO: Recheck this, since if this gets inherited, then it will use its local position
func top_left(from: Origin = Origin.SELF) -> Vector2:
	var _top_left: Vector2
	if (from == Origin.PARENT):
		_top_left = self.get_position()
	else:
		# Godot's origin system works from the top left
		# So, we know that the top left should always be (0, 0)
		_top_left = Vector2(0, 0)
	return _top_left

func top_right(from: Origin = Origin.SELF) -> Vector2:
	var _top_right: Vector2
	var x_new: float
	var y_new: float

	if (from == Origin.PARENT):
		x_new = self.top_left(Origin.PARENT).x + self.size.x
		y_new = self.top_left(Origin.PARENT).y
	else:
		x_new = self.get_component_size().x
		y_new = 0
	_top_right = Vector2(x_new, y_new)

	return _top_right
	
func bottom_left(from: Origin = Origin.SELF) -> Vector2:
	var _bot_left: Vector2
	var x_new: float
	var y_new: float
	
	if (from == Origin.PARENT):
		x_new = self.top_left(Origin.PARENT).x
		y_new = self.top_left(Origin.PARENT).y + self.size.y
	else:
		x_new = 0
		y_new = self.get_component_size().y
	_bot_left = Vector2(x_new, y_new)

	return _bot_left

func bottom_right(from: Origin = Origin.SELF) -> Vector2:
	var _bot_right: Vector2
	var x_new: float
	var y_new: float
	
	if (from == Origin.PARENT):
		x_new = self.top_left(Origin.PARENT).x + self.size.x
		y_new = self.top_left(Origin.PARENT).y + self.size.y
	else:
		x_new = self.get_component_size().x
		y_new = self.get_component_size().y
	_bot_right = Vector2(x_new, y_new)

	return _bot_right

func setup_center_anchor(x_size: int, y_size) -> void:
	self.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER)
	self.set_offset(SIDE_LEFT, -x_size)
	self.set_offset(SIDE_RIGHT, x_size)
	self.set_offset(SIDE_TOP, -y_size)
	self.set_offset(SIDE_BOTTOM, y_size)

# This is placed inside Guidot_Common since I want each child to be able to use this
func _move_display(event: InputEvent, in_moving_mode: bool) -> void:
	# Simple implementation of moving the window during runtime
	if (in_moving_mode):
		if (event is InputEventMouseButton):
			
			if (event.is_pressed() and _mouse_in):
				_dragging_distance = self.position.distance_to(self.get_viewport().get_mouse_position())
				_drag_direction = (self.get_viewport().get_mouse_position() - self.position).normalized()
				_is_dragging = true
				_new_position = self.get_viewport().get_mouse_position() - self._dragging_distance * _drag_direction
				print("Mouse pressed and inside the window")

			elif !(event.is_pressed()) and _mouse_in:
				_is_dragging = false
				print("Mouse stopped pressing")

		elif (event is InputEventMouseMotion):
			if _is_dragging:
				_new_position = self.get_viewport().get_mouse_position() - self._dragging_distance * _drag_direction

func _move_display_process() -> void:
	if _is_dragging:
		self.position = _new_position
