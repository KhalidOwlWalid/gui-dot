@tool
class_name Guidot_Wizard
extends Guidot_Movable_Panel

signal config_tree_configured(branch_name: String)
signal subscribe_to_data(subscribe: bool, channel_name: String)
signal axis_assignment_changed(channel_name: String, axis_name: String)
signal line_color_changed

@onready var _menu_vbox: VBoxContainer = VBoxContainer.new()
@onready var _filter_prop_line_edit: LineEdit = LineEdit.new()
@onready var _wizard_panel_cont: PanelContainer = PanelContainer.new()
@onready var _menu_tab_cont: TabContainer = TabContainer.new()
@onready var _graph_config_cont: ScrollContainer = ScrollContainer.new()
@onready var _data_subscriber_cont: ScrollContainer = ScrollContainer.new()
@onready var _axis_assignment_cont: ScrollContainer = ScrollContainer.new()
@onready var _data_inspector_cont: ScrollContainer = ScrollContainer.new()
@onready var _debugger_cont: ScrollContainer = ScrollContainer.new()

# VBox for graph configurator
@onready var _graph_config_vbox = VBoxContainer.new()
@onready var _data_sub_vbox = VBoxContainer.new()
@onready var _data_inspector_vbox = VBoxContainer.new()
@onready var _debugger_vbox = VBoxContainer.new()

# Wizard helper node
@onready var _guidot_color_picker: Guidot_Color_Picker = Guidot_Color_Picker.new()
@onready var _guidot_error_popup: Guidot_Error_Popup = Guidot_Error_Popup.new()

# Alias for Guidot_Base_Setting
# Not to be used for overriding any base class Guidot_Base_Setting provides
class _GBS extends Guidot_Base_Setting:
	pass

@onready var SelectionType = _GBS.SelectionType

@onready var wizard_config_tree: Dictionary = {}
@onready var wizard_subscribed_data = []

# Helps with storing the HBoxContainer object of each configuration to allow us to hide/unhide
# the objects when not needed
var _internal_config_tree: Dictionary
var _data_index_tree: Dictionary

@onready var _axis_assignment_vbox: VBoxContainer = VBoxContainer.new()

# map channel_name -> axis value (Guidot_Y_Axis_Canvas.AxisPosition)
var _axis_assignments: Dictionary = {}

# Array of available axis positions from the focused graph
var _available_axis_positions: Array = []

class DataSubscriber:
	
	# Stores the server registry as parent dictionary
	# Nested then by groups, and then nodes. The hierarchy looks as follows
	# Server -> Groups -> Nodes
	var _server_manager: Dictionary = {}

	func append_server(server: Guidot_Data_Server) -> void:
		self._server_manager[server] = server

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, self.name, msg)

func capitalize_words(words_with_delim: String, delimiter: String = "_") -> String:
	var words: Array = words_with_delim.rsplit("_")
	var new_config_label: String
	for word in words:
		new_config_label = new_config_label + word[0].to_upper() + word.substr(1, -1) + " "
	return new_config_label


func _create_config_label(config_label: String, center_text: bool = false, capitalize: bool = true) -> Label:
	var label1: Label = Label.new()

	# Capitalize the first letter of each word of the header
	var new_config_label: String
	if (capitalize):
		new_config_label = self.capitalize_words(config_label)
	else:
		new_config_label = config_label

	label1.text = new_config_label
	label1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	if center_text:
		label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label1

