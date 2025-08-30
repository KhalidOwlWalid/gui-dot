class_name Guidot_Common
extends ColorRect

enum Origin {
	PARENT = 0,
	SELF = 1 # wrt to the child (inherited node) itself
}

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

func bottom_right(from: Origin = Origin.PARENT) -> Vector2:
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
