extends Button

var last_tick = Time.get_ticks_usec()
var data
var graph_node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	graph_node = get_node(NodePath("/root/main/demo_graph"))
	data = PackedVector2Array()
	#graph_node.add_data_with_keyword("Test", data, Color.RED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#
#func _pressed() -> void:
	#var tick = Time.get_ticks_usec()
	#if (tick - last_tick > 0.001e6):
		#data.append(Vector2(tick * 1e-6, randf_range(-10, 10)))
		#print(data)
		#last_tick = Time.get_ticks_usec()
	#graph_node.update_data_with_keyword("Test", data)
