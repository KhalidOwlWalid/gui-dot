class_name Guidot_Axis
extends Guidot_Common

@onready var min: float = 0
@onready var max: float = 1
@onready var n_steps: int = 10
@onready var axis_name: String = "X-Axis"
@onready var tick_length: int = 5

# Axis component properties
var last_color: Color
var left_offset: float
var right_offset: float
var top_offset: float
var bottom_offset: float

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

	# Setup signal connection if user hovers above the axis
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)

func setup_axis_limit(min: float, max: float) -> void:
	self.min = min
	self.max = max

func set_min(min: float) -> void:
	self.min = min

func set_max(max: float) -> void:
	self.max = max

func draw_axis():
	pass

func _ready() -> void:
	# Override this if necessary
	self.color = Guidot_Utils.color_dict["black"]
	self.last_color = self.color

func _draw() -> void:
	pass

func _on_mouse_entered() -> void:
	# Save the current color so we can revert back
	self.last_color = self.color
	self.color = Guidot_Utils.color_dict["dim_black"]
	print("Mouse entered")
	queue_redraw()

func _on_mouse_exited() -> void:
	self.color = self.last_color
	print("Mouse exited")
	queue_redraw()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		print("Mouse left was pressed")