func _create_config_button(config_label: String) -> Button:
	var button1: Button = Button.new()
	button1.text = "⇓" + self.capitalize_words(config_label)
	button1.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Default button style (Replicating Godot's UI style)
	var normal_color: Color = 1.3 * Guidot_Utils.get_color("gd_black")
	var pressed_color: Color = 0.85 * Guidot_Utils.get_color("graph_settings_label")
	var normal_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(normal_color, normal_color, [5, -1, -1, -1])
	var pressed_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(pressed_color, pressed_color, [5, -1, -1, -1])
	button1.add_theme_stylebox_override("normal", normal_stylebox)
	button1.add_theme_stylebox_override("hover", pressed_stylebox)
	button1.add_theme_stylebox_override("hover_pressed", pressed_stylebox)
	button1.add_theme_stylebox_override("pressed", pressed_stylebox)
	var empty_stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
	button1.add_theme_stylebox_override("focus", empty_stylebox)

	return button1

func _create_label(config_header: String, center_text: bool = false, color: Color = Guidot_Utils.get_color("gd_black"), capitalize: bool = true) -> Label:
	var label1: Label = self._create_config_label(config_header, center_text, capitalize)
	var label_color: Color = color
	var label_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(label_color, label_color, [5, -1, -1, -1],
		[0, 0, 0, 0], [5, 5, 5, 5])
	label1.add_theme_stylebox_override("normal", label_stylebox)
	return label1

func _create_checkbox_button(def_val: bool, text: String = "") -> CheckBox:
	var checkbox: CheckBox = CheckBox.new()
	checkbox.text = text
	checkbox.button_pressed = def_val
	checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var checkbox_color: Color = Guidot_Utils.get_guidot_base_color()
	var checkbox_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(checkbox_color, checkbox_color)
	checkbox.add_theme_stylebox_override("normal", checkbox_stylebox)
	checkbox.add_theme_stylebox_override("pressed", checkbox_stylebox)

	var empty_stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
	checkbox.add_theme_stylebox_override("focus", empty_stylebox)
	checkbox.add_theme_stylebox_override("hover", empty_stylebox)
	checkbox.add_theme_stylebox_override("hover_pressed", empty_stylebox)

	return checkbox

func _create_line_edit(def_val: String) -> LineEdit:
	var line_edit: LineEdit = LineEdit.new()
	# Move the caret a bit inwards to allow it to be seen
	line_edit.caret_column = 3
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line_edit_color: Color = Guidot_Utils.get_color("wizard_line_edit")
	var line_edit_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(line_edit_color, line_edit_color)
	line_edit_stylebox.expand_margin_left = 5
	line_edit.add_theme_stylebox_override("normal", line_edit_stylebox)

	var focus_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(line_edit_color, line_edit_color)
	focus_stylebox.expand_margin_left = 5
	focus_stylebox.set_border_width_all(1)
	focus_stylebox.border_color = Color.SKY_BLUE
	line_edit.add_theme_stylebox_override("focus", focus_stylebox)
	line_edit.caret_blink = true
	line_edit.text = def_val

	return line_edit

func _create_dropdown_selection(def_val: Variant, config_dict: Dictionary):
	var dropdown: OptionButton = OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var dropdown_color: Color = Guidot_Utils.get_color("wizard_line_edit")
	var dropdown_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(dropdown_color, dropdown_color)

	dropdown.add_theme_stylebox_override("normal", dropdown_stylebox)
	dropdown.add_theme_stylebox_override("hover", dropdown_stylebox)

	var focus_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(dropdown_color, dropdown_color)
	focus_stylebox.expand_margin_left = 5
	focus_stylebox.set_border_width_all(1)
	focus_stylebox.border_color = Color.SKY_BLUE
	dropdown.add_theme_stylebox_override("focus", focus_stylebox)
	
	for selection in config_dict[_GBS.dropdown_selection_key]:
		dropdown.add_item(selection)

	# Note: This hack had to be done since the y-axis position enumeration contains negative values
	# OptionButton does not indexed with negative values and will start from 0 by default unless specified through the use of index in the add_item
	# function
	# This hack allows me to still utilize the negative numbers, and requires a reverse search to set the correct default value for the dropdown
	# menu
	var val_to_select: String = config_dict[_GBS.enum_selection_key].find_key(def_val)
	dropdown.select(config_dict[_GBS.dropdown_selection_key].find(val_to_select))
	
	return dropdown

func _create_slider(def_val: float, min_val: float, max_val: float, step: float = 1) -> HSlider:
	var slider: HSlider = HSlider.new()
	# NOTE
	# Do not set the value until you have set all of the properties of the slider
	# One bug that took awhile to solve was that the slider does not reflect the default value and that is due to the fact that, the slider's
	# default step is 1, and setting anything that is not of increment of 1, will cause it to round it down (e.g. setting 0.1 will round it down
	# to 0), hence the bug, will cause the slider to either be 0 or 1
	# value needs to be set last as to not get overriden by the slider's properties
	slider.step = step
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = def_val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var slider_highlight_color: Color = Color.SKY_BLUE
	var slider_highlight_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(slider_highlight_color,
		slider_highlight_color, [-1, -1, -1, -1], [0, 0, 0, 0], [4, 4, 4, 4])
	slider.add_theme_stylebox_override("grabber_area_highlight", slider_highlight_stylebox)
	return slider
	

func _create_config_row(config_name: String, full_key_name: String, config_dict: Dictionary) -> HBoxContainer:
	var config_hbox: HBoxContainer = HBoxContainer.new()
	# Add space to show emphasis on the config being the leaf of the branch
	var spacer_label: Label = Label.new()
	spacer_label.text = "   "
	var config_label: Label = self._create_label(config_name, false, Guidot_Utils.get_color("gd_black"), true)
	# config_label.text = config_name
	config_hbox.add_theme_constant_override("separation", -1)
	config_hbox.add_child(spacer_label)
	config_hbox.add_child(config_label)

	var def_val = config_dict[_GBS.value_key]
	var selection_type: _GBS.SelectionType = config_dict[_GBS.selection_type_key]
	
	match (selection_type):

		_GBS.SelectionType.CHECKBOX:
			var checkbox: CheckBox = self._create_checkbox_button(def_val, "On")
			checkbox.pressed.connect(self._on_checkbox_pressed.bind(checkbox, full_key_name))
			config_hbox.add_child(checkbox)

		_GBS.SelectionType.LINE_EDIT_FLOAT:
			var line_edit: LineEdit = self._create_line_edit(str(def_val))
			line_edit.text_submitted.connect(self._on_line_edit_float_change.bind(full_key_name, line_edit, config_dict))

			config_hbox.add_child(line_edit)

		_GBS.SelectionType.DROPDOWN:
			var dropdown: OptionButton = self._create_dropdown_selection(def_val, config_dict)
			dropdown.item_selected.connect(self._on_dropdown_selected.bind(dropdown, full_key_name, config_dict[_GBS.enum_selection_key]))
			config_hbox.add_child(dropdown)

		_GBS.SelectionType.SLIDER:

			var min_val = config_dict[_GBS.min_value_key]
			var max_val = config_dict[_GBS.max_value_key]
			var step = config_dict[_GBS.step_key]
			var slider: Slider = self._create_slider(def_val, min_val, max_val, step)
			slider.value_changed.connect(self._on_slider_value_changed.bind(full_key_name))
			config_hbox.add_child(slider)

		_:
			pass

	self._graph_config_vbox.add_child(config_hbox)
	return config_hbox

func _on_slider_value_changed(value: float, branch_name: String) -> void:
	# Making use of the line edit function but having to convert the float into string to ensure its compatible
	# which the function then converts this value back from string to float
	# Stupid, I know, dont ask, I could have just duplicate the function itself, but I'm lazy
	# Unless I see bottlenecks with this method, then this is fine
	# self._on_line_edit_float_change(str(value), branch_name, config_dict)
	Guidot_Wizard.set_config_tree_value(self.wizard_config_tree, branch_name.rsplit("."), value) 
	self.config_tree_configured.emit(branch_name, value)

func _on_config_button_pressed(key_name: String, button: Button, base_branch_name: String) -> void:

	# Iterate through the internal config tree list which contains the HBoxContainer object of the configurator
	# This allows us to access the object directly and hide or unhide it
	var visible: bool
	for config_key in self._internal_config_tree.keys():
		if (base_branch_name in config_key):
			self._internal_config_tree[config_key].visible = !self._internal_config_tree[config_key].visible
			visible = self._internal_config_tree[config_key].visible
			self.log(LOG_DEBUG, ["Toggling ", config_key, " visibility due to ", base_branch_name, " button pressed"])

	key_name = self.capitalize_words(key_name)
	if (not visible):
		button.text = "⇒ " + key_name
	else:
		button.text = "⇓ " + key_name


# path argument expects a valid full key path (nested dictionary) that exist in the dictionary
# For instance, foo = {"bar": {"new_val": 1}}
# The full path for new_val would be "bar.new_val" hence, it expects ["bar", "new_val"]
static func set_config_tree_value(dict: Dictionary, path: Array, value: Variant) -> void:
	
	# Handles config tree value assignment
	# Iteratively loops to the correct key before assigning the value
	var current: Variant = dict
	for i in range(path.size() - 1):
		current = current[path[i]]

	# TODO: Perform checks wether the assigned value is valid or not
	# Reminder: The structure of the array for any settings are: [SelectionType, value]
	# Hence, accessing current[1] changes the "value" of the settings
	current[path[-1]][_GBS.value_key] = value

func _on_checkbox_pressed(cbox: CheckBox, branch_name: String) -> void:
	Guidot_Wizard.set_config_tree_value(self.wizard_config_tree, branch_name.rsplit("."), cbox.button_pressed)	
	self.config_tree_configured.emit(branch_name, cbox.button_pressed)
	# self.log(LOG_DEBUG, ["Guidot Wizard config:", self.wizard_config_tree])

func _on_line_edit_float_change(new_text: String, branch_name: String, line_edit: LineEdit, config_dict: Dictionary) -> void:
	
	var value: float
	var min_val: float = config_dict[_GBS.min_value_key]
	var max_val: float = config_dict[_GBS.max_value_key]
	if (new_text.is_valid_float()):
		value = new_text.to_float()

		if (value < min_val or value > max_val):
			value = config_dict[_GBS.value_key]
			self.log(LOG_DEBUG, [branch_name, "new value (", value, ") exceeded the min (", min_val, ") and max (", max_val, ")"])
			line_edit.text = str(value)
		else:
			Guidot_Wizard.set_config_tree_value(self.wizard_config_tree, branch_name.rsplit("."), value) 
			self.config_tree_configured.emit(branch_name, value)
			self._update_axis_assignment_ui()
			self.log(LOG_INFO, [branch_name, " value changed to ", value])
	else:
		self.log(LOG_WARNING, [branch_name, "expects float. Instead", new_text, "received."])

# enum_ref stores the reference to the actual enumeration so we can keep back reference the actual enumeration value
# once the index has been selected
func _on_dropdown_selected(index: int, dropdown: OptionButton, branch_name: String, enum_ref: Variant):	
	var dropdown_selection: String = dropdown.get_item_text(index)
	var selected_enum: int = enum_ref[dropdown_selection]
	self.log(LOG_DEBUG, ["Selected enum is", dropdown_selection, "(", selected_enum, ")"])
	Guidot_Wizard.set_config_tree_value(self.wizard_config_tree, branch_name.rsplit("."), selected_enum)
	self.config_tree_configured.emit(branch_name, selected_enum)

func _on_data_sub_cbox_pressed(cbox: CheckBox, channel_name: String) -> void:
	# Update local subscribed list and emit subscription change
	var subscribed: bool = cbox.button_pressed
	if subscribed:
		if channel_name not in self.wizard_subscribed_data:
			self.wizard_subscribed_data.append(channel_name)
	else:
		self.wizard_subscribed_data.erase(channel_name)
	self.subscribe_to_data.emit(subscribed, channel_name)
	self._update_axis_assignment_ui()

func update_data_inspector_ui(cursor_info: Dictionary) -> void:
	if not self._data_inspector_vbox:
		return
	# Clear existing entries
	for child in self._data_inspector_vbox.get_children():
		self._data_inspector_vbox.remove_child(child)
		child.queue_free()
	self._data_inspector_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var horizontal_spacer_label: Label = Label.new()
	horizontal_spacer_label.text = "   "
	var channel_header_label: Label = self._create_label("Data Channel Name", true, Guidot_Utils.get_color("graph_settings_label"), false)
	var channel_value_label: Label = self._create_label("Cursor Value", true, Guidot_Utils.get_color("graph_settings_label"), false)

	header_row.add_child(horizontal_spacer_label)
	header_row.add_child(channel_header_label)
	header_row.add_child(channel_value_label)
	self._data_inspector_vbox.add_child(header_row)

	for channel_name in cursor_info.keys():
		var row: HBoxContainer = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)

		var hor_spacer_label1: Label = Label.new()
		hor_spacer_label1.text = "   "

		row.add_child(hor_spacer_label1)

		var channel_label: Label = Label.new()
		channel_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		channel_label.text = channel_name
		row.add_child(channel_label)

		var cursor_value_label: Label = Label.new()
		cursor_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cursor_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cursor_value_label.text = str(cursor_info[channel_name])
		row.add_child(cursor_value_label)

		self._data_inspector_vbox.add_child(row)

