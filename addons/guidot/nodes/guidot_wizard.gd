@tool
class_name Guidot_Wizard
extends Guidot_Movable_Panel

@onready var _menu_vbox: VBoxContainer = VBoxContainer.new()
@onready var _filter_prop_line_edit: LineEdit = LineEdit.new()
@onready var _wizard_panel_cont: PanelContainer = PanelContainer.new()
@onready var _menu_tab_cont: TabContainer = TabContainer.new()
@onready var _graph_config_cont: ScrollContainer = ScrollContainer.new()
@onready var _data_subscriber_cont: ScrollContainer = ScrollContainer.new()

@onready var _graph_settings: Dictionary = {
	"graph_node_ref": "<gd_node_ref>",
	"graph_node_id": "<Node_ID>",
	"graph_type": "Guidot_Time_Series_Graph",
	"global": {
		"preferences": {
			"disable_hotkeys": false,
			"opacity": 100,
			"graph_mode": 0,
		},
	},

	"local": {
		"preferences": {
			"disable_hotkeys": false,
			"opacity": 100,
			"graph_mode": 0,
			"sync_with_global": false,
		},
	},

	"y_axis": {
		"axis_count": {
			"n_left_axis": 1,
			"n_right_axis": 1,
		},
		"axis_range": {
			Guidot_Y_Axis_Canvas.AxisPosition.PRIMARY_LEFT: Vector2(0, 100),
		}
	},

	"x_axis": {
		"axis_range": Vector2(0, 20)
	}
}

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

	var vbox1 = VBoxContainer.new()
	var label1 = Label.new()
	label1.text = "Hello World"
	vbox1.add_child(label1)
	self._data_subscriber_cont.add_child(vbox1)

	self._menu_tab_cont.add_child(self._graph_config_cont)
	self._menu_tab_cont.add_child(self._data_subscriber_cont)
	self._menu_vbox.add_child(_wizard_panel_cont)

	_panel_space.add_child(_menu_vbox)

func _process(delta: float) -> void:
	super._process(delta)

func _input(event: InputEvent) -> void:
	super._input(event)
