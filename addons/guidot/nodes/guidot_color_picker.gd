@tool
class_name Guidot_Color_Picker
extends Guidot_Movable_Panel

@onready var _color_picker: ColorPicker = ColorPicker.new()
@onready var _color_picker_callback: Callable

func _ready() -> void:
	super._ready()
	self.name = "Guidot_Color_Picker"
	self.set_title_name(self.name)
	self.global_position = DisplayServer.screen_get_size()/2 - Vector2i(self.size/2)

	# By default, hide the color picker
	self.visible = false

	self.add_child_into_panel_space(self._color_picker)

	self.add_to_group(Guidot_Common._color_picker_name)

func set_color(color: Color) -> void:
	self._color_picker.color = color

func node() -> ColorPicker:
	return self._color_picker

func get_callback() -> Callable:
	return self._color_picker_callback

func set_callback(cb: Callable) -> void:
	self._color_picker_callback = cb
