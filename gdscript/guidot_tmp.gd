@tool
extends PanelContainer

# TODO: Recheck this, since if this gets inherited, then it will use its local position
func top_left() -> Vector2:
	var _top_left: Vector2
	_top_left = Vector2(0, 0)
	return _top_left
	
func _ready() -> void:
	queue_redraw()
	
func _draw() -> void:
	self.draw_circle(self.top_left(), 2, Color.RED)
