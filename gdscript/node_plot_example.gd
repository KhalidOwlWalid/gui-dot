#@tool
extends Graph_2D
var data: PackedVector2Array
var data1: PackedVector2Array
var graph_node: Node
var graph_node1: Node
var graph_name: String
var last_tick = Time.get_ticks_usec()
var data_name: String = "position.y"
var data_name1: String = "position.x"
var base_position: Vector2
var time: float

func _ready() -> void:
	graph_name = "demo_graph"
	graph_node = get_node_or_null(NodePath("/root/main/demo_graph"))
	data = PackedVector2Array()
	graph_node.add_data_with_keyword(data_name, data, Color.RED)
	base_position = position
	
func _process(delta: float):
	time += delta * 5
	position.y = base_position.y + 100 * sin(time)
	position.x = base_position.x + 100 * cos(time)
	var tick = Time.get_ticks_usec()
	graph_node = get_parent().get_child(0)
	graph_node1 = get_parent().get_child(1)
	if (tick - last_tick > 0.01e6):
		data.append(Vector2(tick * 1e-6, position.y))
		graph_node.update_data_with_keyword(data_name, data)
		last_tick = Time.get_ticks_usec()
