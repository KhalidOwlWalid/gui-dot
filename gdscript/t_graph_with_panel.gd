class_name Guidot_Graph
extends PanelContainer

const Guidot_T_Series_Graph := preload("res://gdscript/time_series_graph.gd")

@onready var guidot_graph = Guidot_T_Series_Graph.new()
@onready var _guidot_stylebox: StyleBoxFlat = StyleBoxFlat.new()
@onready var margin_val: int = 1

@onready var color_dict: Dictionary = Guidot_Utils.color_dict

@onready var _last_mouse_position: Vector2 = Vector2()

@onready var _new_position: Vector2 = Vector2()
@onready var _drag_direction: Vector2 = Vector2()
@onready var _is_dragging: bool = false
@onready var _dragging_distance: float = 0
@onready var _last_position: Vector2 = Vector2()

func _ready() -> void:
	self.name = "Guidot_Graph"
	var factor: float = 0.9
	self.size = Vector2(620*factor, 360*factor)
	self.add_child(guidot_graph)

	_guidot_stylebox.bg_color = color_dict["gd_black"]
	set_margin_size(margin_val)
	add_theme_stylebox_override("panel", _guidot_stylebox)
	self._last_position = self.position
	self._last_mouse_position = self.get_viewport().get_mouse_position()

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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:	
		if event.is_pressed():
			# Start dragging - calculate the offset from mouse to panel position
			_is_dragging = true
			_drag_offset = get_global_mouse_position() - self.global_position
			self._last_position = self.position
		else:
			_is_dragging = false

	if event is InputEventMouseMotion and self._is_dragging:
		self.log(Guidot_Log.Log_Level.INFO, ["Dragging"])
		var curr_mouse_pos: Vector2 = get_global_mouse_position()
		
		# Move panel while maintaining the original mouse offset
		self.global_position = curr_mouse_pos - _drag_offset
		
		self._last_mouse_position = curr_mouse_pos
		self._last_position = self.position

func _move_display_process() -> void:
	if _is_dragging:
		var curr_mouse_offset: Vector2
		var curr_mouse_pos: Vector2 = self.get_viewport().get_mouse_position()

		if (curr_mouse_pos != self._last_mouse_position):
			curr_mouse_offset = curr_mouse_pos - self.position
			self.position = self._last_mouse_position + curr_mouse_offset

		# self.log(Guidot_Log.Log_Level.INFO, ["Currentt mouse position", curr_mouse_pos])
		# self.log(Guidot_Log.Log_Level.INFO, ["Current Position", self.position])
		# self.log(Guidot_Log.Log_Level.INFO, ["Current Mouse Offset", curr_mouse_offset])
		self._last_mouse_position = curr_mouse_pos
		self._last_position = self.position

func _process(delta: float) -> void:
	# self._move_display_process()
	pass

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, "MASTER_PANEL", msg)
