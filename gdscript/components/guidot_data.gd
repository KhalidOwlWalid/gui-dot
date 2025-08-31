class_name Guidot_Data_Core
extends Node

@onready var guidot_node: Node
@onready var data: PackedVector2Array = PackedVector2Array()
@onready var last_update_ms: float = Time.get_ticks_msec()

func _ready() -> void:
	pass

func assign_node(node: Node):
	guidot_node = node

func _process(delta: float) -> void:
	var curr_ms = Time.get_ticks_msec()
	if (curr_ms - last_update_ms > 1000):
		var curr_mouse_pos = self.get_viewport().get_mouse_position()
		data.append(Vector2(curr_ms, curr_mouse_pos.x))
		last_update_ms = Time.get_ticks_msec()
