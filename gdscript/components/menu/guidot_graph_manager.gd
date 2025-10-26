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
@onready var _server_config_tab: AspectRatioContainer
@onready var _x_axis_config_tab: AspectRatioContainer
@onready var _y_axis_config_tab: AspectRatioContainer

var data_subscriber_menu: Guidot_Panel

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# TODO (Khalid): Remove this, temporary for now
	self.data_subscriber_menu.position = Vector2(500, 500)
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

# For each configuration tab, it requires:
#	=> VBox - Host all of the configuration row
func create_configuration_tab(tab_name: String) -> AspectRatioContainer:
	var config_tab: AspectRatioContainer = AspectRatioContainer.new()
	config_tab.name = tab_name
	var vbox: VBoxContainer = VBoxContainer.new()
	
	config_tab.add_child(vbox)

	return config_tab

# Takes in the configuration tab and helps populate the internal VBoxContainer
func add_config_rows(config_tab: AspectRatioContainer, config_rows: Array[Node]) -> void:
	var config_tab_vbox: VBoxContainer  = config_tab.get_children()[0]
	
	for row in config_rows:
		config_tab_vbox.add_child(row)

func _create_server_selection_row() -> void:
	pass

func _on_close_button_pressed() -> void:
	self.visible = false

func _on_subscribe_pressed() -> void:
	print("Subscribe button pressed")

func _create_checkbox_with_label(label: String) -> HBoxContainer:
	var l_hbox1: HBoxContainer = HBoxContainer.new()
	var l_cbox1: CheckBox = CheckBox.new()
	var l_label1: Label = Label.new()
	l_label1.text = label

	l_hbox1.add_child(l_cbox1)
	l_hbox1.add_child(l_label1)

	return l_hbox1

func _setup_data_subscriber_menu() -> void:
	# Ensure this gets constructed first, and added into the scene tree before initializing any of its properties
	self.data_subscriber_menu = Guidot_Panel.new()
	self.add_child(self.data_subscriber_menu)

	var l_vbox1: VBoxContainer = VBoxContainer.new()
	var header: Label = Label.new()
	var search_bar: LineEdit = LineEdit.new()
	var l_scr_cont: ScrollContainer = ScrollContainer.new()
	var data_list_vbox: VBoxContainer = VBoxContainer.new()

	self.data_subscriber_menu.custom_minimum_size = Vector2(300, 300)
	self.data_subscriber_menu.set_background_color(Guidot_Utils.get_color("red"))
	var child_array: Array[Node] = [header, search_bar, l_scr_cont]

	for node in child_array:
		self.data_subscriber_menu.add_child(node)

	l_scr_cont.add_child(data_list_vbox)
	data_list_vbox.add_child(self._create_checkbox_with_label("Test"))

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
	self._server_config_tab = self.create_configuration_tab("Server Manager")
	_graph_config_tab_cont.add_child(_server_config_tab)

	# All server configuration settings
	var graph_buffer_mode_label = self.create_label_row("Current mode", "Realtime", Vector2(200, 20))
	var server_selection = self.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))
	var subscribe_data_margin_container: MarginContainer = MarginContainer.new()

	var subscribe_data_button: Button = Button.new()
	subscribe_data_margin_container.add_child(subscribe_data_button)
	subscribe_data_button.text = "+ Subscribe to data"
	subscribe_data_button.pressed.connect(_on_subscribe_pressed)

	# TODO (Khalid): Use a scroll container to allow us to go through all of the subscribed data
	var sub_data_scroll_cont: ScrollContainer = ScrollContainer.new()
	sub_data_scroll_cont.custom_minimum_size = Vector2(100, 40)
	var sub_data_vbox: VBoxContainer = VBoxContainer.new()
	sub_data_scroll_cont.add_child(sub_data_vbox)
	var label_test = Label.new()
	label_test.text = "Hello World"
	var label2 = Label.new()
	label2.text = "Hello World"
	var label3 = Label.new()
	label3.text = "Hello World"
	sub_data_vbox.add_child(label_test)
	sub_data_vbox.add_child(label2)
	sub_data_vbox.add_child(label3)
	
	var server_config_rows: Array[Node] = [graph_buffer_mode_label, server_selection, subscribe_data_margin_container, sub_data_scroll_cont]
	self.add_config_rows(self._server_config_tab, server_config_rows)

	# Setup axis configuration tab
	self._x_axis_config_tab = self.create_configuration_tab("X-Axis")
	_graph_config_tab_cont.add_child(self._x_axis_config_tab)

	# All Axis Configuration settings
	var test = self.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))
	var test1 = self.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))
	var x_axis_config_rows: Array[Node] = [test, test1]
	self.add_config_rows(self._x_axis_config_tab, x_axis_config_rows) 

	# Setup axis configuration tab
	self._y_axis_config_tab = self.create_configuration_tab("Y-Axis")
	_graph_config_tab_cont.add_child(self._y_axis_config_tab)

	# All Axis Configuration settings
	var test2 = self.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))
	var test3 = self.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))
	var y_axis_config_rows: Array[Node] = [test2, test3]
	self.add_config_rows(self._y_axis_config_tab, y_axis_config_rows) 

	self._setup_data_subscriber_menu()
