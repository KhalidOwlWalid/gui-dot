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
extends Guidot_Panel

var selected_server: String

@onready var _graph_config_tab_cont: TabContainer = TabContainer.new()
@onready var _graph_config_window: PanelContainer = PanelContainer.new()
@onready var _config_window_stylebox: StyleBoxFlat = StyleBoxFlat.new()

# Setting tabs
@onready var _server_config_tab: AspectRatioContainer = AspectRatioContainer.new()
@onready var _axis_config_tab: AspectRatioContainer = AspectRatioContainer.new()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# print(_graph_config_window.size)
	pass

func scaled_row_size(column_scale: float) -> Vector2:
	return Vector2(column_scale * self._graph_config_window.size.x, 20)

func create_label_row(label_text: String, label_value, custom_min_size: Vector2,) -> MarginContainer:
	# Internal properties of the dropdown selection row
	var margin_size: int = 5
	
	# All nodes required to create the dropdown
	var panel_container1 = MarginContainer.new()
	var hbox1 = HBoxContainer.new()
	var label = Label.new()
	var value = Label.new()

	hbox1.custom_minimum_size = custom_min_size
	label.custom_minimum_size = custom_min_size
	value.custom_minimum_size = custom_min_size

	# Control the margin size of each dropdown selection so that it looks nicer in the GUI
	panel_container1.add_theme_constant_override("margin_top", margin_size)
	panel_container1.add_theme_constant_override("margin_bottom", margin_size)
	panel_container1.add_theme_constant_override("margin_left", margin_size)
	panel_container1.add_theme_constant_override("margin_right", margin_size)
	
	# Set the labels properties
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	value.text = str(label_value)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Add the labels and the dropdown selection to the HBOX Container
	hbox1.add_child(label)
	hbox1.add_child(value)
	panel_container1.add_child(hbox1)

	return panel_container1

func create_dropdown_selection_row(label_text: String,  dropdown_items: Array, custom_min_size: Vector2) -> MarginContainer:

	# Internal properties of the dropdown selection row
	var margin_size: int = 5
	
	# All nodes required to create the dropdown
	var panel_container1 = MarginContainer.new()
	var hbox1 = HBoxContainer.new()
	var label1 = Label.new()
	var option_button1 = OptionButton.new()

	hbox1.custom_minimum_size = custom_min_size
	label1.custom_minimum_size = custom_min_size
	option_button1.custom_minimum_size = custom_min_size

	# Control the margin size of each dropdown selection so that it looks nicer in the GUI
	panel_container1.add_theme_constant_override("margin_top", margin_size)
	panel_container1.add_theme_constant_override("margin_bottom", margin_size)
	panel_container1.add_theme_constant_override("margin_left", margin_size)
	panel_container1.add_theme_constant_override("margin_right", margin_size)
	
	# Set the labels properties
	label1.text = label_text
	label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	option_button1.alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in len(dropdown_items):
		option_button1.add_item(str(dropdown_items[i]))

	# Add the labels and the dropdown selection to the HBOX Container
	hbox1.add_child(label1)
	hbox1.add_child(option_button1)
	panel_container1.add_child(hbox1)

	return panel_container1

func create_configuration_tab() -> AspectRatioContainer:
	var config_tab: AspectRatioContainer = AspectRatioContainer.new()
	var vbox: VBoxContainer = VBoxContainer.new()
	
	config_tab.add_child(vbox)

	return config_tab

# Takes in the configuration tab and helps populate the internal VBoxContainer
func add_config_row(config_tab: AspectRatioContainer, config_row: MarginContainer) -> void:
	# var config_tab_children: Array[Node]  = config_tab.get_child()
	pass

func _on_close_button_pressed() -> void:
	self.visible = false

func _ready() -> void:

	var main_vbox: VBoxContainer = VBoxContainer.new()
	self.add_child(main_vbox)

	var header_hbox: HBoxContainer = HBoxContainer.new()

	# Setup for header label for the graph manager
	var main_header: Label = Label.new()
	main_header.text = "Settings"
	main_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_header.custom_minimum_size = Vector2(self.size.x * 0.9, 10)
	header_hbox.add_child(main_header)

	# Setup the controls button for the graph manager
	var close_button: Button = Button.new()
	close_button.text = "X"
	close_button.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_RIGHT)
	close_button.custom_minimum_size = Vector2(self.size.x * 0.1, 10)
	close_button.add_theme_color_override("font_color", Color.RED)
	close_button.pressed.connect(_on_close_button_pressed)
	header_hbox.add_child(close_button)

	main_vbox.add_child(header_hbox)

	# Graph configuration tab container setup
	main_vbox.add_child(_graph_config_tab_cont)

	# Setup server manager tab
	_server_config_tab.name = "Server Manager"
	var vbox1 = VBoxContainer.new()
	var server_options = self.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))
	var data_type = self.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))
	var some_string = self.create_label_row("Current mode", "Realtime", Vector2(200, 20))
	_server_config_tab.add_child(vbox1)
	vbox1.add_child(server_options)
	vbox1.add_child(data_type)
	vbox1.add_child(some_string)
	_graph_config_tab_cont.add_child(_server_config_tab)

	_axis_config_tab.name = "Axis Configuration"
	_graph_config_tab_cont.add_child(_axis_config_tab)
	var axis_config_vbox: VBoxContainer = VBoxContainer.new()
	var test = self.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))
	var test1 = self.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))
	axis_config_vbox.add_child(test)
	axis_config_vbox.add_child(test1)
	_axis_config_tab.add_child(axis_config_vbox)
	_graph_config_tab_cont.add_child(_axis_config_tab)
