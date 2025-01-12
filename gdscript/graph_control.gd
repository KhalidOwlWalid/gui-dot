extends Graph_2D

var last_tick = Time.get_ticks_usec()
var graph_node: Node
var data: PackedVector2Array
var data1: PackedVector2Array
var data2: PackedVector2Array
var data3: PackedVector2Array
var prev_data_size: int
var is_randomize: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var node_name = self.name
	graph_node = get_node(NodePath("/root/main/" + node_name))
	data = PackedVector2Array()
	#data.append(Vector2(1,1))
	is_randomize = true
	graph_node.add_data_with_keyword("Test", data, Color.RED)
	graph_node.add_data_with_keyword("Test1", data, Color.WHITE)
	graph_node.add_data_with_keyword("Test2", data, Color.GREEN)
	graph_node.add_data_with_keyword("Test3", data, Color.DARK_GREEN)
	#print(graph_node.get_data_with_keyword("Test"))
	#var screen_size = DisplayServer.screen_get_size()
	#graph_node.set_size(screen_size)
	
func randomize_data():
	var tick = Time.get_ticks_usec()
	if (tick - last_tick > 1e6):
		data.append(Vector2(tick * 1e-6, randf_range(-10, 10)))
		data1.append(Vector2(tick * 1e-6, randf_range(-5, 5)))
		data2.append(Vector2(tick * 1e-6, randf_range(100, 200)))
		data3.append(Vector2(tick * 1e-6, randf_range(-50, 0)))
		graph_node.update_data_with_keyword("Test", data)
		graph_node.update_data_with_keyword("Test1", data1)
		graph_node.update_data_with_keyword("Test2", data2)
		graph_node.update_data_with_keyword("Test3", data3)
		last_tick = Time.get_ticks_usec()
		queue_redraw()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if is_randomize:
		randomize_data()
