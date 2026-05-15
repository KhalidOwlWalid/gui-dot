# @tool
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

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, self.name, msg)

func _create_config_label(config_label: String) -> Label:
	var label1: Label = Label.new()
	label1.text = config_label
	label1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label1

# Recursively parses the config tree to build the UI
func _parse_config_tree(config_tree: Dictionary, depth: int  = 0) -> void:
	for key in config_tree:
		# print(key, typeof(config_tree[key]))
	
		var key_type: Variant.Type = typeof(config_tree[key])

		if (key_type == TYPE_DICTIONARY):
			self.log(LOG_DEBUG, [key, "is a dictionary of depth ", depth])
			self._parse_config_tree(config_tree[key], depth + 1)

		if (key_type == TYPE_ARRAY):
			self.log(LOG_DEBUG, [key, " is a setting ", depth])


func _update_graph_config_tree(config_tree: Dictionary):

	# Parse nested dictionary here to determine tree depths
	var test: Array = []
	var label1: Label = self._create_config_label("Global")

	test.append(label1)

	for label in test:
		self._graph_config_vbox.add_child(label)
		var label_color: Color = Guidot_Utils.get_color("graph_settings_label")
		var label_stylebox: StyleBoxFlat = Guidot_Stylebox.instantiate_flat_stylebox(label_color, label_color, [0, 0, 0, 0])
		label.add_theme_stylebox_override("normal", label_stylebox)

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
	self._graph_config_cont.add_child(self._graph_config_vbox)

	var _data_sub_vbox = VBoxContainer.new()
	self._data_subscriber_cont.add_child(_data_sub_vbox)

	self._menu_tab_cont.add_child(self._graph_config_cont)
	self._menu_tab_cont.add_child(self._data_subscriber_cont)
	self._menu_vbox.add_child(_wizard_panel_cont)

	var config_tree: Dictionary = {}
	self._update_graph_config_tree(config_tree)

	_panel_space.add_child(_menu_vbox)

	config_tree = {
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
	self._parse_config_tree(config_tree)


func _process(delta: float) -> void:
	super._process(delta)

	# self._update_graph_config_tree(config_tree)

	# self._parse_config_tree(config_tree)

func _input(event: InputEvent) -> void:
	super._input(event)
