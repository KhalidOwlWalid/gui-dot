class_name Guidot_Panel2
extends PanelContainer

######################################## NOTE ##############################################################
# Please call the add_child_to_container function, if you wish to place your nodes inside of the container #
# Failure to do so, may result in the container being drawn on top of your node which may cause the node   #
# to not function as intended																			   #
############################################################################################################

@onready var _panel_size: Vector2 = Vector2(100, 100)
@onready var _init_pos: Vector2 = Vector2(100, 100)

@onready var _last_pos: Vector2 = Vector2()
var color_dict: Dictionary

@onready var _inner_container: PanelContainer = PanelContainer.new()

@onready var _outline_stylebox: StyleBoxFlat = StyleBoxFlat.new()
@onready var _inner_container_stylebox: StyleBoxFlat = StyleBoxFlat.new()
@onready var margin_val: int = 3
@onready var _font_size: int = 10

@onready var _component_tag = "PANEL"

const LOG_DEBUG = Guidot_Log.Log_Level.DEBUG
const LOG_WARNING = Guidot_Log.Log_Level.WARNING
const LOG_INFO = Guidot_Log.Log_Level.INFO
const LOG_ERROR = Guidot_Log.Log_Level.ERROR

func _ready() -> void:
	self.name = "Guidot_Panel"
	self.visible = false
	self.size = _panel_size
	self.position = self._init_pos

	self.add_child(self._inner_container)

	_outline_stylebox.bg_color = Guidot_Utils.get_color("gd_black")
	_inner_container_stylebox.bg_color = Guidot_Utils.get_color("gd_grey")
	set_margin_size(margin_val)
	add_theme_stylebox_override("panel", _outline_stylebox)
	self._inner_container.add_theme_stylebox_override("panel", _inner_container_stylebox)

func set_margin_size(val: int) -> void:
	_outline_stylebox.content_margin_left = val
	_outline_stylebox.content_margin_right = val
	_outline_stylebox.content_margin_bottom = val
	_outline_stylebox.content_margin_top = val

func set_panel_size(new_size: Vector2) -> void:
	self.size = new_size

func set_outline_color(new_color: Color) -> void:
	self._outline_stylebox.bg_color = new_color

func set_container_color(new_color: Color) -> void:
	self._inner_container_stylebox.bg_color = new_color

func add_child_to_container(child: Node) -> void:
	self._inner_container.add_child(child)

func show_panel() -> void:
	self.visible = true

func hide_panel() -> void:
	self._last_pos = self.position
	self.visible = false

func _process(delta: float) -> void:
	pass

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, self._component_tag, msg)
