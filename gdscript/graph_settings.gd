extends Button

var graph_settings: Array[Node]
var data_viewer: Array[Node]
var settings_dict: Dictionary
var data_viewer_dict: Dictionary
var data_type_dict: Dictionary
var data: PackedVector2Array
var demo_graph: Node
var count: float
var data_keyword: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	graph_settings = get_tree().get_nodes_in_group("graph_settings")
	data_viewer = get_tree().get_nodes_in_group("data_viewer")

	for i in range(graph_settings.size()):
		settings_dict.get_or_add(graph_settings[i].name, i)

	for i in range(data_viewer.size()):
		data_viewer_dict.get_or_add(data_viewer[i].name, i)

  # Initializing all parameters
	# for setting in graph_settings:
	# 	if (setting.name == "data_type_option"):
	# 		for i in range(setting.item_count):
	# 			data_type_dict.get_or_add(i, setting.get_item_text(i))

	data = PackedVector2Array()
	demo_graph = get_node(NodePath("/root/main/demo_graph"))
	data_keyword = "Test"
	demo_graph.add_data_with_keyword(data_keyword, data, Color.RED)
	count = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _pressed() -> void:

	var data_type_node: Node = graph_settings[settings_dict.get("data_type_option")]
	var min_val_node: Node = graph_settings[settings_dict.get("min_val")]
	var max_val_node: Node = graph_settings[settings_dict.get("max_val")]
	var y_min_val_node: Node = graph_settings[settings_dict.get("y_min_val")]
	var y_max_val_node: Node = graph_settings[settings_dict.get("y_max_val")]
	var curr_type_idx: int = data_type_node.selected
	var curr_item_txt: String = data_type_node.get_item_text(curr_type_idx)
	match curr_item_txt:
		"sin":
			min_val_node.editable = false
			max_val_node.editable = false
			var amplitude: float = 1.0
			data.append(Vector2(count, amplitude * sin(count)))
			print("sin data selected")
		"random":
			print("random")
		_:
			print("Selected data type does not exist. Defaulting to sin")

	demo_graph.set_y_range(data_keyword, float(y_min_val_node.text), float(y_max_val_node.text))
	print(float(y_min_val_node.text))
	demo_graph.update_data_with_keyword(data_keyword, data)
	var x_viewer: Node = data_viewer[data_viewer_dict.get("x_val")]
	var y_viewer: Node = data_viewer[data_viewer_dict.get("y_val")]
	x_viewer.text = String.num(data[-1].x)
	y_viewer.text = String.num(data[-1].y)
	count += 0.05
