extends Button

var last_tick = Time.get_ticks_usec()
var data
var demo_graph

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	demo_graph = get_node(NodePath("/root/main/demo_graph"))
	data = PackedVector2Array()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _pressed() -> void:
	var tick = Time.get_ticks_usec()
	if (tick - last_tick > 0.001e6):
		data.push_back(Vector2(tick * 1e-6, randf_range(-10, 10)))
		demo_graph.set("_data.packed_v2_data", data)
		last_tick = Time.get_ticks_usec()