func _update_axis_assignment_ui() -> void:
	# Ensure vbox exists
	if not self._axis_assignment_vbox:
		return
	# Clear existing entries
	for child in self._axis_assignment_vbox.get_children():
		self._axis_assignment_vbox.remove_child(child)
		child.queue_free()
	self._axis_assignment_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Populate entries for each subscribed channel
	for channel_name in self.wizard_subscribed_data:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var horizontal_spacer_label: Label = Label.new()
		horizontal_spacer_label.text = "       "
		row.add_child(horizontal_spacer_label)

		var label: Label = Label.new()
		label.text = channel_name
		label.custom_minimum_size = Vector2(160, 0)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var dropdown: OptionButton = OptionButton.new()
		dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# populate with only available axis positions from the graph
		if self._available_axis_positions.is_empty():
			# Fallback: show all axes if none specified
			var axis_pos: int = Guidot_Y_Axis_Canvas.AxisPosition.PRIMARY_LEFT
			for axis_name in Guidot_Y_Axis_Canvas.AxisPosition.keys():
				var axis_val: int = Guidot_Y_Axis_Canvas.AxisPosition[axis_name]
				dropdown.add_item(str(axis_pos))
		else:
			# Show only available axes
			for axis_pos in self._available_axis_positions:
				var axis_name_str: String = Guidot_Y_Axis_Canvas.get_axis_id_str_from_value(axis_pos)
				dropdown.add_item(str(axis_pos))

		# select current assignment if present
		var assigned: int = Guidot_Y_Axis_Canvas.AxisPosition.PRIMARY_LEFT
		if channel_name in self._axis_assignments:
			assigned = int(self._axis_assignments[channel_name])
		# find index for assigned id
		for i in range(dropdown.get_item_count()):
			if dropdown.get_item_id(i) == assigned:
				dropdown.select(i)
				break

		dropdown.item_selected.connect(self._on_axis_dropdown_selected.bind(dropdown, channel_name))

		# TODO: Hardcoding the first server that we see, since I have not refactor the way that server and data works
		var selected_server: Guidot_Data_Server = self.get_tree().get_nodes_in_group(Guidot_Common._server_group_name)[0]
		var channel_node: Guidot_Data = selected_server.get_node_id_with_channel_name(channel_name)
		var curr_chan_node_color: Color = channel_node.get_line_color()

		var color_button: Button = Button.new()
		color_button.text = ""
		color_button.custom_minimum_size = Vector2(30, 0)

		var normal_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(curr_chan_node_color, Color.WHITE)
		var hover_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(curr_chan_node_color, Color.WHITE, [-1, -1, -1, -1],
			[2, 2, 2, 2], [0, 0, 0, 0])
		color_button.add_theme_stylebox_override("normal", normal_stylebox)
		color_button.add_theme_stylebox_override("hover", hover_stylebox)
		color_button.pressed.connect(self._on_color_pick_pressed.bind(channel_node, color_button))

		row.add_child(dropdown)
		row.add_child(color_button)
		self._axis_assignment_vbox.add_child(row)

