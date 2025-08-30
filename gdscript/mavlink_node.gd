@tool
extends Node

# const Guidot_Utils := preload("res://gdscript/components/guidot_utils.gd")

# @onready var guidot_utils = Guidot_Utils.new()

@onready var data: PackedVector2Array = PackedVector2Array()
@onready var last_update_ms: float = Time.get_ticks_msec()
@onready var my_val: int = Guidot_Utils.some_val

# var my_dict: Dictionary = {
#     "1": 1
# }

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var curr_ms = Time.get_ticks_msec()
	if (curr_ms - last_update_ms > 2000):
		var curr_mouse_pos = self.get_viewport().get_mouse_position()
		data.append(Vector2(curr_ms, curr_mouse_pos.x))
		last_update_ms = Time.get_ticks_msec()
		