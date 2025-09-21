class_name Guidot_Graph
extends PanelContainer

const Guidot_T_Series_Graph := preload("res://gdscript/time_series_graph.gd")

@onready var guidot_graph = Guidot_T_Series_Graph.new()
@onready var _guidot_stylebox: StyleBoxFlat = StyleBoxFlat.new()
@onready var margin_val: int = 1

@onready var color_dict: Dictionary = Guidot_Utils.color_dict

func _ready() -> void:
	self.name = "Guidot_Graph"
	self.size = Vector2(620, 360)
	self.add_child(guidot_graph)

	_guidot_stylebox.bg_color = color_dict["gd_black"]
	_guidot_stylebox.content_margin_left = margin_val
	_guidot_stylebox.content_margin_right = margin_val
	_guidot_stylebox.content_margin_bottom = margin_val
	_guidot_stylebox.content_margin_top = margin_val
	add_theme_stylebox_override("panel", _guidot_stylebox)

func set_stylebox_color(color: Color) -> void:
	_guidot_stylebox.bg_color = color