func _on_color_changed(selected_color: Color, channel_node: Guidot_Data, color_button: Button) -> void:
	channel_node.set_line_color_rgba(selected_color)

	var curr_chan_node_color: Color = channel_node.get_line_color()
	var normal_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(curr_chan_node_color, Color.WHITE)
	var hover_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(curr_chan_node_color, Color.WHITE, [-1, -1, -1, -1],
		[2, 2, 2, 2], [0, 0, 0, 0])
	color_button.add_theme_stylebox_override("normal", normal_stylebox)
	color_button.add_theme_stylebox_override("hover", hover_stylebox)

	self.line_color_changed.emit()
	 
func _on_color_pick_pressed(channel_node: Guidot_Data, color_button: Button) -> void:
	# Globally, there should only be one color picker
	# self._guidot_color_picker = self.get_tree().get_nodes_in_group(Guidot_Common._color_picker_name)[0]
	
	if (not self._guidot_color_picker.visible):
		self._guidot_color_picker.visible = true

	var color_picker_cb: Callable = self._guidot_color_picker.get_callback()
	if (color_picker_cb == null):
		color_picker_cb = Callable(self, "_on_color_changed").bind(channel_node, color_button)
		self._guidot_color_picker.set_callback(color_picker_cb)
	else:
		self._guidot_color_picker.node().color_changed.disconnect(self._on_color_changed)
		color_picker_cb = Callable(self, "_on_color_changed").bind(channel_node, color_button)
		self._guidot_color_picker.set_callback(color_picker_cb)
	
	# REFACTOR: Hardcoding the first server that we see, since I have not refactor the way that server and data works. FIX
	self._guidot_color_picker.set_color(channel_node.get_line_color())
	self._guidot_color_picker.node().color_changed.connect(color_picker_cb)

