extends Graph_2D

var graph_node: Node
var data: PackedVector2Array
var fps: float
var t: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	graph_node = get_parent().get_node("fps_plot")
	data = PackedVector2Array()
	graph_node.add_data_with_keyword("fps", data, Color.RED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	t += delta
	fps = Engine.get_frames_per_second()
	data.append(Vector2(t, fps))
	graph_node.update_data_with_keyword("fps", data)
	#graph_node.set_y_range("fps", 0, 150)
	if (data.size() > 30):
		data.remove_at(0)
