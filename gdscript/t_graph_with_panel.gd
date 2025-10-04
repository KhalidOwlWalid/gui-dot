class_name Guidot_Graph
extends PanelContainer

const Guidot_T_Series_Graph := preload("res://gdscript/time_series_graph.gd")

const LOG_DEBUG = Guidot_Log.Log_Level.DEBUG
const LOG_WARNING = Guidot_Log.Log_Level.WARNING
const LOG_INFO = Guidot_Log.Log_Level.INFO
const LOG_ERROR = Guidot_Log.Log_Level.ERROR

@onready var guidot_graph = Guidot_T_Series_Graph.new()
@onready var _guidot_stylebox: StyleBoxFlat = StyleBoxFlat.new()
@onready var margin_val: int = 1

@onready var color_dict: Dictionary = Guidot_Utils.color_dict

@onready var _last_mouse_position: Vector2 = Vector2()
@onready var _mouse_in: bool = false

@onready var _new_position: Vector2 = Vector2()
@onready var _drag_direction: Vector2 = Vector2()
@onready var _is_dragging: bool = false
@onready var _dragging_distance: float = 0
@onready var _last_position: Vector2 = Vector2()

@onready var _is_in_focus: bool = false

enum UI_Mode {
	SELECTED,
	DATA_DISPLAY,
	PREVIEW,
	SETTINGS,
}

@onready var _current_ui_mode: UI_Mode = UI_Mode.DATA_DISPLAY 

func _ready() -> void:
	self.name = "Guidot_Graph"
	var factor: float = 1
	self.size = Vector2(620*factor, 360*factor)
	self.add_child(guidot_graph)

	_guidot_stylebox.bg_color = color_dict["gd_black"]
	set_margin_size(margin_val)
	add_theme_stylebox_override("panel", _guidot_stylebox)
	self._last_position = self.position
	self._last_mouse_position = self.get_viewport().get_mouse_position()

	# Signals connection
	guidot_graph.parent_focus_requested.connect(_on_parent_focused)
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	self._mouse_in = true

func _on_mouse_exited() -> void:
	self._mouse_in = false

func _on_parent_focused() -> void:
	self._is_in_focus = !self._is_in_focus
	self.log(LOG_INFO, ["On parent focused", self._is_in_focus])

	if (self._is_in_focus):
		self.set_stylebox_color(color_dict["red"])
	else:
		# TODO (Khalid): This needs to be able to change back to previous color, not hardcoded color
		self.set_stylebox_color(color_dict["gd_black"])

func set_stylebox_color(color: Color) -> void:
	_guidot_stylebox.bg_color = color

func set_margin_size(val: int) -> void:
	_guidot_stylebox.content_margin_left = val
	_guidot_stylebox.content_margin_right = val
	_guidot_stylebox.content_margin_bottom = val
	_guidot_stylebox.content_margin_top = val

func set_panel_size(new_size: Vector2) -> void:
	pass

var _drag_offset: Vector2

func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:	
			if event.is_pressed() and self._current_ui_mode == UI_Mode.SELECTED:
				# Start dragging - calculate the offset from mouse to panel position
				_is_dragging = true
				# This allows the user to grab the panel anywhere within the panel and drag it
				# anywhere
				_drag_offset = get_global_mouse_position() - self.global_position
				self._last_position = self.position
			else:
				_is_dragging = false

	if (self._current_ui_mode == UI_Mode.SELECTED):	
		if event is InputEventMouseMotion:

			# Only allow the user to drag when the mouse is inside the panel
			if self._is_dragging and self._mouse_in:
				self.log(Guidot_Log.Log_Level.DEBUG, ["Dragging"])
				var curr_mouse_pos: Vector2 = get_global_mouse_position()
				
				# Move panel while maintaining the original mouse offset
				self.global_position = curr_mouse_pos - _drag_offset
				
				self._last_mouse_position = curr_mouse_pos
				self._last_position = self.position

func _process(delta: float) -> void:
	
	if (self._is_in_focus):
		self._current_ui_mode = UI_Mode.SELECTED

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, "MASTER_PANEL", msg)