func _on_axis_dropdown_selected(index: int, dropdown: OptionButton, channel_name: String) -> void:
	var axis_id_str: String = dropdown.get_item_text(index)
	var axis_id_enum_str: String = Guidot_Y_Axis_Canvas.get_axis_id_str_from_value(int(axis_id_str))
	self._axis_assignments[channel_name] = int(axis_id_str)
	self.log(LOG_INFO, ["Axis assignment:", channel_name, "->", axis_id_enum_str])
	self.axis_assignment_changed.emit(channel_name, axis_id_enum_str)

func _create_group_subheader(group_name: String) -> Button:
	var btn: Button = self._create_config_button(group_name)
	btn.text = "   " + btn.text
	return btn

func _wrap_with_indent(control: Control, indent: String) -> HBoxContainer:
	var hbox: HBoxContainer = HBoxContainer.new()
	var spacer: Label = Label.new()
	spacer.text = indent
	hbox.add_child(spacer)
	hbox.add_child(control)
	return hbox

func _on_collapsible_header_pressed(button: Button, children: Array, label_text: String) -> void:
	var any_visible: bool = false
	for child in children:
		if child.visible:
			any_visible = true
			break
	var new_visibility: bool = not any_visible
	for child in children:
		child.visible = new_visibility
	var capitalized: String = self.capitalize_words(label_text)
	if new_visibility:
		button.text = "⇓ " + capitalized
	else:
		button.text = "⇒ " + capitalized

