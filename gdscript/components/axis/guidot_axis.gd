class_name Guidot_Axis
extends Guidot_Common

@onready var min: float = 0
@onready var max: float = 1
@onready var n_steps: int = 10
@onready var axis_name: String = "X-Axis"

@onready var axis: Dictionary = {
	"x": 0,
	"y": 1
}

func setup_axis_node(name: String, color: Color, left: int, right: int, top: int, bottom: int) -> void:
	self.name = name

	# Prevents us from drawing beyond the axis frame
	self.clip_contents = true
	self.color = color

	self.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER)
	self.set_offset(SIDE_LEFT, left)
	self.set_offset(SIDE_RIGHT, right)
	self.set_offset(SIDE_TOP, top)
	self.set_offset(SIDE_BOTTOM, bottom)

func setup_axis_limit(min: float, max: float) -> void:
	self.min = min
	self.max = max

func draw_axis():
	pass

func _ready() -> void:
	pass

func _draw() -> void:
	pass