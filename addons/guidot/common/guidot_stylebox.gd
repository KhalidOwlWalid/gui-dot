class_name Guidot_Stylebox
extends Object

static func instantiate_flat_stylebox(bg_color: Color, border_color: Color, content_margin: Array = [-1, -1, -1, -1],
	border_width: Array = [0, 0, 0, 0], corner_radius: Array = [0, 0, 0, 0]) -> StyleBoxFlat:
	var flat_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	flat_stylebox.bg_color = bg_color
	flat_stylebox.border_color = border_color

	flat_stylebox.content_margin_left   = content_margin[0]
	flat_stylebox.content_margin_right  = content_margin[1]
	flat_stylebox.content_margin_top    = content_margin[2]
	flat_stylebox.content_margin_bottom = content_margin[3]

	flat_stylebox.border_width_left   = border_width[0]
	flat_stylebox.border_width_right  = border_width[1]
	flat_stylebox.border_width_top    = border_width[2]
	flat_stylebox.border_width_bottom = border_width[3]

	flat_stylebox.corner_radius_top_left   	  = corner_radius[0]
	flat_stylebox.corner_radius_top_right  	  = corner_radius[1]
	flat_stylebox.corner_radius_bottom_right  = corner_radius[2]
	flat_stylebox.corner_radius_bottom_left   = corner_radius[3]

	return flat_stylebox