func _on_group_select_all_pressed(select_all_cbox: CheckBox, channel_cboxes: Array) -> void:
	var subscribe: bool = select_all_cbox.button_pressed
	for cbox in channel_cboxes:
		cbox.button_pressed = subscribe
		self._on_data_sub_cbox_pressed(cbox, cbox.text)

func query_server_information() -> void:
	self._data_index_tree.clear()

	var i: int = 0
	for child_node in self._data_sub_vbox.get_children():
		# Skip the refresh button at index 0
		if (i == 0):
			pass
		else:
			child_node.queue_free()
		i += 1

	var gd_servers: Array[Node] = self.get_tree().get_nodes_in_group(Guidot_Common._server_group_name)

	for server in gd_servers:
		self._data_index_tree[server] = {}
		for source in server.get_all_registered_clients().values():
			self.log(LOG_DEBUG, ["Server:", server.get_custom_name(), "has source:", source.get_custom_name()])

			var source_ui_nodes: Array = []
			var source_button: Button = self._create_config_button(source.get_custom_name())
			self._data_sub_vbox.add_child(source_button)

			for group in source.get_all_data_groups():
				var group_ui_nodes: Array = []
				var group_cboxes: Array = []

				var group_btn: Button = self._create_group_subheader(group.get_name())
				self._data_sub_vbox.add_child(group_btn)
				source_ui_nodes.append(group_btn)

				var select_all_cbox: CheckBox = self._create_checkbox_button(false, "Select All")
				var select_all_row: HBoxContainer = self._wrap_with_indent(select_all_cbox, "      ")
				self._data_sub_vbox.add_child(select_all_row)
				group_ui_nodes.append(select_all_row)
				source_ui_nodes.append(select_all_row)

				for channel in group.get_channels():
					var cbox_state: bool = channel.get_name() in self.wizard_subscribed_data
					var cbox: CheckBox = self._create_checkbox_button(cbox_state, channel.get_name())
					cbox.pressed.connect(self._on_data_sub_cbox_pressed.bind(cbox, channel.get_name()))
					var cbox_row: HBoxContainer = self._wrap_with_indent(cbox, "         ")
					self._data_sub_vbox.add_child(cbox_row)
					group_ui_nodes.append(cbox_row)
					source_ui_nodes.append(cbox_row)
					group_cboxes.append(cbox)

				select_all_cbox.pressed.connect(
					self._on_group_select_all_pressed.bind(select_all_cbox, group_cboxes)
				)
				group_btn.pressed.connect(
					self._on_collapsible_header_pressed.bind(group_btn, group_ui_nodes, group.get_name())
				)

			for channel in source.get_ungrouped_channels():
				var cbox_state: bool = channel.get_name() in self.wizard_subscribed_data
				var cbox: CheckBox = self._create_checkbox_button(cbox_state, channel.get_name())
				cbox.pressed.connect(self._on_data_sub_cbox_pressed.bind(cbox, channel.get_name()))
				var cbox_row: HBoxContainer = self._wrap_with_indent(cbox, "   ")
				self._data_sub_vbox.add_child(cbox_row)
				source_ui_nodes.append(cbox_row)

			source_button.pressed.connect(
				self._on_collapsible_header_pressed.bind(source_button, source_ui_nodes, source.get_custom_name())
			)

