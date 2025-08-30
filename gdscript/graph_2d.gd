@tool
extends ColorRect

# Property of the graph
var window_size: Vector2
var window_color: Color

@onready var default_window_size: Vector2 = Vector2(500, 300)
@onready var default_window_color: Color = Color.BLACK

@onready var color_dict: Dictionary = {
	"White": Color.WHITE,
	"Black": Color(0.07, 0.07, 0.07, 1),
	"Grey": Color(0.17, 0.17, 0.17, 1),
	"Red": Color.RED,
	"GD_Black": Color.BLACK
}

@onready var test_dict: Dictionary = {
	1: "Black"
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.clip_contents = true
	self.size = default_window_size
	self.color = default_window_color

func _draw():
	pass

# TODO: Implement this with error detection
func set_window_color(color_str: String) -> void:
	self.color = color_dict[color_str]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	set_window_color("Black")