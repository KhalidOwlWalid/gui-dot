extends Button

var last_tick = Time.get_ticks_usec()
var data1
var data2
var demo_graph

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	demo_graph = get_node(NodePath("/root/main/demo_graph"))
	data1 = PackedVector2Array()
	data2 = PackedVector2Array()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _pressed() -> void:
	var tick = Time.get_ticks_usec()
	if (tick - last_tick > 0.001e6):
		data1.push_back(Vector2(tick * 1e-6, randf_range(-10, 10)))
		data2.push_back(Vector2(tick * 1e-6, randf_range(-10, 10)))
		demo_graph.set_data_vector(data1, 0)
		demo_graph.set_data_vector(data2, 1)
		last_tick = Time.get_ticks_usec()