# Currently, the graph config tree builder only supports up to level 1 depth of nesting
# so adding a nested dictionary inside another level 1 dictionary will simply add it to the same depth level
# Nested dictionary handling will be handled in future updates. For now, it is not the highest priority
func _update_graph_config_tree(config_tree: Dictionary, depth: int = 0, curr_key: String = ""):

	var full_key: String = ""
	for key in config_tree:

		# All keys at depth 0 are headers
		if (depth == 0):
			var label: Label = self._create_label(key, true, Guidot_Utils.get_color("graph_settings_label"))
			self._graph_config_vbox.add_child(label)
			curr_key = key
	
		var key_type: Variant.Type = typeof(config_tree[key])

		if (key_type == TYPE_DICTIONARY):

			var nested_key: String = curr_key
			if (not curr_key == key):
				nested_key = curr_key + "." + key

			if (config_tree[key].has_all(Guidot_Base_Setting.common_keys)):
				# This is a leaf node (user-configurable item)
				var full_path_key: String = nested_key
				var hbox_obj: HBoxContainer = self._create_config_row(key, full_path_key, config_tree[key])
				self._internal_config_tree[full_path_key] = hbox_obj
			else:
				# This is a nested group node (not configurable directly, but contains sub-items)
				if (depth > 0):
					var button: Button = self._create_config_button(key)
					button.pressed.connect(self._on_config_button_pressed.bind(key, button, nested_key))
					self._graph_config_vbox.add_child(button)

				# Recurse into the nested group
				self._update_graph_config_tree(config_tree[key], depth + 1, nested_key)

		elif (key_type == TYPE_STRING):
			var depth_spacer: String = "   "
			var label = self._create_label(config_tree[key], true)
			self._graph_config_vbox.add_child(label)

func update_available_axes(available_axes: Array):
	self._available_axis_positions = available_axes
	self._update_axis_assignment_ui()

func update_config_tree(config_tree: Dictionary, subscribed_data: Array) -> void:
	self.wizard_config_tree = config_tree
	# Ensure no duplicates in subscribed_data
	var unique_data: Array = []
	for item in subscribed_data:
		if item not in unique_data:
			unique_data.append(item)
	self.wizard_subscribed_data = unique_data
	# Store available axes for dropdown population
	for child_node in self._graph_config_vbox.get_children():
		child_node.queue_free()

	self._update_graph_config_tree(self.wizard_config_tree)
	self.query_server_information()
	# Refresh axis manager UI to reflect subscribed channels
	self._update_axis_assignment_ui()
	self.visible = true

func update_debugger_tree() -> void:
	pass

func show_error_popup(gd_error: Guidot_Error) -> void:
	self._guidot_error_popup.generate_popup(gd_error)
	self._guidot_error_popup.visible = true

