@tool
class_name Guidot_Wizard
extends Guidot_Movable_Panel

signal config_tree_configured(branch_name: String)

@onready var _menu_vbox: VBoxContainer = VBoxContainer.new()
@onready var _filter_prop_line_edit: LineEdit = LineEdit.new()
@onready var _wizard_panel_cont: PanelContainer = PanelContainer.new()
@onready var _menu_tab_cont: TabContainer = TabContainer.new()
@onready var _graph_config_cont: ScrollContainer = ScrollContainer.new()
@onready var _data_subscriber_cont: ScrollContainer = ScrollContainer.new()

# VBox for graph configurator
@onready var _graph_config_vbox = VBoxContainer.new()

# Alias for Guidot_Base_Setting
# Not to be used for overriding any base class Guidot_Base_Setting provides
class _GBS extends Guidot_Base_Setting:
	pass

@onready var SelectionType = _GBS.SelectionType

@onready var config_tree: Dictionary = {}

# Helps with storing the HBoxContainer object of each configuration to allow us to hide/unhide
# the objects when not needed
var _internal_config_tree: Dictionary

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

func _create_checkbox_button(def_val: bool) -> CheckBox:
	var checkbox: CheckBox = CheckBox.new()
	checkbox.text = "On"
	checkbox.button_pressed = def_val
	checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var checkbox_color: Color = Guidot_Utils.get_guidot_base_color()
	var checkbox_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(checkbox_color, checkbox_color)
	checkbox.add_theme_stylebox_override("normal", checkbox_stylebox)
	checkbox.add_theme_stylebox_override("pressed", checkbox_stylebox)

	var empty_stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
	checkbox.add_theme_stylebox_override("focus", empty_stylebox)

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
	slider.value = def_val
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var slider_highlight_color: Color = Color.SKY_BLUE
	var slider_highlight_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(slider_highlight_color,
		slider_highlight_color, [-1, -1, -1, -1], [0, 0, 0, 0], [4, 4, 4, 4])
	slider.add_theme_stylebox_override("grabber_area_highlight", slider_highlight_stylebox)
	return slider
	

func _create_config_row(config_name: String, full_key_name: String, config_dict: Dictionary) -> HBoxContainer:
	var config_hbox: HBoxContainer = HBoxContainer.new()
	var config_label: Label = self._create_label(config_name, false, Guidot_Utils.get_color("gd_black"), true)
	# config_label.text = config_name
	config_hbox.add_theme_constant_override("separation", -1)
	config_hbox.add_child(config_label)

	var def_val = config_dict[_GBS.value_key]
	var selection_type: _GBS.SelectionType = config_dict[_GBS.selection_type_key]
	
	match (selection_type):

		_GBS.SelectionType.CHECKBOX:
			var checkbox: CheckBox = self._create_checkbox_button(def_val)
			checkbox.pressed.connect(self._on_checkbox_pressed.bind(checkbox, full_key_name))
			config_hbox.add_child(checkbox)

		_GBS.SelectionType.LINE_EDIT_FLOAT:
			var line_edit: LineEdit = self._create_line_edit(str(def_val))
			line_edit.text_submitted.connect(self._on_line_edit_float_change.bind(full_key_name))

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

func _on_slider_value_changed(value: float, branch_name: String):
	# Making use of the line edit function but having to convert the float into string to ensure its compatible
	# which the function then converts this value back from string to float
	# Stupid, I know, dont ask, I could have just duplicate the function itself, but I'm lazy
	# Unless I see bottlenecks with this method, then this is fine
	self._on_line_edit_float_change(str(value), branch_name)

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
func _set_config_tree_value(dict: Dictionary, path: Array, value: Variant) -> void:
	
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
	self._set_config_tree_value(self.config_tree, branch_name.rsplit("."), cbox.button_pressed)	
	self.config_tree_configured.emit(branch_name)
	self.log(LOG_DEBUG, ["Guidot Wizard config:", self.config_tree])

func _on_line_edit_float_change(new_text: String, branch_name: String) -> void:
	
	var value: float
	if (new_text.is_valid_float()):
		value = new_text.to_float()
		self.log(LOG_DEBUG, [branch_name, " value changed to ", value])
		self._set_config_tree_value(self.config_tree, branch_name.rsplit("."), value) 
	else:
		self.log(LOG_WARNING, [branch_name, "expects float. Instead", new_text, "received."])

	self.config_tree_configured.emit(branch_name)

# enum_ref stores the reference to the actual enumeration so we can keep back reference the actual enumeration value
# once the index has been selected
func _on_dropdown_selected(index: int, dropdown: OptionButton, branch_name: String, enum_ref: Variant):	
	var dropdown_selection: String = dropdown.get_item_text(index)
	var selected_enum: int = enum_ref[dropdown_selection]
	self.log(LOG_DEBUG, ["Selected enum is", dropdown_selection, "(", selected_enum, ")"])
	self._set_config_tree_value(self.config_tree, branch_name.rsplit("."), selected_enum)
	self.config_tree_configured.emit(branch_name)

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
				var final_key: String = nested_key
				var hbox_obj: HBoxContainer = self._create_config_row(key, final_key, config_tree[key])
				self._internal_config_tree[final_key] = hbox_obj

			else:
				# This is a nested group node (not configurable directly, but contains sub-items)
				if (depth > 0):
					var button: Button = self._create_config_button(key)
					button.pressed.connect(self._on_config_button_pressed.bind(key, button, nested_key))
					self._graph_config_vbox.add_child(button)

				# Recurse into the nested group
				self._update_graph_config_tree(config_tree[key], depth + 1, nested_key)

		elif (key_type == TYPE_STRING):
			var label = self._create_label(config_tree[key], true)
			self._graph_config_vbox.add_child(label)

func update_config_tree(config_tree: Dictionary) -> void:
	self.config_tree = config_tree

	for child_node in self._graph_config_vbox.get_children():
		child_node.queue_free()

	self._update_graph_config_tree(self.config_tree)
	self.visible = true

func _ready() -> void:
	super._ready()
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
	self._data_subscriber_cont.name = "Data Subscriber"
	self._data_subscriber_cont.add_theme_stylebox_override("panel", base_stylebox)

	self._graph_config_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	self._graph_config_vbox.add_theme_constant_override("separation", 3)
	self._graph_config_cont.add_child(self._graph_config_vbox)

	var _data_sub_vbox = VBoxContainer.new()
	self._data_subscriber_cont.add_child(_data_sub_vbox)

	self._menu_tab_cont.add_child(self._graph_config_cont)
	self._menu_tab_cont.add_child(self._data_subscriber_cont)
	self._menu_vbox.add_child(_wizard_panel_cont)

	var config_tree: Dictionary = {}

	_panel_space.add_child(_menu_vbox)

	self.add_to_group(Guidot_Common._wizard_group_name)

var j: int = 0
enum SomeRandom  {
	HELLO = -1,
	GOOD_MORNING,
}

func _process(delta: float) -> void:
	super._process(delta)

	if (j == 0):
		config_tree = {
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

		self._update_graph_config_tree(config_tree)
		j += 1

func _input(event: InputEvent) -> void:
	super._input(event)
