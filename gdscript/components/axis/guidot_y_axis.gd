class_name Guidot_Y_Axis
extends Guidot_Axis

func draw_y_axis() -> void:
    # Draw the vertical line of the x-axis 
    draw_line(self.top_left(), self.top_right(), Color.WHITE, 1.0, true)
    
    var tick_y_pos: int = self.top_left().y
    var axis_frame_size: Vector2 = self.get_component_size()
    var increments: int  = axis_frame_size.x / n_steps
    for i in range(n_steps):
        var tick_x_pos: int = self.top_left().x + i * increments
        draw_line(Vector2(tick_x_pos, tick_y_pos), Vector2(tick_x_pos, tick_y_pos + self.tick_length), Color.WHITE, 1.0, true)

func _draw() -> void:
    self.draw_y_axis()

func _process(delta: float) -> void:
    pass
