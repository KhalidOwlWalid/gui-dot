@tool
class_name Guidot_Graph_Manager
extends Guidot_Panel2

signal data_selected

var selected_server: String

@onready var _graph_config_tab_cont: TabContainer = TabContainer.new()
@onready var _graph_config_window: PanelContainer = PanelContainer.new()
@onready var _config_window_stylebox: StyleBoxFlat = StyleBoxFlat.new()

# Setting tabs
@onready var _server_config_tab: AspectRatioContainer
@onready var _x_axis_config_tab: AspectRatioContainer
@onready var _y_axis_config_tab: AspectRatioContainer

var _data_subscriber_manager: Guidot_Panel2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# TODO (Khalid): Remove this, temporary for now
	self._data_subscriber_manager.position = Vector2(500, 500)
	pass

func scaled_row_size(column_scale: float) -> Vector2:
	return Vector2(column_scale * self._graph_config_window.size.x, 20)

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

func _on_data_selected(data_str_array: Array[String]) -> void:
	print(data_str_array)
	pass

func _on_apply_changes_pressed(selected_data: VBoxContainer) -> void:
	var selected_data_str: Array[String] = []
	for hbox in selected_data.get_children():
		var cbox: CheckBox = hbox.get_child(0)
		var data_label: Label = hbox.get_child(1)

		if cbox.button_pressed:
			selected_data_str.append(data_label.text)

	self.data_selected.emit(selected_data_str)

func _on_close_button_submenu_pressed(panel: Node) -> void:
	panel.visible = false

func _on_close_button_pressed() -> void:
	self.visible = false

func _on_subscribe_pressed() -> void:
	self._data_subscriber_manager.visible = true

func _create_checkbox_with_label(label: String) -> HBoxContainer:
	var l_hbox1: HBoxContainer = HBoxContainer.new()
	var l_cbox1: CheckBox = CheckBox.new()
	var l_label1: Label = Label.new()
	l_label1.text = label

	l_hbox1.add_child(l_cbox1)
	l_hbox1.add_child(l_label1)

	return l_hbox1

func _setup_data_subscriber_manager() -> void:
	# Ensure this gets constructed first, and added into the scene tree before initializing any of its properties
	self._data_subscriber_manager = Guidot_Panel2.new()
	
	self.add_child(self._data_subscriber_manager)
	self._data_subscriber_manager.hide_panel()

	self._data_subscriber_manager.custom_minimum_size = Vector2(300, 300)
	self._data_subscriber_manager.set_outline_color(Guidot_Utils.get_color("white"))

	var l_vbox1: VBoxContainer = VBoxContainer.new()
	self._data_subscriber_manager.add_child_to_container(l_vbox1)
	self._data_subscriber_manager.set_container_color(Guidot_Utils.get_color("gd_black"))

	# Header for data subscriber
	var l_hbox1: HBoxContainer = HBoxContainer.new()
	var header: Label = Label.new()
	var l_close_btn1: Button = Button.new()
	l_hbox1.add_child(header)	
	l_hbox1.add_child(l_close_btn1)

	var apply_button: Button = Button.new()
	var search_bar: LineEdit = LineEdit.new()
	var l_scr_cont: ScrollContainer = ScrollContainer.new()
	var data_list_vbox: VBoxContainer = VBoxContainer.new()

	var child_array: Array[Node] = [l_hbox1, apply_button, search_bar, l_scr_cont]

	for node in child_array:
		l_vbox1.add_child(node)

	# Setup the header
	l_hbox1.custom_minimum_size = Vector2(self._data_subscriber_manager.size.x, 20)
	l_hbox1.size = Vector2(self._data_subscriber_manager.size.x, 20)
	header.text = "Data Subscriber Manager"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_close_btn1.custom_minimum_size = Vector2(30, 20)
	l_close_btn1.text = "X"
	l_close_btn1.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_RIGHT)
	l_close_btn1.pressed.connect(_on_close_button_submenu_pressed.bind(self._data_subscriber_manager))
	l_scr_cont.custom_minimum_size = Vector2(self._data_subscriber_manager.size.x, 100)

	l_scr_cont.add_child(data_list_vbox)
	data_list_vbox.add_child(self._create_checkbox_with_label("Engine Speed"))
	data_list_vbox.add_child(self._create_checkbox_with_label("Fd Commands"))
	data_list_vbox.add_child(self._create_checkbox_with_label("Roll"))
	data_list_vbox.add_child(self._create_checkbox_with_label("Pitch"))
	data_list_vbox.add_child(self._create_checkbox_with_label("Yaw"))

	apply_button.text = "Apply changes"
	apply_button.pressed.connect(self._on_apply_changes_pressed.bind(data_list_vbox))

func _ready() -> void:

	super._ready()
	var main_vbox: VBoxContainer = VBoxContainer.new()
	self.add_child_to_container(main_vbox)
	self.set_outline_color(Guidot_Utils.get_color("white"))
	self.set_container_color(Guidot_Utils.get_color("gd_black"))
	self.set_panel_size(Vector2(500, 300))

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
	var graph_buffer_mode_label = Guidot_Utils.create_label_row("Current mode", "Realtime", Vector2(200, 20))
	var server_selection = Guidot_Utils.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))
	var subscribe_data_margin_container: MarginContainer = MarginContainer.new()

	var subscribe_data_button: Button = Button.new()
	subscribe_data_margin_container.add_child(subscribe_data_button)
	subscribe_data_button.text = "+ Subscribe to data"
	subscribe_data_button.pressed.connect(_on_subscribe_pressed)

	# TODO (Khalid): Use a scroll container to allow us to go through all of the subscribed data
	var sub_data_scroll_cont: ScrollContainer = ScrollContainer.new()
	sub_data_scroll_cont.custom_minimum_size = Vector2(100, 200)
	var sub_data_vbox: VBoxContainer = VBoxContainer.new()
	sub_data_scroll_cont.add_child(sub_data_vbox)

	var test_gd_panel2 = Guidot_Server_Config.new()
	
	var server_config_rows: Array[Node] = [graph_buffer_mode_label, server_selection, subscribe_data_margin_container, sub_data_scroll_cont, test_gd_panel2]
	self.add_config_rows(self._server_config_tab, server_config_rows)

	# Setup axis configuration tab
	self._x_axis_config_tab = self.create_configuration_tab("X-Axis")
	_graph_config_tab_cont.add_child(self._x_axis_config_tab)

	# All Axis Configuration settings
	var test = Guidot_Utils.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))
	var test1 = Guidot_Utils.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))
	var x_axis_config_rows: Array[Node] = [test, test1]
	self.add_config_rows(self._x_axis_config_tab, x_axis_config_rows) 

	# Setup axis configuration tab
	self._y_axis_config_tab = self.create_configuration_tab("Y-Axis")
	_graph_config_tab_cont.add_child(self._y_axis_config_tab)

	# All Axis Configuration settings
	var test2 = Guidot_Utils.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))
	var test3 = Guidot_Utils.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))
	var y_axis_config_rows: Array[Node] = [test2, test3]
	self.add_config_rows(self._y_axis_config_tab, y_axis_config_rows) 

	self._setup_data_subscriber_manager()

	# Signal handling
	self.data_selected.connect(self._on_data_selected)
