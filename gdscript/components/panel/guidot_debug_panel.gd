@tool
class_name Guidot_Debug_Panel
extends Guidot_Panel

@onready var _debugging_text_window: ColorRect = ColorRect.new()

func _ready() -> void:
	self.name = "Guidot_Panel"
	self.visible = false
	self.size = _panel_size
	self.position = self._init_pos

	_guidot_panel_stylebox.bg_color = color_dict["gd_black"]
	set_margin_size(margin_val)
	add_theme_stylebox_override("panel", _guidot_panel_stylebox)

	self._debugging_text_window.color = color_dict["gd_dim_blue"]
	add_child(self._debugging_text_window)
