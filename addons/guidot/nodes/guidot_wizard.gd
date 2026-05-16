@tool
class_name Guidot_Wizard
extends Guidot_Movable_Panel

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

@onready var config_tree: Dictionary = {
	"graph_node_ref": "<gd_node_ref>",
	"graph_node_id": "<Node_ID>",
	"graph_type": "Guidot_Time_Series_Graph",
	"global": {
		"preferences": {
			"disable_hotkeys": _GBS.create_selection_type(_GBS.SelectionType.CHECKBOX, false),
			"opacity": _GBS.create_selection_type(_GBS.SelectionType.LINE_EDIT, 100),
			"graph_mode": _GBS.create_selection_type(_GBS.SelectionType.DROPDOWN, 0),
		},
	},
}

var _internal_config_tree: Dictionary

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, self.name, msg)

func _create_config_label(config_label: String, center_text: bool = false) -> Label:
	var label1: Label = Label.new()
	label1.text = config_label
	label1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	if center_text:
		label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label1

func _create_config_button(config_label: String) -> Button:
	var button1: Button = Button.new()
	button1.text = "> " + config_label
	button1.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Default button style (Replicating Godot's UI style)
	var normal_color: Color = 1.3 * Guidot_Utils.get_color("gd_black")
	var pressed_color: Color = 1.05 * Guidot_Utils.get_color("graph_settings_label")
	var normal_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(normal_color, normal_color, [5, -1, -1, -1])
	var pressed_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(pressed_color, pressed_color, [5, -1, -1, -1])
	button1.add_theme_stylebox_override("normal", normal_stylebox)
	button1.add_theme_stylebox_override("hover", pressed_stylebox)
	button1.add_theme_stylebox_override("hover_pressed", pressed_stylebox)
	button1.add_theme_stylebox_override("pressed", pressed_stylebox)
	var empty_stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
	button1.add_theme_stylebox_override("focus", empty_stylebox)

	return button1

func _create_label(config_header: String, center_text: bool = false, color: Color = Guidot_Utils.get_color("gd_black")) -> Label:
	var label1: Label = self._create_config_label(config_header, center_text)
	var label_color: Color = color
	var label_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(label_color, label_color, [5, -1, -1, -1])
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

func _create_config_row(config_name: String, selection_type: _GBS.SelectionType, def_val):
	var config_hbox: HBoxContainer = HBoxContainer.new()
	var config_label: Label = self._create_label(config_name, false)
	config_label.text = config_name
	config_hbox.add_theme_constant_override("separation", -1)
	config_hbox.add_child(config_label)
	
	match (selection_type):

		_GBS.SelectionType.CHECKBOX:
			var checkbox: CheckBox = self._create_checkbox_button(def_val)
			config_hbox.add_child(checkbox)

		_:
			pass

	self._graph_config_vbox.add_child(config_hbox)

func _update_graph_config_tree(config_tree: Dictionary, depth: int = 0, curr_key: String = ""):

	var full_key: String = ""
	for key in config_tree:

		# All keys at depth 0 are headers
		if (depth == 0):
			var label: Label = self._create_label(key, true, Guidot_Utils.get_color("graph_settings_label"))
			self._graph_config_vbox.add_child(label)
	
		var key_type: Variant.Type = typeof(config_tree[key])

		if (key_type == TYPE_DICTIONARY):
			self.log(LOG_DEBUG, [key, "is a dictionary of depth ", depth])

			curr_key = key

			if (depth > 0):
				var button: Button = self._create_config_button(key)
				self._graph_config_vbox.add_child(button)
			self._update_graph_config_tree(config_tree[key], depth + 1, key)

		if (key_type == TYPE_ARRAY):

			var final_key: String = curr_key + "." + key
			self._create_config_row(key, config_tree[key][0], config_tree[key][1])
			self.log(LOG_DEBUG, [key, " is a setting ", depth])

			self.log(LOG_DEBUG, [final_key])

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
	self._data_subscriber_cont.name = "Data Subscriber"

	self._graph_config_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	self._graph_config_vbox.add_theme_constant_override("separation", -1)
	self._graph_config_cont.add_child(self._graph_config_vbox)

	var _data_sub_vbox = VBoxContainer.new()
	self._data_subscriber_cont.add_child(_data_sub_vbox)

	self._menu_tab_cont.add_child(self._graph_config_cont)
	self._menu_tab_cont.add_child(self._data_subscriber_cont)
	self._menu_vbox.add_child(_wizard_panel_cont)

	var config_tree: Dictionary = {}

	_panel_space.add_child(_menu_vbox)

	config_tree = {
	"graph_node_ref": "<gd_node_ref>",
	"graph_node_id": "<Node_ID>",
	"graph_type": "Guidot_Time_Series_Graph",
	"global": {
		"test1": _GBS.create_selection_type(_GBS.SelectionType.CHECKBOX, false),
		"preferences": {
			"disable_hotkeys": _GBS.create_selection_type(_GBS.SelectionType.CHECKBOX, true),
			"opacity": _GBS.create_selection_type(_GBS.SelectionType.LINE_EDIT, 100),
			"graph_mode": _GBS.create_selection_type(_GBS.SelectionType.DROPDOWN, 0),
		},
	},
	"local": {
		"preferences": {
			"disable_hotkeys": _GBS.create_selection_type(_GBS.SelectionType.CHECKBOX, false),
			"opacity": _GBS.create_selection_type(_GBS.SelectionType.LINE_EDIT, 100),
			"graph_mode": _GBS.create_selection_type(_GBS.SelectionType.DROPDOWN, 0),
		},
	},
	}

	self._update_graph_config_tree(config_tree)

func _process(delta: float) -> void:
	super._process(delta)

	# self._update_graph_config_tree(config_tree)

	# self._parse_config_tree(config_tree)

func _input(event: InputEvent) -> void:
	super._input(event)
