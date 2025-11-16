class_name Guidot_Server_Config
extends Guidot_Panel2

var data_subscriber_manager: Guidot_Data_Sub_Manager

@onready var server_selection: MarginContainer 
@onready var sub_data_scroll_cont: ScrollContainer = ScrollContainer.new()
@onready var sub_data_vbox: VBoxContainer = VBoxContainer.new()

@onready var available_server: Dictionary = {}
@onready var selected_data: Dictionary = {}
@onready var selected_server: String = ""
var curr_server_node: Guidot_Data_Server

@onready var axis_pos_selection: Array = Guidot_Y_Axis.AxisPosition.keys()
@onready var color_selection: Array = Guidot_Utils.color_dict.keys()

func _get_server_dropdown() -> OptionButton:
	var hbox_server_sel: HBoxContainer = self.server_selection.get_child(0)
	var server_dropdown: OptionButton = hbox_server_sel.get_child(1)
	return server_dropdown

func _get_dropdown_selected_id() -> String:
	var server_dropdown: OptionButton = self._get_server_dropdown()
	return server_dropdown.get_item_text(server_dropdown.get_selected_id())

func _get_selected_data_display() -> void:
	var vbox = sub_data_scroll_cont.get_children()

func _on_subscribe_pressed() -> void:

	selected_server = self._get_dropdown_selected_id()

	self.data_subscriber_manager.visible = true
	curr_server_node = self.available_server[selected_server]

	self.data_subscriber_manager.set_available_data_for_selection(curr_server_node.get_all_registered_clients())

func _on_close_submenu_button_pressed(panel: Node) -> void:
	panel.visible = false

func register_data_sub_manager(dsub_node: Guidot_Data_Sub_Manager) -> void:
	self.data_subscriber_manager = dsub_node
	self.data_subscriber_manager.data_selected.connect(self._on_data_selected)

func get_selected_data() -> Array:
	return self.selected_data.keys()

func get_all_data_options() -> Array[String]:
	return self.data_subscriber_manager.get_available_data_options()

func _color_selected_callback(idx: int, gd_data_node: Guidot_Data) -> void:
	gd_data_node.set_line_color_str(color_selection[idx])

# This function creates the row to allow the user to configure the properties
# of their data
func _create_channel_config_name(chan_name: String, gd_data_node: Guidot_Data) -> HBoxContainer:
	var chan_config_hbox: HBoxContainer = HBoxContainer.new()
	var chan_label: Label = Label.new()

	# Allows the selection for which axis do we want to plot the data to
	var axis_dropdown: OptionButton = OptionButton.new()
	# Where do we want to place the y axis node, left or right?
	var pos_dropdown: OptionButton = OptionButton.new()
	# Color data selection for the data
	var color_dropdown: OptionButton = OptionButton.new()

	var label_norm_size: float = 0.3
	var n_dropdown: float = 3
	# The last substration here is 
	# var dropdown_norm_size: float = ((1 - label_norm_size)/n_dropdown)
	var dropdown_norm_size: float = 0.1
	chan_label.text = chan_name
	chan_label.custom_minimum_size = Vector2(label_norm_size * self.size.x, 20)

	for i in range(Guidot_Y_Axis._max_axis_num):
		axis_dropdown.add_item(str(i))
	axis_dropdown.custom_minimum_size = Vector2(dropdown_norm_size * self.size.x, 20)
	axis_dropdown.get_popup().max_size.y = 100

	for i in range(axis_pos_selection.size()):
		pos_dropdown.add_item(str(axis_pos_selection[i]).to_lower())
	pos_dropdown.custom_minimum_size = Vector2(dropdown_norm_size * self.size.x, 20)

	for i in range(color_selection.size()):
		color_dropdown.add_item(color_selection[i])
		if (gd_data_node.get_line_color_str() == color_selection[i]):
			color_dropdown.select(i)
	# color_dropdown.custom_minimum_size = Vector2(dropdown_norm_size * self.size.x, 20)
	# color_dropdown.size = Vector2()
	color_dropdown.get_popup().max_size.y = 100
	color_dropdown.item_selected.connect(self._color_selected_callback.bind(gd_data_node))

	chan_config_hbox.add_child(chan_label)
	chan_config_hbox.add_child(axis_dropdown)
	chan_config_hbox.add_child(pos_dropdown)
	chan_config_hbox.add_child(color_dropdown)
	return chan_config_hbox

# Receiving Dictionary[channel_name] = <Guidot_Data Object>
func _on_data_selected(sel_data_array: Dictionary) -> void:
	# Clear the vbox from the previously selected label
	for n in sub_data_vbox.get_children():
		sub_data_vbox.remove_child(n)

	# This will be used by the time series graph to query for the data of each respective channel name
	self.selected_data = sel_data_array

	# Populate selected labels
	for chan_name in sel_data_array.keys():
		var hbox: HBoxContainer = self._create_channel_config_name(chan_name, sel_data_array[chan_name])
		sub_data_vbox.add_child(hbox)

func get_available_gd_server() -> Array[String]:
	var gd_servers: Array[Node] = self.get_tree().get_nodes_in_group(Guidot_Common._server_group_name)
	var gd_servers_str: Array[String]

	# Returns the name of the server
	available_server.clear()
	for server in gd_servers:
		# Stores the respective name as key for node, to make it easy to access later
		available_server[server.name] = server
		gd_servers_str.append(server.name)

	return gd_servers_str

func get_selected_server() -> Guidot_Data_Server:
	self.curr_server_node = self.available_server[self._get_dropdown_selected_id()]
	return self.curr_server_node
	
func _ready() -> void:
	super._ready()
	self.show_panel()

	var vbox: VBoxContainer = VBoxContainer.new()
	self.add_child_to_container(vbox)

	# All server configuration settings
	server_selection = Guidot_Utils.create_dropdown_selection_row("Server Node", self.get_available_gd_server(), Vector2(200, 20))

	var margin_cont1: MarginContainer = MarginContainer.new()
	var subscribe_data_button: Button = Button.new()
	margin_cont1.add_child(subscribe_data_button)
	margin_cont1.add_theme_constant_override("margin_left", 10)
	margin_cont1.add_theme_constant_override("margin_right", 10)
	margin_cont1.add_theme_constant_override("margin_bottom", 10)
	subscribe_data_button.text = "+ Subscribe to data"
	subscribe_data_button.pressed.connect(self._on_subscribe_pressed)

	sub_data_scroll_cont.custom_minimum_size = Vector2(50, 300)
	sub_data_scroll_cont.add_child(sub_data_vbox)

	vbox.add_child(server_selection)
	vbox.add_child(margin_cont1)
	vbox.add_child(sub_data_scroll_cont)