func _ready() -> void:
	super._ready()
	# initialize internal structures
	self._internal_config_tree = {}
	self._data_index_tree = {}
	self.name = "Guidot Wizard"
	self.set_title_name(self.name)
	self.global_position = DisplayServer.screen_get_size()/2 - Vector2i(self.size/2)

	_filter_prop_line_edit.placeholder_text = "Filter Properties"
	self._menu_vbox.add_child(_filter_prop_line_edit)

	self._wizard_panel_cont.size_flags_vertical = Control.SIZE_EXPAND_FILL

	self._menu_cont_stylebox.bg_color = Guidot_Utils.get_guidot_base_color()
	self.set_margin_size(self._menu_cont_stylebox, 3)
	self._wizard_panel_cont.add_theme_stylebox_override("panel", self._menu_cont_stylebox)
	self._wizard_panel_cont.add_child(self._menu_tab_cont)

	self._graph_config_cont.name = "Graph settings"
	var base_color: Color = Guidot_Utils.get_guidot_base_color()
	var base_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(base_color, base_color)
	self._graph_config_cont.add_theme_stylebox_override("panel", base_stylebox)

	self._graph_config_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	self._graph_config_vbox.add_theme_constant_override("separation", 3)
	self._graph_config_cont.add_child(self._graph_config_vbox)

	var refresh_button: Button = self._create_config_button("Refresh")
	self._data_sub_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	self._data_sub_vbox.add_child(refresh_button)
	refresh_button.pressed.connect(self.query_server_information)
	self.query_server_information()
	self._data_subscriber_cont.add_child(self._data_sub_vbox)
	self._data_subscriber_cont.name = "Data Subscriber"
	self._data_subscriber_cont.add_theme_stylebox_override("panel", base_stylebox)

	self._axis_assignment_cont.add_child(self._axis_assignment_vbox)
	self._axis_assignment_cont.name = "Axis Assignment"
	self._axis_assignment_cont.add_theme_stylebox_override("panel", base_stylebox)

	self._data_inspector_cont.add_child(self._data_inspector_vbox)
	self._data_inspector_cont.name = "Data Inspector"
	self._data_inspector_cont.add_theme_stylebox_override("panel", base_stylebox)

	self._debugger_cont.add_child(self._debugger_vbox)
	self._debugger_cont.name = "Debugger"
	self._debugger_cont.add_theme_stylebox_override("panel", base_stylebox)

	self._menu_tab_cont.add_child(self._graph_config_cont)
	self._menu_tab_cont.add_child(self._data_subscriber_cont)
	self._menu_tab_cont.add_child(self._axis_assignment_cont)
	self._menu_tab_cont.add_child(self._data_inspector_cont)
	self._menu_tab_cont.add_child(self._debugger_cont)
	self._menu_vbox.add_child(_wizard_panel_cont)

	var config_tree: Dictionary = {}

	self.add_child_into_panel_space(self._menu_vbox)
	
	# This needs to be added on the root as we want to have this as a floating panel rather than it being constricted to
	# this node itself. If this is added as a child to this node, it will open within the domain of this node, and will
	# not be able to move around freely
	self.get_tree().root.add_child.call_deferred(self._guidot_color_picker)
	self.get_tree().root.add_child.call_deferred(self._guidot_error_popup)

	self.add_to_group(Guidot_Common._wizard_group_name)

var j: int = 0

func populate_fake_config_tree_entry() -> void:
	if (j == 0):
		wizard_config_tree = {
			"graph_node_ref": str(self),
			"graph_node_id": str(self.get_instance_id()),
			"graph_type": str(self.name),
			"global": {
				"primary_left": _GBS.create_selection_type(_GBS.SelectionType.LINE_EDIT_FLOAT, 10),
				"preferences_test": {
					"disable_hotkeys": _GBS.create_selection_type(_GBS.SelectionType.CHECKBOX, true),
					"opacity": _GBS.create_selection_type(_GBS.SelectionType.LINE_EDIT_FLOAT, 100),
					"graph_mode": _GBS.create_selection_type(_GBS.SelectionType.DROPDOWN, Guidot_Common.Graph_Buffer_Mode.FIXED,
						Guidot_Common.Graph_Buffer_Mode.keys(), Guidot_Y_Axis_Canvas.Graph_Buffer_Mode),
					"slider": _GBS.create_float_edit_type(_GBS.SelectionType.SLIDER, 10, 0, 100, 0.1),
				},
			},
			"local": {
				"primary_left": _GBS.create_selection_type(_GBS.SelectionType.LINE_EDIT_FLOAT, 10),
				"preferences": {
					"disable_hotkeys": _GBS.create_selection_type(_GBS.SelectionType.CHECKBOX, true),
					"opacity": _GBS.create_selection_type(_GBS.SelectionType.LINE_EDIT_FLOAT, 100),
					"graph_mode": _GBS.create_selection_type(_GBS.SelectionType.DROPDOWN, Guidot_Y_Axis_Canvas.AxisPosition.TERTIARY_LEFT, Guidot_Y_Axis_Canvas.AxisPosition.keys(), Guidot_Y_Axis_Canvas.AxisPosition),
				},

			},
		}

		self._update_graph_config_tree(wizard_config_tree)
		j += 1

func _process(delta: float) -> void:
	super._process(delta)
	# self.populate_fake_config_tree_entry()

func _input(event: InputEvent) -> void:
	super._input(event)

	if (event is InputEventKey and event.pressed):

		if (event.keycode == KEY_ESCAPE):
			# Pass an empty dictionary to clear the previously populated config tree
			self.log(LOG_INFO, ["Escape key pressed"])
			self.wizard_config_tree = {}
			self.wizard_subscribed_data = []
			self.update_config_tree(self.wizard_config_tree, self.wizard_subscribed_data)
			self.log(LOG_INFO, ["After update config tree"])
	
