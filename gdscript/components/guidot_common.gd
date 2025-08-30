class_name Guidot_Common
extends ColorRect

func top_left() -> Vector2:
    return self.get_position()

func top_right() -> Vector2:
    var x_new: float = self.top_left().x + self.size.x
    var _top_right: Vector2 = Vector2(x_new, self.top_left().y)
    return _top_right

func bottom_left() -> Vector2:
    var y_new: float = self.top_left().y + self.size.y
    var _bot_left: Vector2 = Vector2(self.top_left().x, y_new)
    return _bot_left

func bottom_right() -> Vector2:
    var x_new: float = self.top_left().x + self.size.x
    var y_new: float = self.top_left().y + self.size.y
    var _bot_right: Vector2 = Vector2(x_new, y_new)
    return _bot_right

func get_component_size() -> Vector2:
    return self.size
    
