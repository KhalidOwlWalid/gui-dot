extends Graph_2D

var last_tick = Time.get_ticks_usec()
var graph_node
var data

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	graph_node = get_node("/root/Control/Graph_2D")
	data = PackedVector2Array()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var tick = Time.get_ticks_usec()
	if (tick - last_tick > 0.01e6):
		data.push_back(Vector2(tick, randf_range(-10, 10)))
		graph_node.set("_data1.packed_v2_data", data)
		last_tick = Time.get_ticks_usec()
#
		queue_redraw()
	#if (tick - last_tick > 3e6):
