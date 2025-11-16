class_name Guidot_Data_Sub_Manager
extends Guidot_Panel2

signal data_selected

# Contains all the unique name of the currently available data to be selected from
@onready var _available_data: Dictionary = {
}

# Stores {<unique_name_string>: <Guidot_Data_Node_ID>}
@onready var _available_data_node_id: Dictionary = {
}

@onready var header: Label = Label.new()
@onready var apply_button: Button = Button.new()
@onready var search_bar: LineEdit = LineEdit.new()
@onready var scroll_container: ScrollContainer = ScrollContainer.new()
@onready var data_list_vbox: VBoxContainer = VBoxContainer.new()
@onready var close_button: Button = Button.new()

func get_available_data_options() -> Array[String]:
	var data_options: Array[String] = []

	for data_name in self._available_data.keys():
		data_options.append(data_name)

	return data_options

func get_selected_data() -> Dictionary:
	var sel_data_dict: Dictionary = {}
	
	for hbox in self.data_list_vbox.get_children():
		var cbox: CheckBox = hbox.get_child(0)
		var is_data_selected: bool = cbox.button_pressed
		var data_name: String = cbox.text

		# Ensure that if the user had previously selected the data, we maintain this
		if is_data_selected:
			sel_data_dict[data_name] = true
		else:
			sel_data_dict[data_name] = false

	return sel_data_dict

# client_nodes have a structure of {"client_name": <Guidot_Data_Client>}
func set_available_data_for_selection(client_nodes: Dictionary) -> void:
	# Get the currently selected data from the checkbox
	self._available_data = get_selected_data()

	# Clean up the previosly populated child
	for node in self.data_list_vbox.get_children():
		self.data_list_vbox.remove_child(node)

	# Go through the client ID manager, and get all available data channel from the client
	for client_node in client_nodes.values():
		var channel_list: Array[String]  = client_node.get_all_data_channel_name()
		for channel in channel_list:
			

			# If the user has previously select the data to be plotted, leave it
			# This ensures the user to not have to select the data they wish to plot again
			if (not self._available_data.has(channel) or not self._available_data[channel]):
				# Ensure we store a reference to the <Guidot_Data_Node_ID> for ease of reference later
				self._available_data_node_id[channel] = client_node.get_data_channel_node_id(channel)
				self._available_data[channel] = false

	self._populate_data_selection_vbox()

func _populate_data_selection_vbox() -> void:
	for key in self._available_data.keys():
		data_list_vbox.add_child(Guidot_Utils._create_checkbox_with_label(key, self._available_data[key]))

func _on_close_submenu_button_pressed() -> void:
	self.visible = false

func _on_apply_changes_pressed(selected_data: VBoxContainer) -> void:
	# Will store data that is selected using the checkbox
	var selected_data_dict: Dictionary = {}

	for hbox in selected_data.get_children():
		# The HBoxContainer consists of {CheckBox}
		var cbox: CheckBox = hbox.get_child(0)

		if cbox.button_pressed:
			# Get the unique data channel name from the checkbox
			var channel_name: String = cbox.text
			selected_data_dict[channel_name] = self._available_data_node_id[channel_name]
			
			# Save the current data selected by the user
			self._available_data[cbox.text] = cbox.button_pressed

	self.data_selected.emit(selected_data_dict)
	self.log(LOG_INFO, [selected_data_dict])

func set_container_size(new_size: Vector2) -> void:
	self.scroll_container.custom_minimum_size = new_size

func _ready() -> void:
	super._ready()

	self.hide_panel()

	self.custom_minimum_size = Vector2(300, 300)
	self.set_outline_color(Guidot_Utils.get_color("white"))

	var l_vbox1: VBoxContainer = VBoxContainer.new()
	self.add_child_to_container(l_vbox1)
	self.set_container_color(Guidot_Utils.get_color("gd_black"))

	# Header for data subscriber
	var l_hbox1: HBoxContainer = HBoxContainer.new()
	l_hbox1.add_child(header)	
	l_hbox1.add_child(close_button)

	var child_array: Array[Node] = [l_hbox1, apply_button, search_bar, scroll_container]

	for node in child_array:
		l_vbox1.add_child(node)

	# Setup the header
	header.text = "Data Subscriber Manager"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.custom_minimum_size = Vector2(300, 20)
	close_button.custom_minimum_size = Vector2(30, 20)
	close_button.text = "X"
	close_button.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_RIGHT)
	close_button.pressed.connect(self._on_close_submenu_button_pressed)
	scroll_container.custom_minimum_size = Vector2(self.size.x, 300)

	scroll_container.add_child(data_list_vbox)

	for key in self._available_data.keys():
		data_list_vbox.add_child(Guidot_Utils._create_checkbox_with_label(key, self._available_data[key]))

	self._populate_data_selection_vbox()

	apply_button.text = "Apply changes"
	apply_button.pressed.connect(self._on_apply_changes_pressed.bind(data_list_vbox))
