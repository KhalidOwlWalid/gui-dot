# @tool
extends Node

const Guidot_Data := preload("res://gdscript/components/guidot_data.gd")

# @onready var guidot_utils = Guidot_Utils.new()
@onready var data: PackedVector2Array = PackedVector2Array()
@onready var curr_t: float = 0
@onready var last_update_ms: int = Time.get_ticks_msec()
@onready var init_ms: int = Time.get_ticks_msec()
@onready var data_transmitted: bool = false

signal data_received

func append_point(new_point: Vector2) -> void:
	data.append(new_point)
	data_received.emit()

func _ready() -> void:
	pass

func _mouse_cursor_data(delta: float) -> void:
	var curr_ms: int = Time.get_ticks_msec()
	if (curr_ms - last_update_ms > 10):
		var relative_ms: int = curr_ms - init_ms
		var curr_mouse_pos = self.get_viewport().get_mouse_position()
		append_point(Vector2(float(relative_ms)/1000, curr_mouse_pos.x/1920))
		last_update_ms = Time.get_ticks_msec()

func _process(delta: float) -> void:
	_mouse_cursor_data(delta)
	# pass
