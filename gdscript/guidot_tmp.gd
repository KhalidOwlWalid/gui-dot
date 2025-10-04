# @tool
# extends PanelContainer

# # TODO: Recheck this, since if this gets inherited, then it will use its local position
# func top_left() -> Vector2:
# 	var _top_left: Vector2
# 	_top_left = Vector2(0, 0)
# 	return _top_left


# 	self.mouse_entered.connect(self._on_mouse_entered)

# func _on_mouse_entered() -> void:
# 	pass
	
# func _ready() -> void:
# 	Input.set_default_cursor_shape(Input.CURSOR_BUSY)
# 	queue_redraw()
	
# func _draw() -> void:
# 	self.draw_circle(self.top_left(), 2, Color.RED)

@tool
extends PanelContainer

var test = load("res://tmp/drag.png")

# TODO: Recheck this, since if this gets inherited, then it will use its local position
func top_left() -> Vector2:
	return Vector2(0, 0)

func _ready() -> void:
	# Connect mouse signals
	self.mouse_entered.connect(self._on_mouse_entered)
	self.mouse_exited.connect(self._on_mouse_exited)
	queue_redraw()

func _on_mouse_entered() -> void:
	# Set cursor when mouse enters the panel
	self.set_default_cursor_shape(Control.CURSOR_DRAG)

func _on_mouse_exited() -> void:
	# Reset cursor when mouse leaves the panel
	self.set_default_cursor_shape(Control.CURSOR_ARROW)

func _draw() -> void:
	self.draw_circle(self.top_left(), 2, Color.RED)
