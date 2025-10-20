@tool
class_name Guidot_Graph_Manager
#extends Node
#
#signal selected_server_changed
#signal graph_buffer_mode_changed
#signal selected_data_changed
#
#signal server_deselected
#signal data_deselected
#
#var server_list: Array[Guidot_Data_Server]
#var selected_graph_buffer_mode: Guidot_Common.Graph_Buffer_Mode
#var available_data: Array[String]
#
#var selected_server: Guidot_Data_Server
#var selected_data: String
#
#func _ready() -> void:
	#pass
	#
extends TabContainer

var selected_server: String

# Called when the node enters the scene tree for the first time.
# func _ready() -> void:
# 	self.name = "Server_Configuration"
# 	self.set_margin_size(20)
# 	self.custom_minimum_size = Vector2(100, 100)
# 	self.set_background_color(Color.BLACK)


@onready var _graph_config_window: PanelContainer = PanelContainer.new()
@onready var _config_window_stylebox: StyleBoxFlat = StyleBoxFlat.new()
@onready var _server_config_tab: AspectRatioContainer = AspectRatioContainer.new()
# @onready var color_dict: Dictionary = Guidot_Utils.color_dict

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# print(_graph_config_window.size)
	pass

func scaled_row_size(column_scale: float) -> Vector2:
	return Vector2(column_scale * self._graph_config_window.size.x, 20)

func example_row() -> MarginContainer:
	var panel_container1 = MarginContainer.new()
	var hbox1 = HBoxContainer.new()
	hbox1.custom_minimum_size = Vector2(190, 20)
	var label1 = Label.new()
	var option_button1 = OptionButton.new()

	panel_container1.add_theme_constant_override("margin_top", 10)
	panel_container1.add_theme_constant_override("margin_bottom", 10)
	label1.text = "Server name"
	label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	option_button1.add_item("Server 1")
	option_button1.add_item("Server 2")
	option_button1.add_item("Server 3")

	hbox1.add_child(label1)
	hbox1.add_child(option_button1)
	panel_container1.add_child(hbox1)
	return panel_container1

func _ready() -> void:
	self.add_child(_server_config_tab)
	_server_config_tab.name = "Server Manager"
	_server_config_tab.custom_minimum_size = Vector2(400, 50)

	var vbox1 = VBoxContainer.new()
	_server_config_tab.add_child(vbox1)

	var panel_container1 = self.example_row()
	vbox1.add_child(panel_container1)
