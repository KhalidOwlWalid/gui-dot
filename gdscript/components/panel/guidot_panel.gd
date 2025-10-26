# @tool
class_name Guidot_Panel
extends PanelContainer

# const Guidot_Utils = preload("/home/khalidowlwalid/Documents/KhalidOWlWalid-Github-Projects/Godot/gui-dot/gdscript/utils/guidot_utils.gd")

@onready var _panel_size: Vector2 = Vector2(100, 100)
@onready var _init_pos: Vector2 = Vector2(100, 100)

@onready var _last_pos: Vector2 = Vector2()
var color_dict: Dictionary

@onready var _guidot_panel_stylebox: StyleBoxFlat = StyleBoxFlat.new()
@onready var margin_val: int = 3
@onready var _font_size: int = 10

@onready var _component_tag = "PANEL"

const LOG_DEBUG = Guidot_Log.Log_Level.DEBUG
const LOG_WARNING = Guidot_Log.Log_Level.WARNING
const LOG_INFO = Guidot_Log.Log_Level.INFO
const LOG_ERROR = Guidot_Log.Log_Level.ERROR

func _ready() -> void:
	self.name = "Guidot_Panel"
	self.visible = true
	self.size = _panel_size
	self.position = self._init_pos

	_guidot_panel_stylebox.bg_color = Guidot_Utils.get_color("gd_black")
	set_margin_size(margin_val)
	add_theme_stylebox_override("panel", _guidot_panel_stylebox)

func set_margin_size(val: int) -> void:
	_guidot_panel_stylebox.content_margin_left = val
	_guidot_panel_stylebox.content_margin_right = val
	_guidot_panel_stylebox.content_margin_bottom = val
	_guidot_panel_stylebox.content_margin_top = val

func set_panel_size(new_size: Vector2) -> void:
	self.size = new_size

func set_background_color(new_color: Color) -> void:
	self._guidot_panel_stylebox.bg_color = new_color
	# var l_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	# l_stylebox.bg_color = new_color

func show_panel() -> void:
	self.visible = true

func hide_panel() -> void:
	self._last_pos = self.position
	self.visible = false

func _process(delta: float) -> void:
	pass

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, self._component_tag, msg)
