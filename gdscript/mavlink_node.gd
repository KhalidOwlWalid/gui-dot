# @tool
extends Node

const Guidot_Data := preload("res://gdscript/components/guidot_data.gd")

# @onready var guidot_utils = Guidot_Utils.new()
@onready var data: PackedVector2Array = PackedVector2Array()
@onready var curr_t: float = 0
@onready var last_update_ms: int = Time.get_ticks_msec()
@onready var init_ms: int = Time.get_ticks_msec()
@onready var data_transmitted: bool = false

# dc - data client
var _dc_mouse_cursor_x: Guidot_Data_Client = Guidot_Data_Client.new()
var _dc_mouse_cursor_y: Guidot_Data_Client = Guidot_Data_Client.new()

signal data_received

func append_point(new_point: Vector2) -> void:
	data.append(new_point)
	data_received.emit()

func _ready() -> void:
	print("Mavlink node is now ready")
	self.add_child(self._dc_mouse_cursor_x)
	self.add_child(self._dc_mouse_cursor_y)

	self._dc_mouse_cursor_x.set_unit("Nm")
	self._dc_mouse_cursor_x.set_description("Some random description")

func _mouse_cursor_data(delta: float) -> void:
	var curr_ms: int = Time.get_ticks_msec()
	var curr_s: float = float(curr_ms)/1000

	if (curr_ms - last_update_ms > 10):
		var relative_ms: int = curr_ms - init_ms
		var curr_mouse_pos = self.get_viewport().get_mouse_position()

		# Mimic no data points
		# if (float(Time.get_ticks_msec())/1000 > 5.0) and float(Time.get_ticks_msec())/1000 < 10.0 \
		# 	or (float(Time.get_ticks_msec())/1000 > 12.0) and float(Time.get_ticks_msec())/1000 < 20.0:
		append_point(Vector2(curr_s, curr_mouse_pos.x/1920))
		self._dc_mouse_cursor_x.add_data_point(curr_mouse_pos.x)
		self._dc_mouse_cursor_y.add_data_point(curr_mouse_pos.y)
		last_update_ms = Time.get_ticks_msec()

func _physics_process(delta: float) -> void:
	_mouse_cursor_data(delta)	
