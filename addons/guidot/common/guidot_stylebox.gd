class_name Guidot_Stylebox
extends Object

static func instantiate_flat_stylebox(bg_color: Color, border_color: Color, border_width: Array = [0, 0, 0, 0]) -> StyleBoxFlat:
	var flat_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	flat_stylebox.bg_color = bg_color
	flat_stylebox.border_color = border_color
	flat_stylebox.border_width_left   = border_width[0]
	flat_stylebox.border_width_right  = border_width[1]
	flat_stylebox.border_width_top    = border_width[2]
	flat_stylebox.border_width_bottom = border_width[3]
	return flat_stylebox
