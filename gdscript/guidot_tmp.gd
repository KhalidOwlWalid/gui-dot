@tool
extends ColorRect

var axis_height: int

func _ready() -> void:
	self.color = Color.BLACK
	# self.offset_left = 50
	self.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER)
	self.axis_height = 10
	self.offset_left = 10
	self.offset_right = 20
	self.offset_top = 10
	self.offset_bottom = 10 + self.axis_height
