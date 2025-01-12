extends Graph_2D

var last_tick = Time.get_ticks_usec()
var graph_node: Node
var data: PackedVector2Array
var prev_data_size: int
var is_randomize: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var node_name = self.name
	graph_node = get_node(NodePath("/root/main/" + node_name))
	data = PackedVector2Array()
	data.append(Vector2(1,1))
	is_randomize = true
	graph_node.add_data_with_keyword("Test", data)
	#print(graph_node.get_data_with_keyword("Test"))
	#var screen_size = DisplayServer.screen_get_size()
	#graph_node.set_size(screen_size)
	
func randomize_data():
	var tick = Time.get_ticks_usec()
	if (tick - last_tick > 0.001e6):
		data.push_back(Vector2(tick * 1e-6, randf_range(-10, 10)))
		#print(data)
		graph_node.update_data_with_keyword("Test", data)
		last_tick = Time.get_ticks_usec()
		queue_redraw()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if is_randomize:
		randomize_data()
