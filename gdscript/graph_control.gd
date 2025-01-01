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
	print(node_name)
	data = PackedVector2Array()
	prev_data_size = data.size()
	is_randomize = true
	#var screen_size = DisplayServer.screen_get_size()
	#graph_node.set_size(screen_size)
	
func randomize_data():
	var tick = Time.get_ticks_usec()
	if (tick - last_tick > 0.001e6):
		data.push_back(Vector2(tick * 1e-6, randf_range(-10, 10)))
		graph_node.set("_data.packed_v2_data", data)
		last_tick = Time.get_ticks_usec()
		queue_redraw()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if is_randomize:
		randomize_data()
	else:
		data = graph_node.get("_data.packed_v2_data")
		if (data.is_empty()):
			return
		
		if (data.size() != prev_data_size):
			print("Previous data size: ", prev_data_size, " Current data size: ", data.size())
			prev_data_size = data.size()
			queue_redraw()
