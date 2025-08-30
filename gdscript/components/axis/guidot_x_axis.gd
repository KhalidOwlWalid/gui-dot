class_name Guidot_X_Axis
extends Guidot_Axis

func draw_x_axis() -> void:
    pass
    # Draw the vertical line of the x-axis 
    # draw_line()

func _draw() -> void:
    print(self.top_left())

func _process(delta: float) -> void:
    print(self.top_left())