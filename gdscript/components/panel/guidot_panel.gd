@tool
class_name Guidot_Panel
extends PanelContainer

@onready var _panel_size: Vector2 = Vector2(100, 100)
@onready var _init_pos: Vector2 = Vector2(100, 100)

@onready var _last_pos: Vector2 = Vector2()
@onready var color_dict: Dictionary = Guidot_Utils.color_dict

@onready var _guidot_panel_stylebox: StyleBoxFlat = StyleBoxFlat.new()
@onready var margin_val: int = 3

func _ready() -> void:
	self.name = "Guidot_Panel"
	self.visible = true
	self.size = _panel_size
	self.position = self._init_pos

	_guidot_panel_stylebox.bg_color = color_dict["gd_black"]
	set_margin_size(margin_val)
	add_theme_stylebox_override("panel", _guidot_panel_stylebox)

func set_margin_size(val: int) -> void:
	_guidot_panel_stylebox.content_margin_left = val
	_guidot_panel_stylebox.content_margin_right = val
	_guidot_panel_stylebox.content_margin_bottom = val
	_guidot_panel_stylebox.content_margin_top = val

func show_panel() -> void:
	self.visible = true

func hide_panel() -> void:
	self._last_pos = self.position
	self.visible = false

func _process(delta: float) -> void:
	pass
