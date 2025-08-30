extends Button

var graph_settings: Array[Node]
var data_viewer: Array[Node]
var settings_dict: Dictionary
var data_viewer_dict: Dictionary
var data_type_dict: Dictionary
var data: PackedVector2Array
var data2: PackedVector2Array
var demo_graph: Node
var count: float
var data_keyword: String
var data_keyword2: String
var data_keyword_1: String
var is_button_held: bool
var flag: bool
var time: float
var last_tick: float
var pause_flag: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	graph_settings = get_tree().get_nodes_in_group("graph_settings")
	print(graph_settings)
	data_viewer = get_tree().get_nodes_in_group("data_viewer")

	for i in range(graph_settings.size()):
		settings_dict.get_or_add(graph_settings[i].name, i)

	for i in range(data_viewer.size()):
		data_viewer_dict.get_or_add(data_viewer[i].name, i)

	data = PackedVector2Array()
	data2 = PackedVector2Array()
	demo_graph = get_node(NodePath("/root/main/demo_graph"))
	data_keyword = "Test"
	data_keyword2 = "Test2"
	demo_graph.add_data_with_keyword(data_keyword, data, Color.RED)
	#demo_graph.add_data_with_keyword(data_keyword2, data2, Color.BLUE)
	count = 0
	pause_flag = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var curr_tick: int = Time.get_ticks_usec()
	if (not pause_flag):
		if (curr_tick - last_tick > 0.01e6):
			demo_graph.append_data_with_keyword(data_keyword, mouse_position.x)
			#demo_graph.append_data_with_keyword(data_keyword2, mouse_position.y)
			last_tick = Time.get_ticks_usec()
			demo_graph.set_y_range(data_keyword, 200, 500)
			#demo_graph.set_y_range(data_keyword2, 200, 500)

func _button_down() -> void:
	print("Trigger")
	is_button_held = true

func _button_up() -> void:
	is_button_held = false

func _pressed() -> void:
	var data_type_node: Node = graph_settings[settings_dict.get("data_type_option")]
	var min_val_node: Node = graph_settings[settings_dict.get("min_val")]
	var max_val_node: Node = graph_settings[settings_dict.get("max_val")]
	var y_min_val_node: Node = graph_settings[settings_dict.get("y_min_val")]
	var y_max_val_node: Node = graph_settings[settings_dict.get("y_max_val")]
	var antialiased_checkbox: Node = graph_settings[settings_dict.get("antialiased_checkbox")]
	var paused_button: Node = graph_settings[settings_dict.get("antialiased_checkbox")]
	var curr_type_idx: int = data_type_node.selected
	var curr_item_txt: String = data_type_node.get_item_text(curr_type_idx)
	match curr_item_txt:
		"sin":
			# var tick = Time.get_ticks_usec()
			min_val_node.editable = false
			max_val_node.editable = false
			# var amplitude: float = 1.0
			# data.append(Vector2(tick, amplitude * sin(count)))
		"random":
			print("random")
		_:
			print("Selected data type does not exist. Defaulting to sin")

	demo_graph.set_y_range(data_keyword, float(y_min_val_node.text), float(y_max_val_node.text))
	# demo_graph.update_data_with_keyword(data_keyword, data)
	# var x_viewer: Node = data_viewer[data_viewer_dict.get("x_val")]
	# var y_viewer: Node = data_viewer[data_viewer_dict.get("y_val")]
	# x_viewer.text = String.num(data[-1].x)
	# y_viewer.text = String.num(data[-1].y)
	# count += 0.05
	print("Current antialiased setting: ", antialiased_checkbox.button_pressed)
	demo_graph.set_antialiased_flag(antialiased_checkbox.button_pressed)

	if (not pause_flag):
		pause_flag = true
	else:
		pause_flag = false
