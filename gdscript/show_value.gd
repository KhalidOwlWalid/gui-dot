extends Label

var data1
var data2
var graph_node
var curr_node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	data1 = PackedVector2Array()
	data2 = PackedVector2Array()
	graph_node = get_node(NodePath("/root/main/demo_graph"))
	curr_node = self.get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	data1 = graph_node.get_data_vector(0)
	data2 = graph_node.get_data_vector(1)
	if (data1.is_empty()):
		return
	
	var data1_x = String.num(data1[data1.size() - 1].x, 2)
	var data1_y = String.num(data1[data1.size() - 1].y, 2)
	var data1_fmt: String
	data1_fmt = data1_x + " " + data1_y
	curr_node.text = String(data1_fmt)
	
	
